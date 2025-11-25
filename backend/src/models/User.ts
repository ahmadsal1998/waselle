import mongoose, { Document, Schema } from 'mongoose';

export interface IUser extends Document {
  name: string;
  email?: string;
  password?: string;
  role: 'customer' | 'driver' | 'admin';
  vehicleType?: 'car' | 'bike' | 'cargo';
  location?: {
    lat: number;
    lng: number;
  };
  isAvailable: boolean;
  isActive?: boolean; // Account status (active/inactive)
  phone?: string;
  countryCode?: string;
  address?: string; // Kept for backward compatibility (formatted string)
  city?: string; // Separate city component
  village?: string; // Separate village component
  streetDetails?: string; // Separate street/details component
  isEmailVerified: boolean;
  otpCode?: string;
  otpExpires?: Date;
  profilePicture?: string;
  fcmToken?: string; // Firebase Cloud Messaging token for push notifications
  createdAt: Date;
  updatedAt: Date;
}

const UserSchema: Schema = new Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [
        function (this: IUser) {
          return this.role !== 'customer' || !this.phone;
        },
        'Email is required for drivers and admins, or if phone is not provided',
      ],
      unique: true,
      sparse: true, // Allow multiple null values
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: [
        function (this: IUser) {
          // Password is required for:
          // 1. Non-customer roles (drivers, admins)
          // 2. Customer accounts with real email (not phone-based placeholder)
          if (this.role !== 'customer') return true;
          if (!this.email) return false;
          // Don't require password for phone-based accounts (email placeholder)
          return !this.email.endsWith('@phone.local');
        },
        'Password is required for email-based accounts',
      ],
      minlength: 6,
    },
    role: {
      type: String,
      enum: ['customer', 'driver', 'admin'],
      default: 'customer',
    },
    vehicleType: {
      type: String,
      enum: ['car', 'bike', 'cargo'],
      required: [
        function (this: IUser) {
          return this.role === 'driver';
        },
        'Vehicle type is required for drivers',
      ],
    },
    location: {
      lat: { type: Number },
      lng: { type: Number },
    },
    isAvailable: {
      type: Boolean,
      default: false,
    },
    isActive: {
      type: Boolean,
      default: true, // Drivers are active by default
    },
    phone: {
      type: String,
      unique: true,
      sparse: true, // Allow multiple null values
      trim: true,
    },
    countryCode: {
      type: String,
      trim: true,
    },
    address: {
      type: String,
      trim: true,
      // Optional - can be generated from components if not provided
    },
    city: {
      type: String,
      trim: true,
    },
    village: {
      type: String,
      trim: true,
    },
    streetDetails: {
      type: String,
      trim: true,
    },
    isEmailVerified: {
      type: Boolean,
      default: function(this: IUser) {
        // Customers are verified by default (especially phone-based customers)
        // Email-based customers will need to verify via OTP
        return this.role === 'customer';
      },
    },
    otpCode: {
      type: String,
    },
    otpExpires: {
      type: Date,
    },
    profilePicture: {
      type: String,
      trim: true,
    },
    fcmToken: {
      type: String,
      trim: true,
      sparse: true, // Allow multiple null values
    },
  },
  {
    timestamps: true,
  }
);

// Custom validation: at least email or phone must be provided
UserSchema.pre('validate', function (next) {
  if (!this.email && !this.phone) {
    this.invalidate('email', 'Either email or phone must be provided');
    this.invalidate('phone', 'Either email or phone must be provided');
  }
  next();
});

export default mongoose.model<IUser>('User', UserSchema);
