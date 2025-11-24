import { Server as SocketServer } from 'socket.io';
import { Server as HttpServer } from 'http';
import { verifyToken } from '../utils/jwt';
import Order from '../models/Order';
import User from '../models/User';
import Settings from '../models/Settings';
import City from '../models/City';
import { calculateDistance, findCityForLocation } from '../utils/distance';
import { sendIncomingCallNotification } from './fcmService';

let io: SocketServer;

// Track pending calls: Map<callerId, { orderId, roomId, receiverId }[]>
const pendingCalls = new Map<string, Array<{
  orderId: string;
  roomId: string;
  receiverId: string;
}>>();

// Track accepted calls to prevent false timeouts: Map<roomId, { callerId, receiverId, acceptedAt }>
const acceptedCalls = new Map<string, {
  callerId: string;
  receiverId: string;
  acceptedAt: number;
}>();

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

    // Handle call initiation - notify receiver
    socket.on('call-initiate', async (data: { 
      orderId: string; 
      roomId: string; 
      callerId: string; 
      callerName: string;
      receiverId: string;
    }) => {
      try {
        console.log(`📞 Call initiated: ${data.callerId} calling ${data.receiverId} for order ${data.orderId}`);
        
        // Track pending call
        const callerId = data.callerId;
        if (!pendingCalls.has(callerId)) {
          pendingCalls.set(callerId, []);
        }
        pendingCalls.get(callerId)!.push({
          orderId: data.orderId,
          roomId: data.roomId,
          receiverId: data.receiverId,
        });
        
        // Notify the receiver about the incoming call via Socket.IO
        console.log(`📤 Sending incoming-call to receiver ${data.receiverId}:`);
        console.log(`   - orderId: ${data.orderId}`);
        console.log(`   - roomId: ${data.roomId}`);
        console.log(`   - callerId: ${data.callerId}`);
        console.log(`   - callerName: ${data.callerName}`);
        emitToUserRoom(data.receiverId, 'incoming-call', {
          orderId: data.orderId,
          roomId: data.roomId,
          callerId: data.callerId,
          callerName: data.callerName,
        });

        // Also send FCM push notification (works even when app is terminated)
        try {
          await sendIncomingCallNotification(data.receiverId, {
            orderId: data.orderId,
            roomId: data.roomId,
            callerId: data.callerId,
            callerName: data.callerName,
            type: 'incoming_call',
          });
          console.log(`📱 FCM notification sent to user ${data.receiverId} for incoming call`);
        } catch (error) {
          console.error('Error sending FCM notification:', error);
          // Don't fail the call initiation if FCM fails
        }

        // Also notify the caller that the call notification was sent
        emitToUserRoom(data.callerId, 'call-notification-sent', {
          orderId: data.orderId,
          roomId: data.roomId,
          receiverId: data.receiverId,
        });
      } catch (error) {
        console.error('Error handling call initiation:', error);
      }
    });

    // Handle call acceptance - notify caller
    socket.on('call-accepted', async (data: {
      orderId: string;
      roomId: string;
      callerId: string;
      receiverId: string;
    }) => {
      try {
        console.log(`✅ Call accepted: ${data.receiverId} accepted call from ${data.callerId} for order ${data.orderId}`);
        
        // Track accepted call to prevent false timeouts
        acceptedCalls.set(data.roomId, {
          callerId: data.callerId,
          receiverId: data.receiverId,
          acceptedAt: Date.now(),
        });
        
        // Remove pending call from tracking
        const callerPendingCalls = pendingCalls.get(data.callerId);
        if (callerPendingCalls) {
          const index = callerPendingCalls.findIndex(
            call => call.orderId === data.orderId && call.roomId === data.roomId
          );
          if (index !== -1) {
            callerPendingCalls.splice(index, 1);
            if (callerPendingCalls.length === 0) {
              pendingCalls.delete(data.callerId);
            }
          }
        }
        
        // Notify the caller that the call was accepted
        // Retry mechanism for Render free hosting delays
        let retryCount = 0;
        const maxRetries = 3;
        const retryDelay = 1000; // 1 second
        
        const sendCallAccepted = () => {
          try {
            emitToUserRoom(data.callerId, 'call-accepted', {
              orderId: data.orderId,
              roomId: data.roomId,
              callerId: data.callerId, // CRITICAL: Include callerId for event matching
              receiverId: data.receiverId,
            });
            console.log(`📤 Call-accepted event sent to caller ${data.callerId} (attempt ${retryCount + 1})`);
          } catch (error) {
            console.error(`Error sending call-accepted event (attempt ${retryCount + 1}):`, error);
            if (retryCount < maxRetries) {
              retryCount++;
              setTimeout(sendCallAccepted, retryDelay * retryCount);
            }
          }
        };
        
        // Send immediately
        console.log(`📤 Sending call-accepted to caller ${data.callerId}:`);
        console.log(`   - orderId: ${data.orderId}`);
        console.log(`   - roomId: ${data.roomId}`);
        console.log(`   - callerId: ${data.callerId}`);
        console.log(`   - receiverId: ${data.receiverId}`);
        sendCallAccepted();
        
        // Also send a delayed confirmation (handles WebSocket delays on Render free hosting)
        setTimeout(() => {
          // Re-send call-accepted event after 2 seconds as a backup
          // This helps if the first event was delayed or lost
          emitToUserRoom(data.callerId, 'call-accepted', {
            orderId: data.orderId,
            roomId: data.roomId,
            callerId: data.callerId, // CRITICAL: Include callerId for event matching
            receiverId: data.receiverId,
          });
          console.log(`📤 Call-accepted event re-sent to caller ${data.callerId} (backup)`);
        }, 2000);
        
      } catch (error) {
        console.error('Error handling call acceptance:', error);
      }
    });

    // Handle call rejection - notify caller
    socket.on('call-rejected', async (data: {
      orderId: string;
      roomId: string;
      callerId: string;
      receiverId: string;
    }) => {
      try {
        console.log(`❌ Call rejected: ${data.receiverId} rejected call from ${data.callerId} for order ${data.orderId}`);
        
        // Remove pending call from tracking
        const callerPendingCalls = pendingCalls.get(data.callerId);
        if (callerPendingCalls) {
          const index = callerPendingCalls.findIndex(
            call => call.orderId === data.orderId && call.roomId === data.roomId
          );
          if (index !== -1) {
            callerPendingCalls.splice(index, 1);
            if (callerPendingCalls.length === 0) {
              pendingCalls.delete(data.callerId);
            }
          }
        }
        
        // Notify the caller that the call was rejected
        emitToUserRoom(data.callerId, 'call-rejected', {
          orderId: data.orderId,
          roomId: data.roomId,
          callerId: data.callerId, // CRITICAL: Include callerId for event matching
          receiverId: data.receiverId,
        });
      } catch (error) {
        console.error('Error handling call rejection:', error);
      }
    });

    // Handle call cancellation - when caller cancels before receiver accepts
    socket.on('call-cancelled', async (data: {
      orderId: string;
      roomId: string;
      callerId: string;
      receiverId: string;
    }) => {
      try {
        console.log(`🚫 Call cancelled: ${data.callerId} cancelled call to ${data.receiverId} for order ${data.orderId}`);
        
        // Remove pending call from tracking
        const callerPendingCalls = pendingCalls.get(data.callerId);
        if (callerPendingCalls) {
          const index = callerPendingCalls.findIndex(
            call => call.orderId === data.orderId && call.roomId === data.roomId
          );
          if (index !== -1) {
            callerPendingCalls.splice(index, 1);
            if (callerPendingCalls.length === 0) {
              pendingCalls.delete(data.callerId);
            }
          }
        }
        
        // Notify the receiver that the call was cancelled
        emitToUserRoom(data.receiverId, 'call-cancelled', {
          orderId: data.orderId,
          roomId: data.roomId,
          callerId: data.callerId,
        });
      } catch (error) {
        console.error('Error handling call cancellation:', error);
      }
    });

    socket.on('disconnect', () => {
      const userId = socket.data.user?.userId;
      console.log(`❌ User disconnected: ${userId}`);
      
      // Clean up accepted calls for this user (older than 5 minutes)
      const fiveMinutesAgo = Date.now() - 5 * 60 * 1000;
      for (const [roomId, call] of acceptedCalls.entries()) {
        if ((call.callerId === userId || call.receiverId === userId) && call.acceptedAt < fiveMinutesAgo) {
          acceptedCalls.delete(roomId);
        }
      }
      
      // If user has pending calls, notify receivers that caller disconnected
      if (userId) {
        const callerPendingCalls = pendingCalls.get(userId);
        if (callerPendingCalls && callerPendingCalls.length > 0) {
          console.log(`⚠️ User ${userId} disconnected with ${callerPendingCalls.length} pending call(s), checking status...`);
          
          callerPendingCalls.forEach((call) => {
            // Check if call was actually accepted before notifying cancellation
            const acceptedCall = acceptedCalls.get(call.roomId);
            if (!acceptedCall) {
              // Only notify cancellation if call wasn't accepted
              emitToUserRoom(call.receiverId, 'call-cancelled', {
                orderId: call.orderId,
                roomId: call.roomId,
                callerId: userId,
              });
              console.log(`🚫 Call ${call.roomId} cancelled: caller disconnected before acceptance`);
            } else {
              // CRITICAL FIX: Add grace period for recently accepted calls
              // Don't cancel calls that were accepted within the last 15 seconds
              // This prevents race conditions where user disconnects right after accepting
              const gracePeriodMs = 15 * 1000; // 15 seconds grace period
              const timeSinceAccepted = Date.now() - acceptedCall.acceptedAt;
              
              if (timeSinceAccepted < gracePeriodMs) {
                console.log(`⏳ Call ${call.roomId} was accepted ${timeSinceAccepted}ms ago (within ${gracePeriodMs}ms grace period), NOT cancelling`);
                // Don't send cancellation - call was just accepted and user might be joining Zego room
              } else {
                console.log(`ℹ️ Call ${call.roomId} was accepted ${timeSinceAccepted}ms ago (outside grace period), skipping cancellation notification`);
              }
            }
          });
          
          // Clear pending calls for this user
          pendingCalls.delete(userId);
        }
      }
    });
  });

  return io;
};

