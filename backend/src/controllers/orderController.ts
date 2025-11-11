import { Response } from 'express';
import mongoose from 'mongoose';
import Order from '../models/Order';
import User from '../models/User';
import { AuthRequest } from '../middleware/auth';
import { calculateDistance } from '../utils/distance';
import { calculateEstimatedPrice } from '../utils/pricing';
import { emitNewOrder, emitOrderAccepted } from '../services/socketService';
import OrderCategory from '../models/OrderCategory';

const escapeRegExp = (value: string): string =>
  value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export const createOrder = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const {
      type,
      pickupLocation,
      dropoffLocation,
      vehicleType,
      orderCategory,
      senderName,
      senderAddress,
      senderPhoneNumber,
      deliveryNotes,
    } = req.body;

    if (!vehicleType || !['car', 'bike'].includes(vehicleType)) {
      res.status(400).json({
        message: 'A valid vehicleType is required',
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

    if (typeof senderAddress !== 'string' || !senderAddress.trim()) {
      res.status(400).json({
        message: 'Sender address is required',
      });
      return;
    }

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

    const estimatedPrice = calculateEstimatedPrice({
      vehicleType,
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

    const order = await Order.create({
      customerId: req.user.userId,
      type,
      pickupLocation,
      dropoffLocation,
      vehicleType,
      orderCategory: category.name,
      senderName: senderName.trim(),
      senderAddress: senderAddress.trim(),
      senderPhoneNumber: Math.trunc(parsedPhoneNumber),
      deliveryNotes: deliveryNotes.trim(),
      price: estimatedPrice,
      estimatedPrice,
      distance,
      status: 'pending',
    });

    await order.populate([
      { path: 'customerId', select: 'name email phoneNumber' },
      { path: 'driverId', select: 'name email phoneNumber' },
    ]);

    const orderData = order.toObject();

    emitNewOrder(orderData);

    res.status(201).json({
      message: 'Order created successfully',
      order: orderData,
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to create order' });
  }
};

export const estimateOrderPrice = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const { vehicleType, pickupLocation, dropoffLocation } = req.body;

    if (!vehicleType || !['car', 'bike'].includes(vehicleType)) {
      res.status(400).json({ message: 'Valid vehicleType is required' });
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

    const estimatedPrice = calculateEstimatedPrice({
      vehicleType,
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

    // Get pending orders
    const pendingOrders = await Order.find({
      status: 'pending',
      vehicleType: driver.vehicleType,
    })
      .populate('customerId', 'name email')
      .lean();

    // Calculate distances and sort
    const ordersWithDistance = pendingOrders
      .map((order) => {
        const distance = calculateDistance(
          driver.location!,
          order.pickupLocation
        );
        return {
          ...order,
          distanceFromDriver: distance,
        };
      })
      .sort((a, b) => a.distanceFromDriver - b.distanceFromDriver);

    res.status(200).json({ orders: ordersWithDistance });
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
      { path: 'customerId', select: 'name email phoneNumber' },
      { path: 'driverId', select: 'name email phoneNumber' },
    ]);

    const orderData = order.toObject();

    emitOrderAccepted(orderData);

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

    res.status(200).json({
      message: 'Order status updated successfully',
      order,
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
