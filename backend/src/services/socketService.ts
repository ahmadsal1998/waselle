import { Server as SocketServer } from 'socket.io';
import { Server as HttpServer } from 'http';
import { verifyToken } from '../utils/jwt';
import Order from '../models/Order';
import User from '../models/User';
import Settings from '../models/Settings';
import City from '../models/City';
import { calculateDistance, isInternalOrder, findCityForLocation } from '../utils/distance';

let io: SocketServer;

const emitToUserRoom = (
  userId: string | null | undefined,
  event: string,
  payload: any
) => {
  if (!io || !userId) return;
  io.to(`user:${userId}`).emit(event, payload);
};

export const initializeSocket = (server: HttpServer): SocketServer => {
  io = new SocketServer(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST'],
    },
  });

  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication error'));
    }

    try {
      const decoded = verifyToken(token);
      socket.data.user = decoded;
      next();
    } catch (error) {
      next(new Error('Authentication error'));
    }
  });

  io.on('connection', async (socket) => {
    console.log(`✅ User connected: ${socket.data.user?.userId}`);

    // Join user-specific room
    socket.join(`user:${socket.data.user.userId}`);

    // Join driver specific rooms based on vehicle type
    try {
      const user = await User.findById(socket.data.user.userId);
      if (user?.role === 'driver' && user.vehicleType) {
        const vehicleRoom = `drivers:${user.vehicleType}`;
        socket.data.vehicleType = user.vehicleType;
        socket.join(vehicleRoom);
      }
    } catch (error) {
      console.error('Error assigning driver to room:', error);
    }

    // Handle location updates
    socket.on('update-location', async (data: { lat: number; lng: number }) => {
      try {
        await User.findByIdAndUpdate(socket.data.user.userId, {
          location: { lat: data.lat, lng: data.lng },
        });
        socket.broadcast.emit('driver-location-update', {
          driverId: socket.data.user.userId,
          location: data,
        });
      } catch (error) {
        console.error('Error updating location:', error);
      }
    });

    // Handle order status updates
    socket.on('order-status-update', async (data: { orderId: string; status: string }) => {
      try {
        const order = await Order.findByIdAndUpdate(
          data.orderId,
          { status: data.status },
          { new: true }
        )
          .populate('customerId', 'name email')
          .populate('driverId', 'name email location');

        if (order) {
          emitOrderUpdated(order);
        }
      } catch (error) {
        console.error('Error updating order status:', error);
      }
    });

    socket.on('disconnect', () => {
      console.log(`❌ User disconnected: ${socket.data.user?.userId}`);
    });
  });

  return io;
};

