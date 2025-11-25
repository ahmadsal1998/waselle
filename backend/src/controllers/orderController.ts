import { Response, Request } from 'express';
import mongoose from 'mongoose';
import Order from '../models/Order';
import User from '../models/User';
import { AuthRequest } from '../middleware/auth';
import { calculateDistance } from '../utils/distance';
import { calculateEstimatedPrice } from '../utils/pricing';
import {
  emitNewOrder,
  emitOrderAccepted,
  emitOrderUpdated,
} from '../services/socketService';
import {
  sendOrderStatusNotification,
  sendDriverOrderStatusNotification,
  sendNewOrderNotificationToDrivers,
} from '../services/notificationService';
import OrderCategory from '../models/OrderCategory';
import Settings from '../models/Settings';
import City from '../models/City';
import { findCityForLocation } from '../utils/distance';
import { generateToken } from '../utils/jwt';
import { normalizeAddress } from '../utils/address';
import { admin } from '../utils/firebase';
import { normalizePhoneNumber, splitPhoneNumber } from '../utils/phone';
import { checkAndSuspendDriverIfNeeded } from '../utils/balance';
import { sendSMSOTP } from '../utils/smsProvider';
import { generateOTP } from '../utils/otp';

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export const createOrder = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const {
      type,
      deliveryType,
      pickupLocation,
      dropoffLocation,
      vehicleType,
      orderCategory,
      senderName,
      senderAddress, // Optional - formatted string for backward compatibility
      senderCity, // Separate city component
      senderVillage, // Separate village component
      senderStreetDetails, // Separate street/details component
      senderPhoneNumber,
      deliveryNotes,
    } = req.body;

    if (!vehicleType || !['car', 'bike', 'cargo'].includes(vehicleType)) {
      res.status(400).json({
        message: 'A valid vehicleType is required',
      });
      return;
    }

    // Check if vehicle type is enabled
    const settings = await Settings.getSettings();
    const vehicleConfig = settings.vehicleTypes[vehicleType as 'bike' | 'car' | 'cargo'];
    if (!vehicleConfig || !vehicleConfig.enabled) {
      res.status(400).json({
        message: `Vehicle type ${vehicleType} is not currently available`,
      });
      return;
    }

    if (!deliveryType || !['internal', 'external'].includes(deliveryType)) {
      res.status(400).json({
        message: 'A valid deliveryType is required (internal or external)',
      });
      return;
    }

    if (typeof orderCategory !== 'string' || !orderCategory.trim()) {
      res.status(400).json({
        message: 'Order category is required',
      });
      return;
    }

    if (typeof senderName !== 'string' || !senderName.trim()) {
      res.status(400).json({
        message: 'Sender name is required',
      });
      return;
    }

    // Validate separate address components
    if (!senderCity || typeof senderCity !== 'string' || !senderCity.trim()) {
      res.status(400).json({
        message: 'Sender city is required',
      });
      return;
    }

    if (!senderVillage || typeof senderVillage !== 'string' || !senderVillage.trim()) {
      res.status(400).json({
        message: 'Sender village is required',
      });
      return;
    }

    if (!senderStreetDetails || typeof senderStreetDetails !== 'string' || !senderStreetDetails.trim()) {
      res.status(400).json({
        message: 'Sender street details are required',
      });
      return;
    }

    // Generate formatted address from components for backward compatibility
    const formattedAddress = `${senderCity.trim()}-${senderVillage.trim()}-${senderStreetDetails.trim()}`;

    const rawPhoneValue = senderPhoneNumber;
    const parsedPhoneNumber =
      typeof rawPhoneValue === 'number'
        ? rawPhoneValue
        : typeof rawPhoneValue === 'string'
        ? Number(rawPhoneValue.replace(/[^\d]/g, ''))
        : NaN;

    if (!Number.isFinite(parsedPhoneNumber) || parsedPhoneNumber <= 0) {
      res.status(400).json({
        message: 'A valid numeric sender phone number is required',
      });
      return;
    }

    if (typeof deliveryNotes !== 'string' || !deliveryNotes.trim()) {
      res.status(400).json({
        message: 'Delivery notes are required',
      });
      return;
    }

    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    // Update user information if provided (address, name, etc.)
    // Note: Address is updated from order form, not from user.address
    const user = await User.findById(req.user.userId);
    if (user) {
      if (senderName && senderName.trim()) {
        user.name = senderName.trim();
      }
      // Update address components from order form (separate fields)
      // Store city, village, and streetDetails separately
      if (senderCity && senderCity.trim()) {
        user.city = senderCity.trim();
      }
      if (senderVillage && senderVillage.trim()) {
        user.village = senderVillage.trim();
      }
      if (senderStreetDetails && senderStreetDetails.trim()) {
        user.streetDetails = senderStreetDetails.trim();
      }
      
      // Generate formatted address from components if provided
      if (senderCity || senderVillage || senderStreetDetails) {
        const addressParts = [];
        if (senderCity && senderCity.trim()) addressParts.push(senderCity.trim());
        if (senderVillage && senderVillage.trim()) addressParts.push(senderVillage.trim());
        if (senderStreetDetails && senderStreetDetails.trim()) addressParts.push(senderStreetDetails.trim());
        if (addressParts.length > 0) {
          user.address = addressParts.join('-');
        }
      } else if (senderAddress && senderAddress.trim()) {
        // Fallback: use formatted address if components not provided (backward compatibility)
        user.address = normalizeAddress(senderAddress);
      }
      
      // Update customer location based on order type
      // For "send" orders: use pickupLocation (where customer is sending from)
      // For "receive" orders: use dropoffLocation (where customer wants to receive)
      if (pickupLocation && dropoffLocation) {
        let locationToUse: { lat: number; lng: number } | null = null;
        
        if (type === 'send' && pickupLocation.lat && pickupLocation.lng) {
          // Customer is sending, use pickup location as their location
          locationToUse = {
            lat: typeof pickupLocation.lat === 'number' ? pickupLocation.lat : parseFloat(pickupLocation.lat),
            lng: typeof pickupLocation.lng === 'number' ? pickupLocation.lng : parseFloat(pickupLocation.lng),
          };
        } else if (type === 'receive' && dropoffLocation.lat && dropoffLocation.lng) {
          // Customer is receiving, use dropoff location as their location
          locationToUse = {
            lat: typeof dropoffLocation.lat === 'number' ? dropoffLocation.lat : parseFloat(dropoffLocation.lat),
            lng: typeof dropoffLocation.lng === 'number' ? dropoffLocation.lng : parseFloat(dropoffLocation.lng),
          };
        }
        
        if (locationToUse && !isNaN(locationToUse.lat) && !isNaN(locationToUse.lng)) {
          user.location = locationToUse;
          console.log(`[createOrder] Updated customer ${user._id} location to: ${locationToUse.lat}, ${locationToUse.lng} (order type: ${type})`);
        }
      }
      
      // Update phone if provided (should match existing user)
      if (senderPhoneNumber) {
        const cleanPhone = typeof senderPhoneNumber === 'number'
          ? senderPhoneNumber.toString()
          : senderPhoneNumber.toString().replace(/[^\d]/g, '');
        // Only update if phone format is valid
        if (cleanPhone.length >= 9 && cleanPhone.length <= 10) {
          // Don't change the phone, just verify it matches
          // Phone is unique identifier, shouldn't be changed
        }
      }
      await user.save();
    }

    if (!pickupLocation || !dropoffLocation) {
      res.status(400).json({
        message: 'pickupLocation and dropoffLocation are required',
      });
      return;
    }

    let distance: number | undefined;
    if (
      typeof pickupLocation.lat === 'number' &&
      typeof pickupLocation.lng === 'number' &&
      typeof dropoffLocation.lat === 'number' &&
      typeof dropoffLocation.lng === 'number'
    ) {
      distance = calculateDistance(pickupLocation, dropoffLocation);
    }

    const estimatedPrice = await calculateEstimatedPrice({
      vehicleType: vehicleType as 'bike' | 'car' | 'cargo',
      distanceKm: distance,
    });

    const trimmedCategory = orderCategory.trim();

    const category = await OrderCategory.findOne({
      name: { $regex: `^${escapeRegExp(trimmedCategory)}$`, $options: 'i' },
      isActive: true,
    });

    if (!category) {
      res.status(400).json({
        message: 'Selected order category is not available',
      });
      return;
    }

    // Split phone number into country code and local number
    // Use user's phone from MongoDB if available, otherwise use senderPhoneNumber from request
    const userPhoneToSplit = user?.phone || senderPhoneNumber?.toString();
    const phoneParts = splitPhoneNumber(userPhoneToSplit);

    // Store address components separately in the database
    const order = await Order.create({
      customerId: req.user.userId,
      type,
      deliveryType,
      pickupLocation,
      dropoffLocation,
      vehicleType,
      orderCategory: category.name,
      senderName: senderName.trim(),
      // Store separate components
      senderCity: senderCity.trim(),
      senderVillage: senderVillage.trim(),
      senderStreetDetails: senderStreetDetails.trim(),
      // Generate formatted address for backward compatibility (optional)
      senderAddress: formattedAddress,
      senderPhoneNumber: Math.trunc(parsedPhoneNumber),
      phone: phoneParts?.phone,
      countryCode: phoneParts?.countryCode,
      deliveryNotes: deliveryNotes.trim(),
      price: estimatedPrice,
      estimatedPrice,
      distance,
      status: 'pending',
    });

    await order.populate([
      { path: 'customerId', select: 'name email phone countryCode' },
      { path: 'driverId', select: 'name email phone countryCode' },
    ]);

    const orderData = order.toObject();

    emitNewOrder(orderData);

    // Send push notification to customer when order is created
    if (order.customerId) {
      const customerId = typeof order.customerId === 'object' && (order.customerId as any)._id 
        ? (order.customerId as any)._id.toString() 
        : order.customerId.toString();
      await sendOrderStatusNotification(
        order._id.toString(),
        customerId,
        'pending',
        orderData
      );
    }

    // Send push notification to relevant drivers about new order
    // Determine customer location based on order type
    let customerLocation: { lat: number; lng: number } | null = null;
    if (type === 'send' && pickupLocation.lat && pickupLocation.lng) {
      customerLocation = {
        lat: typeof pickupLocation.lat === 'number' ? pickupLocation.lat : parseFloat(pickupLocation.lat),
        lng: typeof pickupLocation.lng === 'number' ? pickupLocation.lng : parseFloat(pickupLocation.lng),
      };
    } else if (type === 'receive' && dropoffLocation.lat && dropoffLocation.lng) {
      customerLocation = {
        lat: typeof dropoffLocation.lat === 'number' ? dropoffLocation.lat : parseFloat(dropoffLocation.lat),
        lng: typeof dropoffLocation.lng === 'number' ? dropoffLocation.lng : parseFloat(dropoffLocation.lng),
      };
    }

    if (customerLocation) {
      // Send notifications asynchronously (don't block response)
      sendNewOrderNotificationToDrivers(
        order._id.toString(),
        vehicleType as 'bike' | 'car' | 'cargo',
        deliveryType as 'internal' | 'external',
        customerLocation,
        orderData
      ).catch((error) => {
        console.error('Error sending new order notifications to drivers:', error);
      });
    }

    res.status(201).json({
      message: 'Order created successfully',
      order: orderData,
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to create order' });
  }
};

