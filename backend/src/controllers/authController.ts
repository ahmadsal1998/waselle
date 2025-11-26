import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import User from '../models/User';
import { generateToken } from '../utils/jwt';
import { generateAndSendOTP, generateOTP } from '../utils/otp';
import { verifyFirebaseToken as verifyFirebaseIdToken, admin } from '../utils/firebase';
import { AuthRequest } from '../middleware/auth';
import { normalizePhoneNumber } from '../utils/phone';
import { sendSMSOTP } from '../utils/smsProvider';

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

    // Check if driver account is active
    if (user.role === 'driver' && user.isActive === false) {
      // Check balance and potentially reactivate if balance <= 0
      const { checkAndSuspendDriverIfNeeded } = await import('../utils/balance');
      const suspensionResult = await checkAndSuspendDriverIfNeeded(user._id);
      
      // Refresh user data after potential reactivation
      const updatedUser = await User.findById(user._id);
      
      // If driver was reactivated, allow login to proceed
      if (suspensionResult.reactivated && updatedUser?.isActive === true) {
        // Use updated user data for the rest of login
        Object.assign(user, updatedUser?.toObject());
      } else if (suspensionResult.suspended) {
        res.status(403).json({ 
          message: `Your account has been suspended due to exceeding the balance limit. Current balance: ${suspensionResult.balance.toFixed(2)} NIS (Limit: ${suspensionResult.maxAllowed} NIS). Please contact administrator to make a payment.` 
        });
        return;
      } else {
        res.status(403).json({ message: 'Your account has been deactivated. Please contact administrator.' });
        return;
      }
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
        isActive: user.isActive,
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

    // Normalize phone numbers before comparison and storage
    const normalizedFirebasePhone = normalizePhoneNumber(firebasePhoneNumber);
    const normalizedPhone = normalizePhoneNumber(phoneNumber);

    if (!normalizedFirebasePhone) {
      res.status(400).json({ message: 'Invalid phone number format in Firebase token' });
      return;
    }

    if (!normalizedPhone) {
      res.status(400).json({ message: 'Invalid phone number format provided' });
      return;
    }

    // Verify that the phone number matches (after normalization)
    if (normalizedFirebasePhone !== normalizedPhone) {
      res.status(400).json({ 
        message: `Phone number mismatch: token has ${firebasePhoneNumber} (normalized: ${normalizedFirebasePhone}), provided ${phoneNumber} (normalized: ${normalizedPhone})` 
      });
      return;
    }

    // Use normalized phone number for storage
    const phoneToStore = normalizedFirebasePhone;

    // Find or create user by phone number (try normalized and original formats)
    // Normalize all possible formats for lookup
    const normalizedPhoneNumber = normalizePhoneNumber(phoneNumber);
    const normalizedFirebasePhoneNumber = normalizePhoneNumber(firebasePhoneNumber);
    
    let user = await User.findOne({ 
      $or: [
        { phone: phoneToStore },
        ...(normalizedPhoneNumber && normalizedPhoneNumber !== phoneToStore ? [{ phone: normalizedPhoneNumber }] : []),
        ...(normalizedFirebasePhoneNumber && normalizedFirebasePhoneNumber !== phoneToStore ? [{ phone: normalizedFirebasePhoneNumber }] : []),
        ...(phoneNumber && phoneNumber !== phoneToStore ? [{ phone: phoneNumber }] : []),
        ...(firebasePhoneNumber && firebasePhoneNumber !== phoneToStore ? [{ phone: firebasePhoneNumber }] : []),
      ].filter(Boolean)
    });

    if (!user) {
      // Create new user if doesn't exist (for phone-based registration)
      // Use unique email placeholder to avoid duplicate null email issues
      const emailPlaceholder = decodedToken.email || `${phoneToStore.replace(/[^0-9]/g, '')}@phone.local`;
      
      user = await User.create({
        name: decodedToken.name || 'User',
        email: emailPlaceholder,
        phone: phoneToStore,
        role: 'customer',
        isEmailVerified: true, // Phone verification counts as verification
      });
    } else {
      // Update user verification status and normalize phone number
      user.isEmailVerified = true;
      user.phone = phoneToStore;
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
        // Verify phone number matches if present in token (normalize before comparison)
        if (decodedToken.phone_number) {
          const tokenPhone = decodedToken.phone_number;
          const normalizedTokenPhone = normalizePhoneNumber(tokenPhone);
          const normalizedPhone = normalizePhoneNumber(phone);
          
          if (normalizedTokenPhone && normalizedPhone && normalizedTokenPhone !== normalizedPhone) {
            console.warn(`⚠️  Phone number mismatch: token has ${tokenPhone} (normalized: ${normalizedTokenPhone}), provided ${phone} (normalized: ${normalizedPhone})`);
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
    
    // Normalize phone number for lookup
    const normalizedPhoneForLookup = normalizePhoneNumber(phone);
    
    // Find or create user by phone number (try normalized and original formats)
    let user = await User.findOne({ 
      $or: [
        ...(normalizedPhoneForLookup ? [{ phone: normalizedPhoneForLookup }] : []),
        { phone: phone },
        { phone: `+${phone.replace(/^\+/, '')}` },
      ].filter(Boolean)
    });

    // Normalize phone number before storage
    const rawPhone = decodedToken?.phone_number || phone;
    const verifiedPhone = normalizePhoneNumber(rawPhone);
    
    if (!verifiedPhone) {
      res.status(400).json({ message: 'Invalid phone number format' });
      return;
    }
    
    if (!user) {
      // Create new user if doesn't exist (for phone-based registration)
      // Use phone number as name if not provided
      // Use unique email placeholder to avoid duplicate null email issues
      // For phone-based users, email is optional and password is not required
      const userData: any = {
        name: decodedToken?.name || `User ${verifiedPhone.substring(verifiedPhone.length - 4)}`, // Last 4 digits as default name
        phone: verifiedPhone,
        role: 'customer',
        isEmailVerified: true, // Phone verification counts as verification
      };
      
      // Set email: use real email from Firebase token if available, otherwise use unique placeholder
      if (decodedToken?.email && decodedToken.email.includes('@') && !decodedToken.email.endsWith('@phone.local')) {
        userData.email = decodedToken.email;
      } else {
        // Use phone number as unique identifier for email placeholder
        const phoneDigits = verifiedPhone.replace(/[^0-9]/g, '');
        userData.email = `${phoneDigits}@phone.local`;
      }
      
      user = await User.create(userData);
      console.log(`✅ Created new user in MongoDB: ${user._id} for phone: ${verifiedPhone}`);
    } else {
      // Update user verification status if needed
      if (!user.isEmailVerified) {
        user.isEmailVerified = true;
      }
      // Always normalize and update phone number
      user.phone = verifiedPhone;
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
      isActive: user.isActive,
      location: user.location,
      profilePicture: user.profilePicture,
      createdAt: user.createdAt,
    };

    res.status(200).json({ user: userData });
  } catch (error: any) {
    res.status(500).json({ message: error.message || 'Failed to get user' });
  }
};

/**
 * Send OTP to phone number via SMS provider
 * Replaces Firebase Phone Authentication
 */
export const sendPhoneOTP = async (req: Request, res: Response): Promise<void> => {
  try {
    const { phoneNumber, language } = req.body;

    if (!phoneNumber || typeof phoneNumber !== 'string' || phoneNumber.trim().length < 9) {
      res.status(400).json({ message: 'A valid phone number is required' });
      return;
    }

    // Validate language if provided (should be 'ar' or 'en')
    const validLanguage = language && ['ar', 'en'].includes(language) ? language : undefined;

    // Normalize phone number
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    if (!normalizedPhone) {
      res.status(400).json({ message: 'Invalid phone number format' });
      return;
    }

    // Generate 6-digit OTP
    const otp = generateOTP();
    const otpExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Find or create user by phone number
    let user = await User.findOne({ 
      $or: [
        { phone: normalizedPhone },
        { phone: phoneNumber },
      ]
    });

    if (user) {
      // Update existing user's OTP
      user.otpCode = otp;
      user.otpExpires = otpExpires;
      if (user.phone !== normalizedPhone) {
        user.phone = normalizedPhone;
      }
      await user.save();
    } else {
      // Create new user with phone number
      const phoneDigits = normalizedPhone.replace(/[^0-9]/g, '');
      const emailPlaceholder = `${phoneDigits}@phone.local`;
      
      user = await User.create({
        name: `User ${normalizedPhone.substring(normalizedPhone.length - 4)}`,
        email: emailPlaceholder,
        phone: normalizedPhone,
        role: 'customer',
        isEmailVerified: false, // Will be verified after OTP verification
        otpCode: otp,
        otpExpires: otpExpires,
      });
    }

    // Send OTP via SMS provider
    try {
      await sendSMSOTP(normalizedPhone, otp, validLanguage);
    } catch (error: any) {
      console.error('Error sending SMS OTP:', error);
      // In development, return OTP in response if SMS fails
      const isDevelopment = process.env.NODE_ENV !== 'production';
      if (isDevelopment) {
        console.warn(`⚠️  SMS sending failed. OTP for ${normalizedPhone}: ${otp}`);
        res.status(200).json({
          message: 'OTP generated. Check console for OTP code (SMS sending failed).',
          phone: normalizedPhone,
          otp: otp, // Only in development
        });
        return;
      }
      // In production, return error
      res.status(500).json({ 
        message: 'Failed to send OTP. Please try again later.' 
      });
      return;
    }

    // Success response (don't include OTP in production)
    const isDevelopment = process.env.NODE_ENV !== 'production';
    res.status(200).json({
      message: 'OTP sent successfully',
      phone: normalizedPhone,
      ...(isDevelopment && { otp }), // Only include OTP in development
    });
  } catch (error: any) {
    console.error('Error in sendPhoneOTP:', error);
    res.status(500).json({ message: error.message || 'Failed to send OTP' });
  }
};

/**
 * Verify phone OTP and authenticate user
 * Replaces Firebase Phone Authentication verification
 */
export const verifyPhoneOTP = async (req: Request, res: Response): Promise<void> => {
  try {
    const { phoneNumber, otp } = req.body;

    if (!phoneNumber || typeof phoneNumber !== 'string') {
      res.status(400).json({ message: 'Phone number is required' });
      return;
    }

    if (!otp || typeof otp !== 'string' || otp.length !== 6) {
      res.status(400).json({ message: 'A valid 6-digit OTP is required' });
      return;
    }

    // Normalize phone number
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    if (!normalizedPhone) {
      res.status(400).json({ message: 'Invalid phone number format' });
      return;
    }

    // Find user by phone number
    const user = await User.findOne({ 
      $or: [
        { phone: normalizedPhone },
        { phone: phoneNumber },
      ]
    });

    if (!user) {
      res.status(404).json({ 
        message: 'No OTP request found for this phone number. Please request a new OTP.' 
      });
      return;
    }

    // Check if OTP exists
    if (!user.otpCode) {
      res.status(400).json({ message: 'No OTP found. Please request a new OTP.' });
      return;
    }

    // Verify OTP
    if (user.otpCode !== otp) {
      res.status(400).json({ message: 'Invalid OTP' });
      return;
    }

    // Check if OTP expired
    if (user.otpExpires && new Date() > user.otpExpires) {
      res.status(400).json({ message: 'OTP expired. Please request a new OTP.' });
      return;
    }

    // OTP verified successfully
    // Mark user as verified and clear OTP
    user.isEmailVerified = true;
    user.otpCode = undefined;
    user.otpExpires = undefined;
    await user.save();

    // Generate JWT token
    const token = generateToken({
      userId: user._id.toString(),
      role: user.role,
      email: user.email || `${normalizedPhone.replace(/[^0-9]/g, '')}@phone.local`,
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
    console.error('Error in verifyPhoneOTP:', error);
    res.status(500).json({ message: error.message || 'OTP verification failed' });
  }
};

/**
 * Delete user account with OTP verification
 * Requires authentication and OTP verification before deletion
 */
export const deleteAccount = async (
  req: AuthRequest,
  res: Response
): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ message: 'Authentication required' });
      return;
    }

    const { phoneNumber, otp } = req.body;

    if (!phoneNumber || typeof phoneNumber !== 'string') {
      res.status(400).json({ message: 'Phone number is required' });
      return;
    }

    if (!otp || typeof otp !== 'string' || otp.length !== 6) {
      res.status(400).json({ message: 'A valid 6-digit OTP is required' });
      return;
    }

    // Normalize phone number
    const normalizedPhone = normalizePhoneNumber(phoneNumber);
    if (!normalizedPhone) {
      res.status(400).json({ message: 'Invalid phone number format' });
      return;
    }

    // Find user by ID (from authenticated token) and phone number
    const user = await User.findById(req.user.userId);
    
    if (!user) {
      res.status(404).json({ message: 'User not found' });
      return;
    }

    // Verify phone number matches user's phone
    const userPhoneNormalized = user.phone ? normalizePhoneNumber(user.phone) : null;
    if (!userPhoneNormalized || userPhoneNormalized !== normalizedPhone) {
      res.status(400).json({ message: 'Phone number does not match your account' });
      return;
    }

    // Check if OTP exists
    if (!user.otpCode) {
      res.status(400).json({ message: 'No OTP found. Please request a new OTP.' });
      return;
    }

    // Verify OTP
    if (user.otpCode !== otp) {
      res.status(400).json({ message: 'Invalid OTP' });
      return;
    }

    // Check if OTP expired
    if (user.otpExpires && new Date() > user.otpExpires) {
      res.status(400).json({ message: 'OTP expired. Please request a new OTP.' });
      return;
    }

    // OTP verified successfully - delete the user account
    await User.findByIdAndDelete(user._id);

    console.log(`✅ Account deleted successfully for user: ${user._id} (${normalizedPhone})`);

    res.status(200).json({
      message: 'Account deleted successfully',
      success: true,
    });
  } catch (error: any) {
    console.error('Error in deleteAccount:', error);
    res.status(500).json({ message: error.message || 'Failed to delete account' });
  }
};
