import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import User from '../models/User';
import { generateToken } from '../utils/jwt';
import { generateAndSendOTP } from '../utils/otp';
import { AuthRequest } from '../middleware/auth';

export const register = async (req: Request, res: Response): Promise<void> => {
  try {
    const { name, email, password, role, phoneNumber, vehicleType } = req.body;
    const userRole: 'customer' | 'driver' | 'admin' = role || 'customer';

    if (userRole === 'driver') {
      if (!vehicleType || !['car', 'bike'].includes(vehicleType)) {
        res.status(400).json({ message: 'Vehicle type must be either car or bike' });
        return;
      }
    }

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser) {
      res.status(400).json({ message: 'User already exists with this email' });
      return;
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Generate OTP
    const otp = await generateAndSendOTP(email);
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Create user
    const user = await User.create({
      name,
      email,
      password: hashedPassword,
      role: userRole,
      phoneNumber,
      vehicleType: userRole === 'driver' ? vehicleType : undefined,
      otpCode: otp,
      otpExpires,
      isEmailVerified: false,
    });

    res.status(201).json({
      message: 'Registration successful. Please verify your email with OTP.',
      userId: user._id,
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Registration failed' });
  }
};

export const verifyOTP = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, otp } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    if (user.isEmailVerified) {
      res.status(400).json({ message: 'Email already verified' });
      return;
    }

    if (user.otpCode !== otp) {
      res.status(400).json({ message: 'Invalid OTP' });
      return;
    }

    if (user.otpExpires && new Date() > user.otpExpires) {
      res.status(400).json({ message: 'OTP expired' });
      return;
    }

    user.isEmailVerified = true;
    user.otpCode = undefined;
    user.otpExpires = undefined;
    await user.save();

    const token = generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    res.status(200).json({
      message: 'Email verified successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        vehicleType: user.vehicleType,
      },
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'OTP verification failed' });
  }
};

export const login = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    if (!user.isEmailVerified) {
      res.status(401).json({ message: 'Please verify your email first' });
      return;
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    const token = generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email,
    });

    res.status(200).json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        isAvailable: user.isAvailable,
        vehicleType: user.vehicleType,
      },
    });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Login failed' });
  }
};

export const resendOTP = async (req: Request, res: Response): Promise<void> => {
  try {
    const { email } = req.body;

    const user = await User.findOne({ email });
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    if (user.isEmailVerified) {
      res.status(400).json({ message: 'Email already verified' });
      return;
    }

    const otp = await generateAndSendOTP(email);
    user.otpCode = otp;
    user.otpExpires = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    res.status(200).json({ message: 'OTP resent successfully' });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to resend OTP' });
  }
};

export const getCurrentUser = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    const user = await User.findById(req.user?.userId).select('-password');
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    res.status(200).json({ user });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get user' });
  }
};
