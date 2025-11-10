import { Server as SocketServer } from 'socket.io';
import { Server as HttpServer } from 'http';
import { verifyToken } from '../utils/jwt';
import Order from '../models/Order';
import User from '../models/User';
import { findNearestDrivers } from '../utils/distance';

let io: SocketServer;

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
          // Notify customer
          io.to(`user:${order.customerId._id}`).emit('order-updated', order);
          
          // Notify driver
          if (order.driverId) {
            io.to(`user:${order.driverId._id}`).emit('order-updated', order);
          }
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

    const drivers = await User.find({
      role: 'driver',
      isAvailable: true,
      vehicleType: order.vehicleType,
      location: { $exists: true },
    });

    if (drivers.length === 0) {
      return;
    }

    const nearestDrivers = findNearestDrivers(
      drivers.map((d) => ({
        location: d.location!,
        _id: d._id.toString(),
      })),
      order.pickupLocation,
      10
    );

    // Emit to driver vehicle room
    if (order.vehicleType) {
      io.to(`drivers:${order.vehicleType}`).emit('new-order', order);
    }

    // Emit directly to nearest drivers as a fallback prioritization
    nearestDrivers.forEach(({ driverId }) => {
      io.to(`user:${driverId}`).emit('new-order', order);
    });
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

  if (customerId) {
  io.to(`user:${customerId}`).emit('order-accepted', order);
  }

  if (driverId) {
    io.to(`user:${driverId}`).emit('order-updated', order);
  }

  if (order?.vehicleType) {
    io.to(`drivers:${order.vehicleType}`).emit('order-removed', {
      orderId: order?._id?.toString() ?? order?.id,
      acceptedBy: driverId,
    });
  }
};

export { io };