/**
 * Helper function to find drivers within radius/range
 */
const findDriversWithinRadius = (
  drivers: any[],
  userLocation: { lat: number; lng: number },
  deliveryType: string,
  internalRadiusKm: number,
  externalMinRadiusKm: number,
  externalMaxRadiusKm: number
): any[] => {
  return drivers.filter((driver) => {
    if (!driver.location || !userLocation) {
      return false;
    }
    const distance = calculateDistance(driver.location, userLocation);
    
    if (deliveryType === 'internal') {
      // Internal orders: Fixed radius (distance <= 2km)
      return distance <= internalRadiusKm;
    } else {
      // External orders: Must be within min and max radius range
      return distance >= externalMinRadiusKm && distance <= externalMaxRadiusKm;
    }
  });
};

/**
 * Expanding radius fallback mechanism for external orders
 * Expands the radius step by step if no drivers are found
 */
const tryExpandingRadius = async (
  order: any,
  drivers: any[],
  userLocation: { lat: number; lng: number },
  initialMinRadius: number,
  initialMaxRadius: number,
  cityName?: string
): Promise<boolean> => {
  const MAX_EXPANSIONS = 3;
  const EXPANSION_STEP = 5; // Expand by 5km each time
  const WAIT_TIME_MS = 12000; // Wait 12 seconds between expansions

  let currentMinRadius = initialMinRadius;
  let currentMaxRadius = initialMaxRadius;

  for (let expansion = 0; expansion < MAX_EXPANSIONS; expansion++) {
    // Wait before expanding (except for first expansion)
    if (expansion > 0) {
      await new Promise((resolve) => setTimeout(resolve, WAIT_TIME_MS));
      
      // Check if order was already accepted
      const updatedOrder = await Order.findById(order._id);
      if (!updatedOrder || updatedOrder.status !== 'pending' || updatedOrder.driverId) {
        console.log(`Order ${order._id} was accepted during expansion, stopping expansion`);
        return true; // Order was accepted
      }
    }

    // Expand radius
    currentMinRadius = currentMaxRadius;
    currentMaxRadius = currentMinRadius + EXPANSION_STEP;

    console.log(
      `[Expanding Radius] Attempt ${expansion + 1}/${MAX_EXPANSIONS}: Trying range ${currentMinRadius}-${currentMaxRadius}km for order ${order._id}`
    );

    // Find drivers within expanded range
    const driversWithinRange = drivers.filter((driver) => {
      if (!driver.location || !userLocation) {
        return false;
      }
      const distance = calculateDistance(driver.location, userLocation);
      return distance >= currentMinRadius && distance <= currentMaxRadius;
    });

    if (driversWithinRange.length > 0) {
      // Emit to drivers within expanded range
      driversWithinRange.forEach((driver) => {
        io.to(`user:${driver._id.toString()}`).emit('new-order', order);
      });

      const cityInfo = cityName ? ` (city: ${cityName})` : '';
      console.log(
        `Order ${order._id} (external)${cityInfo} sent to ${driversWithinRange.length} driver(s) within expanded range ${currentMinRadius}-${currentMaxRadius}km (expansion ${expansion + 1})`
      );
      return true; // Found drivers
    }
  }

  // No drivers found after all expansions
  const cityInfo = cityName ? ` for city ${cityName}` : '';
  console.log(
    `No drivers available after ${MAX_EXPANSIONS} expansions for external order ${order._id}${cityInfo}. Maximum range tried: ${currentMinRadius}-${currentMaxRadius}km`
  );

  // Notify customer that no drivers are available
  const customerId = order?.customerId?._id?.toString() ?? order?.customerId?.toString();
  if (customerId) {
    emitToUserRoom(customerId, 'no-drivers-available', {
      orderId: order._id?.toString() ?? order?.id,
      message: 'No drivers available within the service area',
    });
  }

  return false; // No drivers found
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

    // Get deliveryType from order (required field)
    const deliveryType: string = order.deliveryType || 'internal';
    
    // Get all active cities with service centers configured
    const citiesWithServiceCenters = await City.find({
      isActive: true,
      'serviceCenter.center.lat': { $exists: true, $ne: null },
      'serviceCenter.center.lng': { $exists: true, $ne: null },
    }).lean();

    let internalRadiusKm: number;
    let externalMinRadiusKm: number;
    let externalMaxRadiusKm: number;
    let cityName: string | undefined;

    // Get radius based on delivery type and city/global settings
    if (citiesWithServiceCenters.length > 0) {
      const cityServiceCenter = findCityForLocation(
        userLocation,
        citiesWithServiceCenters as any
      );

      if (cityServiceCenter) {
        cityName = cityServiceCenter.cityName;
        internalRadiusKm = cityServiceCenter.internalOrderRadiusKm;
        externalMinRadiusKm = cityServiceCenter.externalOrderMinRadiusKm;
        externalMaxRadiusKm = cityServiceCenter.externalOrderMaxRadiusKm;
      } else {
        // Use global settings
        const settings = await Settings.getSettings();
        internalRadiusKm = settings.internalOrderRadiusKm;
        externalMinRadiusKm = settings.externalOrderMinRadiusKm;
        externalMaxRadiusKm = settings.externalOrderMaxRadiusKm;
      }
    } else {
      // Use global settings
      const settings = await Settings.getSettings();
      internalRadiusKm = settings.internalOrderRadiusKm;
      externalMinRadiusKm = settings.externalOrderMinRadiusKm;
      externalMaxRadiusKm = settings.externalOrderMaxRadiusKm;
    }

    // Find all available drivers matching the vehicle type
    const drivers = await User.find({
      role: 'driver',
      isAvailable: true,
      vehicleType: order.vehicleType,
      location: { $exists: true },
    });

    if (drivers.length === 0) {
      // Notify customer that no drivers are available
      const customerId = order?.customerId?._id?.toString() ?? order?.customerId?.toString();
      if (customerId) {
        emitToUserRoom(customerId, 'no-drivers-available', {
          orderId: order._id?.toString() ?? order?.id,
          message: 'No drivers available',
        });
      }
      return;
    }

    // Filter drivers based on delivery type and radius logic
    // Internal orders: Fixed radius (distance <= 2km)
    // External orders: Range check (distance >= minRadius AND distance <= maxRadius)
    const driversWithinRadius = findDriversWithinRadius(
      drivers,
      userLocation,
      deliveryType,
      internalRadiusKm,
      externalMinRadiusKm,
      externalMaxRadiusKm
    );

    if (driversWithinRadius.length === 0) {
      const cityInfo = cityName ? ` for city ${cityName}` : '';
      if (deliveryType === 'internal') {
        console.log(
          `No drivers found within ${internalRadiusKm}km radius from user location for ${deliveryType} order ${order._id}${cityInfo}`
        );
        // For internal orders, notify customer immediately (no expansion)
        const customerId = order?.customerId?._id?.toString() ?? order?.customerId?.toString();
        if (customerId) {
          emitToUserRoom(customerId, 'no-drivers-available', {
            orderId: order._id?.toString() ?? order?.id,
            message: 'No drivers available within the service area',
          });
        }
      } else {
        console.log(
          `No drivers found within ${externalMinRadiusKm}-${externalMaxRadiusKm}km range from user location for ${deliveryType} order ${order._id}${cityInfo}. Starting expanding radius fallback...`
        );
        // For external orders, try expanding radius
        await tryExpandingRadius(
          order,
          drivers,
          userLocation,
          externalMinRadiusKm,
          externalMaxRadiusKm,
          cityName
        );
      }
      return;
    }

    // Emit to each driver within radius individually
    driversWithinRadius.forEach((driver) => {
      io.to(`user:${driver._id.toString()}`).emit('new-order', order);
    });

    const cityInfo = cityName ? ` (city: ${cityName})` : '';
    if (deliveryType === 'internal') {
      console.log(
        `Order ${order._id} (${deliveryType})${cityInfo} sent to ${driversWithinRadius.length} driver(s) within ${internalRadiusKm}km radius from user location`
      );
    } else {
      console.log(
        `Order ${order._id} (${deliveryType})${cityInfo} sent to ${driversWithinRadius.length} driver(s) within ${externalMinRadiusKm}-${externalMaxRadiusKm}km range from user location`
      );
    }
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