export const estimateOrderPrice = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { vehicleType, pickupLocation, dropoffLocation } = req.body;

    if (!vehicleType || !['car', 'bike', 'cargo'].includes(vehicleType)) {
      res.status(400).json({ message: 'Valid vehicleType is required' });
      return;
    }

    // Check if vehicle type is enabled
    const settings = await Settings.getSettings();
    const vehicleConfig = settings.vehicleTypes[vehicleType as 'bike' | 'car' | 'cargo'];
    if (!vehicleConfig || !vehicleConfig.enabled) {
      res.status(400).json({
        message: `Vehicle type ${vehicleType} is not currently available`,
      });
      return;
    }

    let distance: number | undefined;
    if (
      pickupLocation?.lat !== undefined &&
      pickupLocation?.lng !== undefined &&
      dropoffLocation?.lat !== undefined &&
      dropoffLocation?.lng !== undefined
    ) {
      distance = calculateDistance(pickupLocation, dropoffLocation);
    }

    const estimatedPrice = await calculateEstimatedPrice({
      vehicleType: vehicleType as 'bike' | 'car' | 'cargo',
      distanceKm: distance,
    });

    res.status(200).json({ estimatedPrice });
  } catch (error: any) {
    res
      .status(500)
      .json({ message: error.message || 'Failed to estimate order price' });
  }
};

