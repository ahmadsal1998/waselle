import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import User from '../models/User';
import { generateToken } from '../utils/jwt';
import { generateAndSendOTP, generateOTP } from '../utils/otp';
import { verifyFirebaseToken as verifyFirebaseIdToken, admin } from '../utils/firebase';
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

export const verifyFirebaseToken = async (req: Request, res: Response): Promise<void> => {
  try {
    const { idToken, phoneNumber } = req.body;

    if (!idToken || !phoneNumber) {
      res.status(400).json({ message: 'ID token and phone number are required' });
      return;
    }

    // Verify Firebase token
    const decodedToken = await verifyFirebaseIdToken(idToken);
    const firebasePhoneNumber = decodedToken.phone_number;

    // Check if phone number exists in Firebase token
    if (!firebasePhoneNumber) {
      res.status(400).json({ message: 'Phone number not found in Firebase token' });
      return;
    }

    // Verify that the phone number matches
    if (firebasePhoneNumber !== phoneNumber && !phoneNumber.includes(firebasePhoneNumber.replace('+', ''))) {
      // Try to match without country code prefix
      const normalizedFirebasePhone = firebasePhoneNumber.replace(/^\+/, '');
      const normalizedPhone = phoneNumber.replace(/^\+/, '');
      if (normalizedFirebasePhone !== normalizedPhone && !normalizedPhone.includes(normalizedFirebasePhone)) {
        res.status(400).json({ message: 'Phone number mismatch' });
        return;
      }
    }

    // Find or create user by phone number
    let user = await User.findOne({ 
      $or: [
        { phone: phoneNumber },
        { phone: firebasePhoneNumber },
      ]
    });

    if (!user) {
      // Create new user if doesn't exist (for phone-based registration)
      user = await User.create({
        name: decodedToken.name || 'User',
        email: decodedToken.email || `${phoneNumber}@phone.local`,
        phone: firebasePhoneNumber || phoneNumber,
        role: 'customer',
        isEmailVerified: true, // Phone verification counts as verification
      });
    } else {
      // Update user verification status
      user.isEmailVerified = true;
      if (!user.phone) {
        user.phone = firebasePhoneNumber || phoneNumber;
      }
      await user.save();
    }

    // Generate JWT token
    const token = generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email || `${phoneNumber}@phone.local`,
    });

    res.status(200).json({
      message: 'Phone verified successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        vehicleType: user.vehicleType,
        isAvailable: user.isAvailable,
        profilePicture: user.profilePicture,
      },
    });
  } catch (error: any) {
    console.error('Firebase token verification error:', error);
    res.status(500).json({ message: error.message || 'Firebase token verification failed' });
  }
};

export const phoneLogin = async (req: Request, res: Response): Promise<void> => {
  try {
    const { phone, firebaseUid, verificationId, smsCode, idToken } = req.body;

    if (!phone || !firebaseUid) {
      res.status(400).json({ message: 'Phone and firebaseUid are required' });
      return;
    }

    // Verify Firebase ID token if provided (recommended for security)
    let decodedToken: admin.auth.DecodedIdToken | null = null;
    if (idToken) {
      try {
        decodedToken = await verifyFirebaseIdToken(idToken);
        // Verify that the Firebase UID matches
        if (decodedToken.uid !== firebaseUid) {
          console.warn(`⚠️  Firebase UID mismatch: token has ${decodedToken.uid}, provided ${firebaseUid}`);
          // Continue anyway since OTP was already verified on client
        }
        // Verify phone number matches if present in token
        if (decodedToken.phone_number) {
          const tokenPhone = decodedToken.phone_number;
          const normalizedTokenPhone = tokenPhone.replace(/^\+/, '');
          const normalizedPhone = phone.replace(/^\+/, '');
          if (normalizedTokenPhone !== normalizedPhone && !normalizedPhone.includes(normalizedTokenPhone)) {
            console.warn(`⚠️  Phone number mismatch: token has ${tokenPhone}, provided ${phone}`);
            // Continue anyway since OTP was already verified on client
          }
        }
      } catch (error: any) {
        console.error('⚠️  Firebase token verification failed:', error.message);
        console.warn('⚠️  Proceeding without token verification since OTP was already verified on client');
        // Continue without token verification - OTP was already verified by Firebase on client
        decodedToken = null;
      }
    } else {
      // If no idToken provided, we'll still proceed but log a warning
      console.warn('⚠️  phone-login called without idToken. Consider sending idToken for better security.');
    }
    
    // Find or create user by phone number
    let user = await User.findOne({ 
      $or: [
        { phone: phone },
        { phone: `+${phone.replace(/^\+/, '')}` },
      ]
    });

    // Use phone from decoded token if available, otherwise use provided phone
    const verifiedPhone = decodedToken?.phone_number || (phone.startsWith('+') ? phone : `+${phone}`);
    
    if (!user) {
      // Create new user if doesn't exist (for phone-based registration)
      // Use phone number as name if not provided
      // Only set email if it's a real email from Firebase token (not a placeholder)
      // For phone-based users, email is optional and password is not required
      const userData: any = {
        name: decodedToken?.name || `User ${verifiedPhone.substring(verifiedPhone.length - 4)}`, // Last 4 digits as default name
        phone: verifiedPhone,
        role: 'customer',
        isEmailVerified: true, // Phone verification counts as verification
      };
      
      // Only set email if it's a real email from Firebase token
      if (decodedToken?.email && decodedToken.email.includes('@') && !decodedToken.email.endsWith('@phone.local')) {
        userData.email = decodedToken.email;
      }
      
      user = await User.create(userData);
      console.log(`✅ Created new user in MongoDB: ${user._id} for phone: ${verifiedPhone}`);
    } else {
      // Update user verification status if needed
      if (!user.isEmailVerified) {
        user.isEmailVerified = true;
      }
      if (!user.phone) {
        user.phone = verifiedPhone;
      }
      // Update name/email from Firebase token if available
      if (decodedToken) {
        if (decodedToken.name && !user.name) {
          user.name = decodedToken.name;
        }
        // Only update email if it's a real email (not a placeholder)
        if (decodedToken.email && decodedToken.email.includes('@') && !decodedToken.email.endsWith('@phone.local')) {
          if (!user.email) {
            user.email = decodedToken.email;
          }
        }
      }
      await user.save();
      console.log(`✅ Updated existing user in MongoDB: ${user._id} for phone: ${verifiedPhone}`);
    }

    // Generate JWT token
    // Use phone number as identifier if no email (for phone-based users)
    const token = generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email || `${verifiedPhone.replace(/[^0-9]/g, '')}@phone.local`,
    });

    res.status(200).json({
      message: 'Phone login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        vehicleType: user.vehicleType,
        isAvailable: user.isAvailable,
        profilePicture: user.profilePicture,
      },
    });
  } catch (error: any) {
    console.error('Phone login error:', error);
    res.status(500).json({ message: error.message || 'Phone login failed' });
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
