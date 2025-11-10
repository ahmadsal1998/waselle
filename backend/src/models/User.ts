import mongoose, { Document, Schema } from 'mongoose';

export interface IUser extends Document {
  name: string;
  email: string;
  password: string;
  role: 'customer' | 'driver' | 'admin';
  vehicleType?: 'car' | 'bike';
  location?: {
    lat: number;
    lng: number;
  };
  isAvailable: boolean;
  phoneNumber?: string;
  isEmailVerified: boolean;
  otpCode?: string;
  otpExpires?: Date;
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
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: 6,
    },
    role: {
      type: String,
      enum: ['customer', 'driver', 'admin'],
      default: 'customer',
    },
    vehicleType: {
      type: String,
      enum: ['car', 'bike'],
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
    phoneNumber: {
      type: String,
      trim: true,
    },
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    otpCode: {
      type: String,
    },
    otpExpires: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

export default mongoose.model<IUser>('User', UserSchema);