export const getOrders = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    let query: any = {};

    if (req.user.role === 'customer') {
      query.customerId = req.user.userId;
    } else if (req.user.role === 'driver') {
      query.driverId = req.user.userId;
    }

    const orders = await Order.find(query)
      .populate('customerId', 'name email')
      .populate('driverId', 'name email')
      .sort({ createdAt: -1 });

    res.status(200).json({ orders });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get orders' });
  }
};

export const getAvailableOrders = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'driver') {
      res.status(403).json({ message: 'Only drivers can access this endpoint' });
      return;
    }

    const driver = await User.findById(req.user.userId);
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    if (!driver.vehicleType) {
      res.status(400).json({
        message: 'Driver must have a vehicle type set before viewing orders',
      });
      return;
    }

    if (!driver.location || !driver.isAvailable) {
      res.status(400).json({
        message: 'Driver must be available and have location set',
      });
      return;
    }

    // Get pending orders with customer location populated
    // Only include orders from verified users
    const pendingOrders = await Order.find({
      status: 'pending',
      vehicleType: driver.vehicleType,
    })
      .populate({
        path: 'customerId',
        select: 'name email location phone countryCode isEmailVerified',
        match: { isEmailVerified: true }, // Only include verified users
      })
      .lean();
    
    console.log(`[getAvailableOrders] Found ${pendingOrders.length} pending orders with vehicleType=${driver.vehicleType}`);
    
    // Log orders that don't have customer (filtered out by populate match)
    const ordersWithoutCustomer = await Order.find({
      status: 'pending',
      vehicleType: driver.vehicleType,
    })
      .populate({
        path: 'customerId',
        select: 'name email location phone countryCode isEmailVerified',
      })
      .lean();
    
    const unverifiedOrders = ordersWithoutCustomer.filter((order: any) => {
      const customer = order.customerId;
      return !customer || !customer.isEmailVerified;
    });
    
    if (unverifiedOrders.length > 0) {
      console.log(`[getAvailableOrders] ${unverifiedOrders.length} orders filtered out (unverified customers or missing customer data)`);
      unverifiedOrders.forEach((order: any) => {
        const customer = order.customerId;
        if (customer) {
          console.log(`[getAvailableOrders] Order ${order._id}: Customer ${customer.name} isVerified=${customer.isEmailVerified}`);
        } else {
          console.log(`[getAvailableOrders] Order ${order._id}: No customer data`);
        }
      });
    }

    // Get settings for radius configuration
    const settings = await Settings.getSettings();

    // Get all active cities with service centers configured
    const citiesWithServiceCenters = await City.find({
      isActive: true,
      'serviceCenter.center.lat': { $exists: true, $ne: null },
      'serviceCenter.center.lng': { $exists: true, $ne: null },
    }).lean();

    // Filter orders based on distance from driver to customer location
    // Also filter out orders from unverified users (shouldn't happen but safety check)
    const filteredOrders = pendingOrders
      .map((order) => {
        // Get customer location (user's location)
        const customer = order.customerId as any;
        // Skip orders without customer, customer location, or from unverified users
        if (!customer) {
          console.log(`[getAvailableOrders] Order ${order._id}: No customer (filtered by populate match)`);
          return null;
        }
        if (!customer.isEmailVerified) {
          console.log(`[getAvailableOrders] Order ${order._id}: Customer ${customer.name} not verified (isEmailVerified=${customer.isEmailVerified})`);
          return null;
        }
        
        // Try to get customer location, fallback to order location for existing orders
        let customerLocation = customer.location;
        if (!customerLocation && order.pickupLocation) {
          // Fallback: Use order's pickupLocation (for "send" orders) or dropoffLocation (for "receive" orders)
          if (order.type === 'send' && order.pickupLocation) {
            customerLocation = {
              lat: order.pickupLocation.lat,
              lng: order.pickupLocation.lng,
            };
            console.log(`[getAvailableOrders] Order ${order._id}: Using pickupLocation as customer location fallback`);
          } else if (order.type === 'receive' && order.dropoffLocation) {
            customerLocation = {
              lat: order.dropoffLocation.lat,
              lng: order.dropoffLocation.lng,
            };
            console.log(`[getAvailableOrders] Order ${order._id}: Using dropoffLocation as customer location fallback`);
          }
        }
        
        if (!customerLocation) {
          console.log(`[getAvailableOrders] Order ${order._id}: Customer ${customer.name} has no location and order has no location data`);
          return null;
        }

        // Get delivery type from order
        const deliveryType = order.deliveryType || 'internal';

        // Determine radius based on delivery type and city/global settings
        let internalRadiusKm: number;
        let externalMinRadiusKm: number;
        let externalMaxRadiusKm: number;

        if (citiesWithServiceCenters.length > 0) {
          const cityServiceCenter = findCityForLocation(
            customerLocation,
            citiesWithServiceCenters as any
          );

          if (cityServiceCenter) {
            // Use city-specific radius
            internalRadiusKm = cityServiceCenter.internalOrderRadiusKm;
            externalMinRadiusKm = cityServiceCenter.externalOrderMinRadiusKm;
            externalMaxRadiusKm = cityServiceCenter.externalOrderMaxRadiusKm;
          } else {
            // Use global settings
            internalRadiusKm = settings.internalOrderRadiusKm;
            externalMinRadiusKm = settings.externalOrderMinRadiusKm;
            externalMaxRadiusKm = settings.externalOrderMaxRadiusKm;
          }
        } else {
          // Use global settings
          internalRadiusKm = settings.internalOrderRadiusKm;
          externalMinRadiusKm = settings.externalOrderMinRadiusKm;
          externalMaxRadiusKm = settings.externalOrderMaxRadiusKm;
        }

        // Calculate distance from driver to customer location (NOT pickup location)
        const distance = calculateDistance(driver.location!, customerLocation);

        // Apply radius logic based on delivery type
        // Internal orders: Fixed radius (distance <= 2km)
        // External orders: Range check (distance >= minRadius AND distance <= maxRadius)
        let isWithinRadius: boolean;
        if (deliveryType === 'internal') {
          isWithinRadius = distance <= internalRadiusKm;
          if (isWithinRadius) {
            console.log(`[getAvailableOrders] Order ${order._id}: Included (distance=${distance.toFixed(2)}km <= radius=${internalRadiusKm}km)`);
          } else {
            console.log(`[getAvailableOrders] Order ${order._id}: Excluded (distance=${distance.toFixed(2)}km > radius=${internalRadiusKm}km)`);
          }
        } else {
          isWithinRadius = distance >= externalMinRadiusKm && distance <= externalMaxRadiusKm;
          if (isWithinRadius) {
            console.log(`[getAvailableOrders] Order ${order._id}: Included (distance=${distance.toFixed(2)}km within range ${externalMinRadiusKm}-${externalMaxRadiusKm}km)`);
          } else {
            console.log(`[getAvailableOrders] Order ${order._id}: Excluded (distance=${distance.toFixed(2)}km outside range ${externalMinRadiusKm}-${externalMaxRadiusKm}km)`);
          }
        }

        // Only include orders within the allowed radius/range
        if (isWithinRadius) {
          return {
            ...order,
            distanceFromDriver: distance,
          };
        }

        // Order is outside the allowed radius/range - exclude it
        return null;
      })
      .filter((order) => order !== null) // Remove null entries (filtered out orders)
      .sort((a: any, b: any) => a.distanceFromDriver - b.distanceFromDriver);

    console.log(`[getAvailableOrders] Returning ${filteredOrders.length} orders to driver ${driver._id} (vehicleType=${driver.vehicleType})`);
    console.log(`[getAvailableOrders] Note: Push notifications for new orders are sent when orders are created, not when drivers fetch the orders list`);
    
    res.status(200).json({ orders: filteredOrders });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to get available orders',
    });
  }
};

