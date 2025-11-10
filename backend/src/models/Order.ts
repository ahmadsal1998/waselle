import mongoose, { Document, Schema } from 'mongoose';

export interface IOrder extends Document {
  customerId: mongoose.Types.ObjectId;
  driverId?: mongoose.Types.ObjectId;
  type: 'send' | 'receive';
  vehicleType: 'car' | 'bike';
  orderCategory: string;
  senderName: string;
  senderAddress: string;
  senderPhoneNumber: string;
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
  status: 'pending' | 'accepted' | 'on_the_way' | 'delivered' | 'cancelled';
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
    vehicleType: {
      type: String,
      enum: ['car', 'bike'],
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
      required: [true, 'Sender address is required'],
      trim: true,
    },
    senderPhoneNumber: {
      type: String,
      required: [true, 'Sender phone number is required'],
      trim: true,
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
    status: {
      type: String,
      enum: ['pending', 'accepted', 'on_the_way', 'delivered', 'cancelled'],
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

export default mongoose.model<IOrder>('Order', OrderSchema);
