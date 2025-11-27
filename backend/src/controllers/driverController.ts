import { Response } from 'express';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import User from '../models/User';
import { AuthRequest } from '../middleware/auth';
import { checkAndSuspendDriverIfNeeded, calculateDriverBalance, calculateDriverBalancesBatch, checkAndSuspendDriversBatch } from '../utils/balance';
import Settings from '../models/Settings';

// Get all drivers (admin only)
export const getAllDrivers = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { search, status, page, limit, includeBalance } = req.query;
    const query: any = { role: 'driver' };

    // Search by name, email, or phone
    if (search && typeof search === 'string') {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } },
        { phone: { $regex: search, $options: 'i' } },
      ];
    }

    // Filter by active status
    if (status === 'active') {
      query.isActive = { $ne: false };
    } else if (status === 'inactive') {
      query.isActive = false;
    }

    // Pagination
    const pageNum = parseInt(page as string) || 1;
    const limitNum = parseInt(limit as string) || 50;
    const skip = (pageNum - 1) * limitNum;

    // Get total count for pagination
    const totalCount = await User.countDocuments(query);

    // Fetch drivers with pagination
    const drivers = await User.find(query)
      .select('-password -otpCode -otpExpires')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limitNum);

    // Get settings for max allowed balance
    const settings = await Settings.getSettings();
    const maxAllowedBalance = settings.maxAllowedBalance || 3;

    // Only calculate balances if requested (for performance)
    let driversWithBalance;
    if (includeBalance === 'true') {
      // Batch calculate balances for all drivers efficiently
      const driverIds = drivers.map((d) => d._id as mongoose.Types.ObjectId);
      const balanceMap = await calculateDriverBalancesBatch(driverIds);

      // Batch check and suspend/reactivate drivers (much more efficient)
      await checkAndSuspendDriversBatch(driverIds, balanceMap);

      // Refresh drivers after potential suspension changes
      const refreshedDrivers = await User.find({
        _id: { $in: driverIds },
      }).select('-password -otpCode -otpExpires');

      // Map drivers with balance info
      driversWithBalance = refreshedDrivers.map((driver) => {
        const balanceInfo = balanceMap.get(driver._id.toString());
        if (!balanceInfo) {
          return driver.toObject();
        }

        const balanceExceeded = balanceInfo.currentBalance >= maxAllowedBalance;
        const suspensionReason =
          balanceExceeded && driver.isActive === false
            ? 'Exceeded Balance Limit'
            : null;
        const wasReactivated =
          balanceInfo.currentBalance <= 0 && driver.isActive === true;

        return {
          ...driver.toObject(),
          balance: balanceInfo.currentBalance,
          balanceExceeded,
          suspensionReason,
          maxAllowedBalance,
          wasReactivated,
        };
      });
    } else {
      // Return drivers without balance calculation for faster response
      driversWithBalance = drivers.map((driver) => driver.toObject());
    }

    res.status(200).json({
      drivers: driversWithBalance,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: totalCount,
        totalPages: Math.ceil(totalCount / limitNum),
      },
    });
  } catch (error: any) {
    console.error('Get all drivers error:', error);
    res.status(500).json({ message: error.message || 'Failed to get drivers' });
  }
};

// Get driver by ID
export const getDriverById = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { driverId } = req.params;
    const driver = await User.findOne({ _id: driverId, role: 'driver' })
      .select('-password -otpCode -otpExpires');

    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    res.status(200).json({ driver });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get driver' });
  }
};

// Create new driver (admin only)
export const createDriver = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { name, email, phone, password, vehicleType, isActive } = req.body;

    // Validation
    if (!name) {
      res.status(400).json({ message: 'Name is required' });
      return;
    }

    if (!email) {
      res.status(400).json({ message: 'Email is required' });
      return;
    }

    if (!phone) {
      res.status(400).json({ message: 'Phone number is required' });
      return;
    }

    if (!password || password.length < 6) {
      res.status(400).json({ message: 'Password is required and must be at least 6 characters' });
      return;
    }

    if (!vehicleType || !['car', 'bike', 'cargo'].includes(vehicleType)) {
      res.status(400).json({ message: 'Valid vehicle type (car, bike, cargo) is required' });
      return;
    }

    // Check if user exists
    const existingUser = await User.findOne({
      $or: [
        { email },
        { phone },
      ],
    });

    if (existingUser) {
      res.status(400).json({ message: 'User already exists with this email or phone' });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create driver
    const driver = await User.create({
      name,
      email,
      phone,
      password: hashedPassword,
      role: 'driver',
      vehicleType,
      isActive: isActive !== undefined ? isActive : true,
      isEmailVerified: true, // Admin-created drivers are pre-verified
      isAvailable: false,
    });

    // Convert to plain object and remove sensitive fields
    const driverObj = driver.toObject();
    delete driverObj.password;
    delete driverObj.otpCode;
    delete driverObj.otpExpires;

    res.status(201).json({
      message: 'Driver created successfully',
      driver: driverObj,
    });
  } catch (error: any) {
    console.error('Create driver error:', error);
    res.status(500).json({ message: error.message || 'Failed to create driver' });
  }
};

// Update driver (admin only)
export const updateDriver = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { driverId } = req.params;
    const { name, email, phone, vehicleType, isActive } = req.body;

    const driver = await User.findOne({ _id: driverId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    // Check if email/phone already exists (excluding current driver)
    if (email || phone) {
      const existingUser = await User.findOne({
        _id: { $ne: driverId },
        $or: [
          ...(email ? [{ email }] : []),
          ...(phone ? [{ phone }] : []),
        ],
      });

      if (existingUser) {
        res.status(400).json({ message: 'Email or phone already exists' });
        return;
      }
    }

    // Update fields
    if (name) driver.name = name;
    if (email !== undefined) driver.email = email || undefined;
    if (phone !== undefined) driver.phone = phone || undefined;
    if (vehicleType) driver.vehicleType = vehicleType;
    if (isActive !== undefined) driver.isActive = isActive;

    await driver.save();

    const updatedDriver = await User.findById(driverId)
      .select('-password -otpCode -otpExpires');

    res.status(200).json({
      message: 'Driver updated successfully',
      driver: updatedDriver,
    });
  } catch (error: any) {
    console.error('Update driver error:', error);
    res.status(500).json({ message: error.message || 'Failed to update driver' });
  }
};

// Reset/Change driver password (admin only)
export const resetDriverPassword = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { driverId } = req.params;
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      res.status(400).json({ message: 'Password must be at least 6 characters' });
      return;
    }

    const driver = await User.findOne({ _id: driverId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    driver.password = hashedPassword;
    await driver.save();

    res.status(200).json({ message: 'Password reset successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to reset password' });
  }
};

// Toggle driver active status (admin only)
export const toggleDriverStatus = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { driverId } = req.params;
    const driver = await User.findOne({ _id: driverId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    driver.isActive = !driver.isActive;
    await driver.save();

    res.status(200).json({
      message: `Driver ${driver.isActive ? 'activated' : 'deactivated'} successfully`,
      driver: {
        id: driver._id,
        name: driver.name,
        isActive: driver.isActive,
      },
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to toggle driver status' });
  }
};

// Delete driver (admin only)
export const deleteDriver = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const { driverId } = req.params;
    const driver = await User.findOne({ _id: driverId, role: 'driver' });
    if (!driver) {
      res.status(404).json({ message: 'Driver not found' });
      return;
    }

    await User.findByIdAndDelete(driverId);

    res.status(200).json({ message: 'Driver deleted successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to delete driver' });
  }
};