export const acceptOrder = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'driver') {
      res.status(403).json({ message: 'Only drivers can accept orders' });
      return;
    }

    const { orderId } = req.params;

    const order = await Order.findById(orderId);
    if (!order) {
      res.status(404).json({ message: 'Order not found' });
      return;
    }

    const driver = await User.findById(req.user.userId);
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    if (driver.isActive === false) {
      res.status(403).json({
        message: 'Your account has been suspended. Please contact admin to resolve your balance.',
      });
      return;
    }

    if (!driver.vehicleType) {
      res.status(400).json({
        message: 'Driver must have a vehicle type set before accepting orders',
      });
      return;
    }

    if (order.vehicleType !== driver.vehicleType) {
      res.status(403).json({
        message: 'Not authorized to accept orders for a different vehicle type',
      });
      return;
    }

    if (order.status !== 'pending') {
      res.status(400).json({ message: 'Order is not available for acceptance' });
      return;
    }

    order.driverId = new mongoose.Types.ObjectId(req.user.userId);
    order.status = 'accepted';
    await order.save();

    await order.populate([
      { path: 'customerId', select: 'name email phone countryCode' },
      { path: 'driverId', select: 'name email phone countryCode' },
    ]);

    const orderData = order.toObject();

    emitOrderAccepted(orderData);

    // Send push notification to customer
    if (order.customerId) {
      const customerId = typeof order.customerId === 'object' && (order.customerId as any)._id 
        ? (order.customerId as any)._id.toString() 
        : order.customerId.toString();
      await sendOrderStatusNotification(
        order._id.toString(),
        customerId,
        'accepted',
        orderData
      );
    }

    // Send push notification to driver
    if (order.driverId) {
      const driverId = typeof order.driverId === 'object' && (order.driverId as any)._id 
        ? (order.driverId as any)._id.toString() 
        : order.driverId.toString();
      await sendDriverOrderStatusNotification(
        order._id.toString(),
        driverId,
        'accepted',
        orderData
      );
    }

    res.status(200).json({
      message: 'Order accepted successfully',
      order: orderData,
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to accept order' });
  }
};

export const updateOrderStatus = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { orderId } = req.params;
    const { status } = req.body;

    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    const order = await Order.findById(orderId);
    if (!order) {
      res.status(404).json({ message: 'Order not found' });
      return;
    }

    // Check authorization
    if (
      req.user.role === 'driver' &&
      order.driverId?.toString() !== req.user.userId
    ) {
      res.status(403).json({ message: 'Not authorized to update this order' });
      return;
    }

    if (
      req.user.role === 'customer' &&
      order.customerId.toString() !== req.user.userId
    ) {
      res.status(403).json({ message: 'Not authorized to update this order' });
      return;
    }

    order.status = status;
    await order.save();

    // If order is marked as delivered and has a driver, check balance and suspend if needed
    if (status === 'delivered' && order.driverId) {
      try {
        const suspensionResult = await checkAndSuspendDriverIfNeeded(order.driverId);
        if (suspensionResult.suspended) {
          console.log(
            `Driver ${order.driverId} automatically suspended due to balance limit. Balance: ${suspensionResult.balance}, Max Allowed: ${suspensionResult.maxAllowed}`
          );
        }
      } catch (balanceError: any) {
        // Log error but don't fail the order update
        console.error('Error checking driver balance:', balanceError);
      }
    }

    await order.populate([
      { path: 'customerId', select: 'name email phone countryCode' },
      { path: 'driverId', select: 'name email phone countryCode location' },
    ]);

    const orderData = order.toObject();
    emitOrderUpdated(orderData);

    // Send push notifications to customer and driver
    if (order.customerId) {
      const customerId = typeof order.customerId === 'object' && (order.customerId as any)._id 
        ? (order.customerId as any)._id.toString() 
        : order.customerId.toString();
      await sendOrderStatusNotification(
        order._id.toString(),
        customerId,
        status,
        orderData
      );
    }

    if (order.driverId) {
      const driverId = typeof order.driverId === 'object' && (order.driverId as any)._id 
        ? (order.driverId as any)._id.toString() 
        : order.driverId.toString();
      await sendDriverOrderStatusNotification(
        order._id.toString(),
        driverId,
        status,
        orderData
      );
    }

    res.status(200).json({
      message: 'Order status updated successfully',
      order: orderData,
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update order status',
    });
  }
};

