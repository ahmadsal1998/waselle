import { Response } from 'express';
import mongoose from 'mongoose';
import Payment from '../models/Payment';
import User from '../models/User';
import { AuthRequest } from '../middleware/auth';
import { calculateDriverBalance, checkAndSuspendDriverIfNeeded, resetDriverBalance } from '../utils/balance';

// Add payment for a driver (admin only)
export const addPayment = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { driverId } = req.params;
    const { amount, date, notes } = req.body;

    // Validation
    if (!amount || typeof amount !== 'number' || amount <= 0) {
      res.status(400).json({ message: 'Valid payment amount is required' });
      return;
    }

    // Convert driverId to ObjectId
    const driverObjectId = new mongoose.Types.ObjectId(driverId);

    // Check if driver exists
    const driver = await User.findOne({ _id: driverObjectId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    // Create payment
    const payment = await Payment.create({
      driverId: driverObjectId,
      amount,
      date: date ? new Date(date) : new Date(),
      notes: notes || undefined,
    });

    // Reset driver balance to 0 and update last settlement date
    await resetDriverBalance(driverObjectId);
    console.log(`Driver ${driverObjectId} balance reset to 0 after payment of ${amount} NIS`);

    // Check if reactivation is needed (balance is now 0)
    const suspensionResult = await checkAndSuspendDriverIfNeeded(driverObjectId, 0);
    
    // Recalculate balance info for response (should be 0 now)
    const balanceInfo = await calculateDriverBalance(driverObjectId);

    // Refresh driver data after potential status change
    const updatedDriver = await User.findById(driverObjectId)
      .select('-password -otpCode -otpExpires');

    // Determine success message based on status change
    let successMessage = 'Payment added successfully';
    if (suspensionResult.reactivated) {
      successMessage = 'Payment added successfully. Driver account has been automatically reactivated (balance cleared).';
    } else if (suspensionResult.suspended) {
      successMessage = 'Payment added successfully. Driver account remains suspended (balance still exceeds limit).';
    }

    res.status(201).json({
      message: successMessage,
      payment,
      balanceInfo,
      driver: updatedDriver,
      suspensionStatus: {
        suspended: suspensionResult.suspended,
        reactivated: suspensionResult.reactivated,
        balance: suspensionResult.balance,
        maxAllowed: suspensionResult.maxAllowed,
      },
    });
  } catch (error: any) {
    console.error('Add payment error:', error);
    res.status(500).json({ message: error.message || 'Failed to add payment' });
  }
};

// Get all payments for a driver (admin only)
export const getDriverPayments = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { driverId } = req.params;
    const { page, limit } = req.query;

    // Convert driverId to ObjectId
    const driverObjectId = new mongoose.Types.ObjectId(driverId);

    // Check if driver exists
    const driver = await User.findOne({ _id: driverObjectId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    // Pagination
    const pageNum = parseInt(page as string) || 1;
    const limitNum = parseInt(limit as string) || 50;
    const skip = (pageNum - 1) * limitNum;

    // Get total count for pagination
    const totalCount = await Payment.countDocuments({ driverId: driverObjectId });

    const payments = await Payment.find({ driverId: driverObjectId })
      .sort({ date: -1, createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    res.status(200).json({
      payments,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: totalCount,
        totalPages: Math.ceil(totalCount / limitNum),
      },
    });
  } catch (error: any) {
    console.error('Get driver payments error:', error);
    res.status(500).json({ message: error.message || 'Failed to get payments' });
  }
};

// Get driver balance information (admin only)
export const getDriverBalance = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { driverId } = req.params;

    // Convert driverId to ObjectId
    const driverObjectId = new mongoose.Types.ObjectId(driverId);

    // Check if driver exists
    const driver = await User.findOne({ _id: driverObjectId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    const balanceInfo = await calculateDriverBalance(driverObjectId);

    res.status(200).json({ balanceInfo });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get driver balance' });
  }
};

