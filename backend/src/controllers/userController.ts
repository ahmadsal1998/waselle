import { Response } from 'express';
import User from '../models/User';
import { AuthRequest } from '../middleware/auth';

export const updateLocation = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    const { lat, lng } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { location: { lat, lng } },
      { new: true }
    ).select('-password');

    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.status(200).json({
      message: 'Location updated successfully',
      user,
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update location',
    });
  }
};

export const updateAvailability = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    const { isAvailable } = req.body;

    const user = await User.findByIdAndUpdate(
      req.user.userId,
      { isAvailable },
      { new: true }
    ).select('-password');

    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.status(200).json({
      message: 'Availability updated successfully',
      user,
    });
  } catch (error: any) {
    res.status(500).json({
      message: error.message || 'Failed to update availability',
    });
  }
};

export const getAllUsers = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user || req.user.role !== 'admin') {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const users = await User.find().select('-password').sort({ createdAt: -1 });

    res.status(200).json({ users });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get users' });
  }
};

export const getUserById = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    const { userId } = req.params;

    // Only admin or the user themselves can access
    if (req.user.role !== 'admin' && req.user.userId !== userId) {
      res.status(403).json({ message: 'Access denied' });
      return;
    }

    const user = await User.findById(userId).select('-password');
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.status(200).json({ user });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get user' });
  }
};

export const getAvailableDrivers = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    const drivers = await User.find({
      role: 'driver',
      'location.lat': { $exists: true, $ne: null },
      'location.lng': { $exists: true, $ne: null },
    })
      .select('name email phoneNumber location isAvailable updatedAt vehicleType')
      .lean();

    res.status(200).json({ drivers });
  } catch (error: any) {
    res
      .status(500)
      .json({ message: error.message || 'Failed to get available drivers' });
  }
};