export const getOrderById = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { orderId } = req.params;

    const order = await Order.findById(orderId)
      .populate('customerId', 'name email phoneNumber')
      .populate('driverId', 'name email phoneNumber location');

    if (!order) {
      res.status(404).json({ message: 'Order not found' });
      return;
    }

    res.status(200).json({ order });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get order' });
  }
};

// Send OTP to phone number for order verification
export const sendOrderOTP = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { phone, countryCode } = req.body;

    if (!phone || typeof phone !== 'string' || phone.trim().length < 9) {
      res.status(400).json({
        message: 'A valid phone number is required (minimum 9 digits)',
      });
      return;
    }

    const normalizedCountryCode = countryCode || '+970';
    const cleanPhone = phone.replace(/[^\d]/g, '');
    const rawFullPhoneNumber = `${normalizedCountryCode}${cleanPhone}`;
    
    // Normalize phone number before storage
    const fullPhoneNumber = normalizePhoneNumber(rawFullPhoneNumber);
    if (!fullPhoneNumber) {
      res.status(400).json({
        message: 'Invalid phone number format',
      });
      return;
    }

    // Generate OTP
    const otp = generateOTP();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Find or create user by phone number (check both normalized and raw formats)
    let user = await User.findOne({ 
      $or: [
        { phone: fullPhoneNumber },
        { phone: rawFullPhoneNumber },
      ]
    });

    if (user) {
      // Update existing user's OTP and normalize phone number
      user.otpCode = otp;
      user.otpExpires = otpExpires;
      if (user.phone !== fullPhoneNumber) {
        user.phone = fullPhoneNumber;
      }
      await user.save();
    } else {
      // Create new user with normalized phone number
      user = await User.create({
        name: 'Customer', // Temporary name, will be updated when order is created
        phone: fullPhoneNumber,
        countryCode: fullPhoneNumber.startsWith('+') ? fullPhoneNumber.substring(0, 4) : '+970',
        role: 'customer',
        isEmailVerified: true, // Phone-based customers are verified by default
        otpCode: otp,
        otpExpires: otpExpires,
      });
    }

    // Send OTP via SMS provider
    try {
      await sendSMSOTP(fullPhoneNumber, otp);
    } catch (error: any) {
      console.error('Error sending SMS OTP:', error);
      // In development, return OTP in response if SMS fails
      const isDevelopment = process.env.NODE_ENV !== 'production';
      if (isDevelopment) {
        console.warn(`⚠️  SMS sending failed. OTP for ${fullPhoneNumber}: ${otp}`);
        res.status(200).json({
          message: 'OTP generated. Check console for OTP code (SMS sending failed).',
          phone: fullPhoneNumber,
          otp: otp, // Only in development
        });
        return;
      }
      // In production, return error
      res.status(500).json({
        message: 'Failed to send OTP. Please try again later.',
      });
      return;
    }

    // Success response (don't include OTP in production)
    const isDevelopment = process.env.NODE_ENV !== 'production';
    res.status(200).json({
      message: 'OTP sent successfully',
      phone: fullPhoneNumber,
      ...(isDevelopment && { otp }), // Only include OTP in development
    });
  } catch (error: any) {
    console.error('Error sending order OTP:', error);
    res.status(500).json({
      message: error.message || 'Failed to send OTP',
    });
  }
};

