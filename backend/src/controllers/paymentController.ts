import { Response } from 'express';
import Payment from '../models/Payment';
import User from '../models/User';
import { AuthRequest } from '../middleware/auth';
import { calculateDriverBalance, checkAndSuspendDriverIfNeeded } from '../utils/balance';

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

    // Check if driver exists
    const driver = await User.findOne({ _id: driverId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    // Create payment
    const payment = await Payment.create({
      driverId,
      amount,
      date: date ? new Date(date) : new Date(),
      notes: notes || undefined,
    });

    // Recalculate balance and check if suspension/reactivation is needed
    const suspensionResult = await checkAndSuspendDriverIfNeeded(driverId);
    const balanceInfo = await calculateDriverBalance(driverId);

    // Refresh driver data after potential status change
    const updatedDriver = await User.findById(driverId)
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

    // Check if driver exists
    const driver = await User.findOne({ _id: driverId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    const payments = await Payment.find({ driverId })
      .sort({ date: -1, createdAt: -1 });

    res.status(200).json({ payments });
  } catch (error: any) {
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

    // Check if driver exists
    const driver = await User.findOne({ _id: driverId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    const balanceInfo = await calculateDriverBalance(driverId);

    res.status(200).json({ balanceInfo });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get driver balance' });
  }
};

