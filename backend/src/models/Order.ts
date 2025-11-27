import mongoose, { Document, Schema } from 'mongoose';

export interface IOrder extends Document {
  customerId: mongoose.Types.ObjectId;
  driverId?: mongoose.Types.ObjectId;
  type: 'send' | 'receive';
  deliveryType: 'internal' | 'external';
  vehicleType: 'car' | 'bike' | 'cargo';
  orderCategory: string;
  senderName: string;
  senderAddress: string; // Kept for backward compatibility (formatted string)
  senderCity?: string; // Separate city component
  senderVillage?: string; // Separate village component
  senderStreetDetails?: string; // Separate street/details component
  senderPhoneNumber: number; // Kept for backward compatibility
  phone?: string; // Local phone number without country code (e.g., "593202026")
  countryCode?: string; // Country code (e.g., "+972")
  deliveryNotes?: string;
  pickupLocation: {
    lat: number;
    lng: number;
    address?: string;
  };
  dropoffLocation: {
    lat: number;
    lng: number;
    address?: string;
  };
  price: number;
  estimatedPrice: number;
  finalPrice?: number; // Final price set by driver
  priceStatus: 'pending' | 'proposed' | 'accepted' | 'rejected'; // Price confirmation status
  priceProposedAt?: Date; // When the driver proposed the final price
  priceRespondedAt?: Date; // When the user accepted/rejected the price
  status: 'pending' | 'accepted' | 'on_the_way' | 'delivered' | 'cancelled' | 'new_price_pending';
  estimatedTime?: number;
  distance?: number;
  createdAt: Date;
  updatedAt: Date;
}

const OrderSchema: Schema = new Schema(
  {
    customerId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Customer ID is required'],
    },
    driverId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
    },
    type: {
      type: String,
      enum: ['send', 'receive'],
      required: [true, 'Order type is required'],
    },
    deliveryType: {
      type: String,
      enum: ['internal', 'external'],
      required: [true, 'Delivery type is required'],
    },
    vehicleType: {
      type: String,
      enum: ['car', 'bike', 'cargo'],
      required: [true, 'Vehicle type is required'],
    },
    orderCategory: {
      type: String,
      required: [true, 'Order category is required'],
      trim: true,
    },
    senderName: {
      type: String,
      required: [true, 'Sender name is required'],
      trim: true,
    },
    senderAddress: {
      type: String,
      trim: true,
      // Optional - can be generated from components if not provided
    },
    senderCity: {
      type: String,
      trim: true,
    },
    senderVillage: {
      type: String,
      trim: true,
    },
    senderStreetDetails: {
      type: String,
      trim: true,
    },
    senderPhoneNumber: {
      type: Number,
      required: [true, 'Sender phone number is required'],
      min: 0,
    },
    phone: {
      type: String,
      trim: true,
      // Local phone number without country code (e.g., "593202026")
    },
    countryCode: {
      type: String,
      trim: true,
      // Country code (e.g., "+972")
    },
    deliveryNotes: {
      type: String,
      trim: true,
    },
    pickupLocation: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true },
      address: { type: String },
    },
    dropoffLocation: {
      lat: { type: Number, required: true },
      lng: { type: Number, required: true },
      address: { type: String },
    },
    price: {
      type: Number,
      required: [true, 'Price is required'],
      min: 0,
    },
    estimatedPrice: {
      type: Number,
      required: [true, 'Estimated price is required'],
      min: 0,
    },
    finalPrice: {
      type: Number,
      min: 0,
      // Final price set by driver, null until driver proposes it
    },
    priceStatus: {
      type: String,
      enum: ['pending', 'proposed', 'accepted', 'rejected'],
      default: 'pending',
      // pending: waiting for driver to propose price
      // proposed: driver has proposed a price, waiting for user response
      // accepted: user accepted the proposed price
      // rejected: user rejected the proposed price
    },
    priceProposedAt: {
      type: Date,
      // Timestamp when driver proposed the final price
    },
    priceRespondedAt: {
      type: Date,
      // Timestamp when user accepted/rejected the price
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'on_the_way', 'delivered', 'cancelled', 'new_price_pending'],
      default: 'pending',
    },
    estimatedTime: {
      type: Number, // in minutes
    },
    distance: {
      type: Number, // in kilometers
    },
  },
  {
    timestamps: true,
  }
);

// Indexes for better query performance
OrderSchema.index({ driverId: 1, status: 1 }); // For balance calculations
OrderSchema.index({ customerId: 1, createdAt: -1 }); // For customer order history
OrderSchema.index({ status: 1, createdAt: -1 }); // For order listings

export default mongoose.model<IOrder>('Order', OrderSchema);