// Verify OTP and create order
export const verifyOTPAndCreateOrder = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const {
      otp,
      phone,
      countryCode,
      type,
      deliveryType,
      pickupLocation,
      dropoffLocation,
      vehicleType,
      orderCategory,
      senderName,
      senderCity,
      senderVillage,
      senderStreetDetails,
      deliveryNotes,
    } = req.body;

    // Validate OTP
    if (!otp || typeof otp !== 'string' || otp.length !== 6) {
      res.status(400).json({
        message: 'A valid 6-digit OTP is required',
      });
      return;
    }

    // Validate phone
    if (!phone || typeof phone !== 'string' || phone.trim().length < 9) {
      res.status(400).json({
        message: 'A valid phone number is required',
      });
      return;
    }

    const normalizedCountryCode = countryCode || '+970';
    const cleanPhone = phone.replace(/[^\d]/g, '');
    const rawFullPhoneNumber = `${normalizedCountryCode}${cleanPhone}`;
    
    // Normalize phone number before lookup
    const fullPhoneNumber = normalizePhoneNumber(rawFullPhoneNumber);
    if (!fullPhoneNumber) {
      res.status(400).json({
        message: 'Invalid phone number format',
      });
      return;
    }

    // Find user by phone (check both normalized and raw formats)
    const user = await User.findOne({ 
      $or: [
        { phone: fullPhoneNumber },
        { phone: rawFullPhoneNumber },
      ]
    });

    if (!user) {
      res.status(404).json({
        message: 'No OTP request found for this phone number. Please request a new OTP.',
      });
      return;
    }

    // Verify OTP
    if (user.otpCode !== otp) {
      res.status(400).json({
        message: 'Invalid OTP code',
      });
      return;
    }

    if (user.otpExpires && new Date() > user.otpExpires) {
      res.status(400).json({
        message: 'OTP has expired. Please request a new OTP.',
      });
      return;
    }

    // Clear OTP and mark as verified (phone-based customers are verified)
    user.otpCode = undefined;
    user.otpExpires = undefined;
    user.isEmailVerified = true; // Phone-based customers are verified by default
    
    // Normalize phone number if it's different
    if (user.phone !== fullPhoneNumber) {
      user.phone = fullPhoneNumber;
    }

    // Update user information from order
    if (senderName && senderName.trim()) {
      user.name = senderName.trim();
    }

    if (senderCity && senderCity.trim()) {
      user.city = senderCity.trim();
    }
    if (senderVillage && senderVillage.trim()) {
      user.village = senderVillage.trim();
    }
    if (senderStreetDetails && senderStreetDetails.trim()) {
      user.streetDetails = senderStreetDetails.trim();
    }

    // Generate formatted address
    if (senderCity || senderVillage || senderStreetDetails) {
      const addressParts = [];
      if (senderCity && senderCity.trim()) addressParts.push(senderCity.trim());
      if (senderVillage && senderVillage.trim()) addressParts.push(senderVillage.trim());
      if (senderStreetDetails && senderStreetDetails.trim()) addressParts.push(senderStreetDetails.trim());
      if (addressParts.length > 0) {
        user.address = addressParts.join('-');
      }
    }

    // Update customer location based on order type
    if (pickupLocation && dropoffLocation) {
      let locationToUse: { lat: number; lng: number } | null = null;
      
      if (type === 'send' && pickupLocation.lat && pickupLocation.lng) {
        locationToUse = {
          lat: typeof pickupLocation.lat === 'number' ? pickupLocation.lat : parseFloat(pickupLocation.lat),
          lng: typeof pickupLocation.lng === 'number' ? pickupLocation.lng : parseFloat(pickupLocation.lng),
        };
      } else if (type === 'receive' && dropoffLocation.lat && dropoffLocation.lng) {
        locationToUse = {
          lat: typeof dropoffLocation.lat === 'number' ? dropoffLocation.lat : parseFloat(dropoffLocation.lat),
          lng: typeof dropoffLocation.lng === 'number' ? dropoffLocation.lng : parseFloat(dropoffLocation.lng),
        };
      }
      
      if (locationToUse && !isNaN(locationToUse.lat) && !isNaN(locationToUse.lng)) {
        user.location = locationToUse;
      }
    }

    await user.save();

    // Validate order data (reuse validation from createOrder)
    if (!vehicleType || !['car', 'bike', 'cargo'].includes(vehicleType)) {
      res.status(400).json({
        message: 'A valid vehicleType is required',
      });
      return;
    }

    const settings = await Settings.getSettings();
    const vehicleConfig = settings.vehicleTypes[vehicleType as 'bike' | 'car' | 'cargo'];
    if (!vehicleConfig || !vehicleConfig.enabled) {
      res.status(400).json({
        message: `Vehicle type ${vehicleType} is not currently available`,
      });
      return;
    }

    if (!deliveryType || !['internal', 'external'].includes(deliveryType)) {
      res.status(400).json({
        message: 'A valid deliveryType is required (internal or external)',
      });
      return;
    }

    if (typeof orderCategory !== 'string' || !orderCategory.trim()) {
      res.status(400).json({
        message: 'Order category is required',
      });
      return;
    }

    if (typeof senderName !== 'string' || !senderName.trim()) {
      res.status(400).json({
        message: 'Sender name is required',
      });
      return;
    }

    if (!senderCity || typeof senderCity !== 'string' || !senderCity.trim()) {
      res.status(400).json({
        message: 'Sender city is required',
      });
      return;
    }

    if (!senderVillage || typeof senderVillage !== 'string' || !senderVillage.trim()) {
      res.status(400).json({
        message: 'Sender village is required',
      });
      return;
    }

    if (!senderStreetDetails || typeof senderStreetDetails !== 'string' || !senderStreetDetails.trim()) {
      res.status(400).json({
        message: 'Sender street details are required',
      });
      return;
    }

    if (typeof deliveryNotes !== 'string' || !deliveryNotes.trim()) {
      res.status(400).json({
        message: 'Delivery notes are required',
      });
      return;
    }

    if (!pickupLocation || !dropoffLocation) {
      res.status(400).json({
        message: 'pickupLocation and dropoffLocation are required',
      });
      return;
    }

    // Calculate distance and price
    let distance: number | undefined;
    if (
      typeof pickupLocation.lat === 'number' &&
      typeof pickupLocation.lng === 'number' &&
      typeof dropoffLocation.lat === 'number' &&
      typeof dropoffLocation.lng === 'number'
    ) {
      distance = calculateDistance(pickupLocation, dropoffLocation);
    }

    const estimatedPrice = await calculateEstimatedPrice({
      vehicleType: vehicleType as 'bike' | 'car' | 'cargo',
      distanceKm: distance,
    });

    // Validate order category
    const trimmedCategory = orderCategory.trim();
    const category = await OrderCategory.findOne({
      name: { $regex: `^${escapeRegExp(trimmedCategory)}$`, $options: 'i' },
      isActive: true,
    });

    if (!category) {
      res.status(400).json({
        message: 'Selected order category is not available',
      });
      return;
    }

    // Generate formatted address
    const formattedAddress = `${senderCity.trim()}-${senderVillage.trim()}-${senderStreetDetails.trim()}`;

    // Split phone number into country code and local number
    const phoneParts = splitPhoneNumber(user.phone || fullPhoneNumber);

    // Create order
    const order = await Order.create({
      customerId: user._id,
      type,
      deliveryType,
      pickupLocation,
      dropoffLocation,
      vehicleType,
      orderCategory: category.name,
      senderName: senderName.trim(),
      senderCity: senderCity.trim(),
      senderVillage: senderVillage.trim(),
      senderStreetDetails: senderStreetDetails.trim(),
      senderAddress: formattedAddress,
      senderPhoneNumber: parseInt(cleanPhone),
      phone: phoneParts?.phone,
      countryCode: phoneParts?.countryCode,
      deliveryNotes: deliveryNotes.trim(),
      price: estimatedPrice,
      estimatedPrice,
      distance,
      status: 'pending',
    });

    await order.populate([
      { path: 'customerId', select: 'name email phone countryCode' },
      { path: 'driverId', select: 'name email phone countryCode' },
    ]);

    const orderData = order.toObject();

    emitNewOrder(orderData);

    // Send push notification to relevant drivers about new order
    // Determine customer location based on order type
    let customerLocation: { lat: number; lng: number } | null = null;
    if (type === 'send' && pickupLocation.lat && pickupLocation.lng) {
      customerLocation = {
        lat: typeof pickupLocation.lat === 'number' ? pickupLocation.lat : parseFloat(pickupLocation.lat),
        lng: typeof pickupLocation.lng === 'number' ? pickupLocation.lng : parseFloat(pickupLocation.lng),
      };
    } else if (type === 'receive' && dropoffLocation.lat && dropoffLocation.lng) {
      customerLocation = {
        lat: typeof dropoffLocation.lat === 'number' ? dropoffLocation.lat : parseFloat(dropoffLocation.lat),
        lng: typeof dropoffLocation.lng === 'number' ? dropoffLocation.lng : parseFloat(dropoffLocation.lng),
      };
    }

    if (customerLocation) {
      // Send notifications asynchronously (don't block response)
      sendNewOrderNotificationToDrivers(
        order._id.toString(),
        vehicleType as 'bike' | 'car' | 'cargo',
        deliveryType as 'internal' | 'external',
        customerLocation,
        orderData
      ).catch((error) => {
        console.error('Error sending new order notifications to drivers:', error);
      });
    }

    // Generate JWT token for the user
    const token = generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email || '',
    });

    res.status(201).json({
      message: 'Order created successfully',
      order: orderData,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        countryCode: user.countryCode,
        role: user.role,
      },
    });
  } catch (error: any) {
    console.error('Error verifying OTP and creating order:', error);
    res.status(500).json({
      message: error.message || 'Failed to verify OTP and create order',
    });
  }
};

