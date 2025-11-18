import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import User from '../models/User';
import { generateToken } from '../utils/jwt';
import { generateAndSendOTP, generateOTP } from '../utils/otp';
import { AuthRequest } from '../middleware/auth';
import admin from '../config/firebase';

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
    let otp: string;
    try {
      otp = await generateAndSendOTP(email);
    } catch (error: any) {
      console.error('Error generating/sending OTP:', error);
      // Still generate OTP even if email fails (for development/testing)
      otp = generateOTP();
      console.warn(`⚠️  Email sending failed. Generated OTP for ${email}: ${otp}`);
      console.warn(`⚠️  Error: ${error.message}`);
    }
    
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
    console.error('Registration error:', error);
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

    if (!user.email) {
      res.status(400).json({ message: 'User email is missing' });
      return;
    }

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
        isAvailable: user.isAvailable,
        profilePicture: user.profilePicture,
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

    if (!user.password) {
      res.status(401).json({ message: 'Invalid credentials' });
      return;
    }

    if (!user.email) {
      res.status(401).json({ message: 'User email is missing' });
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
        profilePicture: user.profilePicture,
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

    // Generate OTP
    let otp: string;
    try {
      otp = await generateAndSendOTP(email);
    } catch (error: any) {
      console.error('Error generating/sending OTP:', error);
      // Still generate OTP even if email fails (for development/testing)
      otp = generateOTP();
      console.warn(`⚠️  Email sending failed. Generated OTP for ${email}: ${otp}`);
      console.warn(`⚠️  Error: ${error.message}`);
    }
    
    user.otpCode = otp;
    user.otpExpires = new Date(Date.now() + 10 * 60 * 1000);
    await user.save();

    res.status(200).json({ message: 'OTP resent successfully' });
  } catch (error: any) {
    console.error('Resend OTP error:', error);
    res.status(500).json({ message: error.message || 'Failed to resend OTP' });
  }
};

export const verifyFirebaseToken = async (
  req: Request,
  res: Response
): Promise<void> => {
  try {
    const { idToken } = req.body;

    if (!idToken) {
      res.status(400).json({ message: 'Firebase ID token is required' });
      return;
    }

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
    const phoneNumber = decodedToken.phone_number;
    if (!phoneNumber) {
      res.status(400).json({ message: 'Phone number not found in Firebase token' });
      return;
    }

    // Find or create user by phone number
    let user = await User.findOne({ phone: phoneNumber });

    if (!user) {
      // Create new user with phone number
      user = await User.create({
        name: 'Customer', // Temporary name, can be updated later
        phone: phoneNumber,
        countryCode: phoneNumber.startsWith('+') ? phoneNumber.substring(0, 4) : '+970',
        role: 'customer',
        isEmailVerified: true, // Phone-based users are verified by default
      });
    } else {
      // Update existing user - ensure they're marked as verified
      user.isEmailVerified = true;
      await user.save();
    }

    // Generate backend JWT token
    const token = generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email || phoneNumber, // Use phone as email fallback
    });

    res.status(200).json({
      message: 'Firebase token verified successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        countryCode: user.countryCode,
        role: user.role,
        vehicleType: user.vehicleType,
        isAvailable: user.isAvailable,
        profilePicture: user.profilePicture,
      },
    });
  } catch (error: any) {
    console.error('Firebase token verification error:', error);
    res.status(500).json({ message: error.message || 'Failed to verify Firebase token' });
  }
};

export const getCurrentUser = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    const user = await User.findById(req.user.userId).select('-password -otpCode -otpExpires');
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    // Return user data with all fields including phone, countryCode, address, profilePicture
    const userData: any = {
      id: user._id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      countryCode: user.countryCode,
      address: user.address,
      city: user.city,
      village: user.village,
      streetDetails: user.streetDetails,
      role: user.role,
      vehicleType: user.vehicleType,
      isAvailable: user.isAvailable,
      location: user.location,
      profilePicture: user.profilePicture,
      createdAt: user.createdAt,
    };

    res.status(200).json({ user: userData });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get user' });
  }
};