export const emitNewOrder = async (order: any): Promise<void> => {
  try {
    if (!io) {
      console.warn('Socket server not initialized when emitting new order');
      return;
    }

    if (!order.pickupLocation) {
      console.warn(`Order ${order._id} has no pickup location`);
      return;
    }

    // Get customer location (user's location) - this is what we use for distance calculation
    const customer = await User.findById(order.customerId);
    if (!customer || !customer.location) {
      console.warn(`Order ${order._id} customer has no location`);
      return;
    }

    const userLocation = customer.location;

    // Get all active cities with service centers configured
    const citiesWithServiceCenters = await City.find({
      isActive: true,
      'serviceCenter.center.lat': { $exists: true, $ne: null },
      'serviceCenter.center.lng': { $exists: true, $ne: null },
    }).lean();

    let radiusKm: number;
    let deliveryType: string = order.deliveryType || 'internal';
    let cityName: string | undefined;

    // Use the deliveryType from the order if available, otherwise determine from location
    if (!order.deliveryType) {
      // Fallback: Determine delivery type based on location if not provided
      if (citiesWithServiceCenters.length > 0) {
        const cityServiceCenter = findCityForLocation(
          userLocation,
          citiesWithServiceCenters as any
        );

        if (cityServiceCenter) {
          cityName = cityServiceCenter.cityName;
          const isInternal = isInternalOrder(
            userLocation,
            cityServiceCenter.center,
            cityServiceCenter.serviceAreaRadiusKm
          );
          deliveryType = isInternal ? 'internal' : 'external';
        }
      }

      // Fall back to global settings if no city found
      if (!cityName) {
        const settings = await Settings.getSettings();
        const isInternal = isInternalOrder(
          userLocation,
          settings.serviceAreaCenter,
          settings.serviceAreaRadiusKm
        );
        deliveryType = isInternal ? 'internal' : 'external';
      }
    }

    // Get radius based on delivery type and city/global settings
    if (citiesWithServiceCenters.length > 0) {
      const cityServiceCenter = findCityForLocation(
        userLocation,
        citiesWithServiceCenters as any
      );

      if (cityServiceCenter) {
        cityName = cityServiceCenter.cityName;
        radiusKm = deliveryType === 'internal'
          ? cityServiceCenter.internalOrderRadiusKm
          : cityServiceCenter.externalOrderRadiusKm;
      } else {
        // Use global settings
        const settings = await Settings.getSettings();
        radiusKm = deliveryType === 'internal'
          ? settings.internalOrderRadiusKm
          : settings.externalOrderRadiusKm;
      }
    } else {
      // Use global settings
      const settings = await Settings.getSettings();
      radiusKm = deliveryType === 'internal'
        ? settings.internalOrderRadiusKm
        : settings.externalOrderRadiusKm;
    }

    // Find all available drivers matching the vehicle type
    const drivers = await User.find({
      role: 'driver',
      isAvailable: true,
      vehicleType: order.vehicleType,
      location: { $exists: true },
    });

    if (drivers.length === 0) {
      return;
    }

    // Filter drivers within the configured radius from USER'S location (not pickup location)
    const driversWithinRadius = drivers.filter((driver) => {
      if (!driver.location || !userLocation) {
        return false;
      }
      const distance = calculateDistance(driver.location, userLocation);
      return distance <= radiusKm;
    });

    if (driversWithinRadius.length === 0) {
      const cityInfo = cityName ? ` for city ${cityName}` : '';
      console.log(
        `No drivers found within ${radiusKm}km radius from user location for ${deliveryType} order ${order._id}${cityInfo}`
      );
      return;
    }

    // Emit to each driver within radius individually
    driversWithinRadius.forEach((driver) => {
      io.to(`user:${driver._id.toString()}`).emit('new-order', order);
    });

    const cityInfo = cityName ? ` (city: ${cityName})` : '';
    console.log(
      `Order ${order._id} (${deliveryType})${cityInfo} sent to ${driversWithinRadius.length} driver(s) within ${radiusKm}km radius from user location`
    );
  } catch (error) {
    console.error('Error emitting new order:', error);
  }
};

export const emitOrderAccepted = (order: any): void => {
  if (!io) {
    console.warn('Socket server not initialized when emitting order acceptance');
    return;
  }

  const customerId =
    order?.customerId?._id?.toString() ?? order?.customerId?.toString();
  const driverId =
    order?.driverId?._id?.toString() ?? order?.driverId?.toString();

  emitToUserRoom(customerId, 'order-accepted', order);
  emitToUserRoom(driverId, 'order-updated', order);

  if (order?.vehicleType) {
    io.to(`drivers:${order.vehicleType}`).emit('order-removed', {
      orderId: order?._id?.toString() ?? order?.id,
      acceptedBy: driverId,
    });
  }
};

export const emitOrderUpdated = (order: any): void => {
  if (!io) {
    console.warn('Socket server not initialized when emitting order update');
    return;
  }

  const customerId =
    order?.customerId?._id?.toString() ?? order?.customerId?.toString();
  const driverId =
    order?.driverId?._id?.toString() ?? order?.driverId?.toString();

  emitToUserRoom(customerId, 'order-updated', order);
  emitToUserRoom(driverId, 'order-updated', order);
};

export { io };