// Create order with Firebase ID Token (phone verified via Firebase)
export const createOrderWithFirebaseToken = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const {
      idToken,
      type,
      deliveryType,
      pickupLocation,
      dropoffLocation,
      vehicleType,
      orderCategory,
      senderName,
      senderCity,
      senderVillage,
      senderStreetDetails,
      deliveryNotes,
    } = req.body;

    // Verify Firebase ID token
    let decodedToken;
    try {
      decodedToken = await admin.auth().verifyIdToken(idToken);
    } catch (error: any) {
      console.error('Firebase token verification error:', error);
      res.status(401).json({ message: 'Invalid or expired Firebase token' });
      return;
    }

    // Extract phone number from Firebase token
    const rawPhoneNumber = decodedToken.phone_number;
    if (!rawPhoneNumber) {
      res.status(400).json({ message: 'Phone number not found in Firebase token' });
      return;
    }

    // Normalize phone number before storage
    const phoneNumber = normalizePhoneNumber(rawPhoneNumber);
    if (!phoneNumber) {
      res.status(400).json({ message: 'Invalid phone number format in Firebase token' });
      return;
    }

    // Find or create user by phone number (check both normalized and raw formats)
    let user = await User.findOne({ 
      $or: [
        { phone: phoneNumber },
        { phone: rawPhoneNumber },
      ]
    });

    if (!user) {
      // Create new user with normalized phone number
      user = await User.create({
        name: senderName?.trim() || 'Customer',
        phone: phoneNumber,
        countryCode: phoneNumber.startsWith('+') ? phoneNumber.substring(0, 4) : '+970',
        role: 'customer',
        isEmailVerified: true,
      });
    } else {
      // Update existing user information from order
      if (senderName && senderName.trim()) {
        user.name = senderName.trim();
      }
      // Normalize phone number if it's different
      if (user.phone !== phoneNumber) {
        user.phone = phoneNumber;
      }
    }

    // Update user address information
    if (senderCity && senderCity.trim()) {
      user.city = senderCity.trim();
    }
    if (senderVillage && senderVillage.trim()) {
      user.village = senderVillage.trim();
    }
    if (senderStreetDetails && senderStreetDetails.trim()) {
      user.streetDetails = senderStreetDetails.trim();
    }

    // Generate formatted address
    if (senderCity || senderVillage || senderStreetDetails) {
      const addressParts = [];
      if (senderCity && senderCity.trim()) addressParts.push(senderCity.trim());
      if (senderVillage && senderVillage.trim()) addressParts.push(senderVillage.trim());
      if (senderStreetDetails && senderStreetDetails.trim()) addressParts.push(senderStreetDetails.trim());
      if (addressParts.length > 0) {
        user.address = addressParts.join('-');
      }
    }

    // Update customer location based on order type
    if (pickupLocation && dropoffLocation) {
      let locationToUse: { lat: number; lng: number } | null = null;
      
      if (type === 'send' && pickupLocation.lat && pickupLocation.lng) {
        locationToUse = {
          lat: typeof pickupLocation.lat === 'number' ? pickupLocation.lat : parseFloat(pickupLocation.lat),
          lng: typeof pickupLocation.lng === 'number' ? pickupLocation.lng : parseFloat(pickupLocation.lng),
        };
      } else if (type === 'receive' && dropoffLocation.lat && dropoffLocation.lng) {
        locationToUse = {
          lat: typeof dropoffLocation.lat === 'number' ? dropoffLocation.lat : parseFloat(dropoffLocation.lat),
          lng: typeof dropoffLocation.lng === 'number' ? dropoffLocation.lng : parseFloat(dropoffLocation.lng),
        };
      }
      
      if (locationToUse && !isNaN(locationToUse.lat) && !isNaN(locationToUse.lng)) {
        user.location = locationToUse;
      }
    }

    user.isEmailVerified = true;
    await user.save();

    // Validate order data
    if (!vehicleType || !['car', 'bike', 'cargo'].includes(vehicleType)) {
      res.status(400).json({ message: 'A valid vehicleType is required' });
      return;
    }

    const settings = await Settings.getSettings();
    const vehicleConfig = settings.vehicleTypes[vehicleType as 'bike' | 'car' | 'cargo'];
    if (!vehicleConfig || !vehicleConfig.enabled) {
      res.status(400).json({
        message: `Vehicle type ${vehicleType} is not currently available`,
      });
      return;
    }

    if (!deliveryType || !['internal', 'external'].includes(deliveryType)) {
      res.status(400).json({
        message: 'A valid deliveryType is required (internal or external)',
      });
      return;
    }

    if (typeof orderCategory !== 'string' || !orderCategory.trim()) {
      res.status(400).json({ message: 'Order category is required' });
      return;
    }

    if (typeof senderName !== 'string' || !senderName.trim()) {
      res.status(400).json({ message: 'Sender name is required' });
      return;
    }

    if (!senderCity || typeof senderCity !== 'string' || !senderCity.trim()) {
      res.status(400).json({ message: 'Sender city is required' });
      return;
    }

    if (!senderVillage || typeof senderVillage !== 'string' || !senderVillage.trim()) {
      res.status(400).json({ message: 'Sender village is required' });
      return;
    }

    if (!senderStreetDetails || typeof senderStreetDetails !== 'string' || !senderStreetDetails.trim()) {
      res.status(400).json({ message: 'Sender street details are required' });
      return;
    }

    if (!pickupLocation || !dropoffLocation) {
      res.status(400).json({
        message: 'pickupLocation and dropoffLocation are required',
      });
      return;
    }

    // Calculate distance and price
    let distance: number | undefined;
    if (
      typeof pickupLocation.lat === 'number' &&
      typeof pickupLocation.lng === 'number' &&
      typeof dropoffLocation.lat === 'number' &&
      typeof dropoffLocation.lng === 'number'
    ) {
      distance = calculateDistance(pickupLocation, dropoffLocation);
    }

    const estimatedPrice = await calculateEstimatedPrice({
      vehicleType: vehicleType as 'bike' | 'car' | 'cargo',
      distanceKm: distance,
    });

    // Validate order category
    const trimmedCategory = orderCategory.trim();
    const category = await OrderCategory.findOne({
      name: { $regex: `^${escapeRegExp(trimmedCategory)}$`, $options: 'i' },
      isActive: true,
    });

    if (!category) {
      res.status(400).json({
        message: 'Selected order category is not available',
      });
      return;
    }

    // Generate formatted address
    const formattedAddress = `${senderCity.trim()}-${senderVillage.trim()}-${senderStreetDetails.trim()}`;

    // Split phone number into country code and local number
    const phoneParts = splitPhoneNumber(user.phone || phoneNumber);
    
    // Extract phone number digits for senderPhoneNumber (backward compatibility)
    const cleanPhone = phoneNumber.replace(/[^\d]/g, '');
    const senderPhoneNumber = parseInt(cleanPhone) || 0;

    // Create order
    const order = await Order.create({
      customerId: user._id,
      type,
      deliveryType,
      pickupLocation,
      dropoffLocation,
      vehicleType,
      orderCategory: category.name,
      senderName: senderName.trim(),
      senderCity: senderCity.trim(),
      senderVillage: senderVillage.trim(),
      senderStreetDetails: senderStreetDetails.trim(),
      senderAddress: formattedAddress,
      senderPhoneNumber,
      phone: phoneParts?.phone,
      countryCode: phoneParts?.countryCode,
      deliveryNotes: deliveryNotes?.trim() || '',
      price: estimatedPrice,
      estimatedPrice,
      distance,
      status: 'pending',
    });

    await order.populate([
      { path: 'customerId', select: 'name email phone countryCode' },
      { path: 'driverId', select: 'name email phone countryCode' },
    ]);

    const orderData = order.toObject();

    emitNewOrder(orderData);

    // Send push notification to relevant drivers about new order
    // Determine customer location based on order type
    let customerLocation: { lat: number; lng: number } | null = null;
    if (type === 'send' && pickupLocation.lat && pickupLocation.lng) {
      customerLocation = {
        lat: typeof pickupLocation.lat === 'number' ? pickupLocation.lat : parseFloat(pickupLocation.lat),
        lng: typeof pickupLocation.lng === 'number' ? pickupLocation.lng : parseFloat(pickupLocation.lng),
      };
    } else if (type === 'receive' && dropoffLocation.lat && dropoffLocation.lng) {
      customerLocation = {
        lat: typeof dropoffLocation.lat === 'number' ? dropoffLocation.lat : parseFloat(dropoffLocation.lat),
        lng: typeof dropoffLocation.lng === 'number' ? dropoffLocation.lng : parseFloat(dropoffLocation.lng),
      };
    }

    if (customerLocation) {
      // Send notifications asynchronously (don't block response)
      sendNewOrderNotificationToDrivers(
        order._id.toString(),
        vehicleType as 'bike' | 'car' | 'cargo',
        deliveryType as 'internal' | 'external',
        customerLocation,
        orderData
      ).catch((error) => {
        console.error('Error sending new order notifications to drivers:', error);
      });
    }

    // Generate JWT token for the user
    const token = generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email || phoneNumber,
    });

    res.status(201).json({
      message: 'Order created successfully',
      order: orderData,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        countryCode: user.countryCode,
        role: user.role,
      },
    });
  } catch (error: any) {
    console.error('Error creating order with Firebase token:', error);
    res.status(500).json({
      message: error.message || 'Failed to create order',
    });
  }
};


