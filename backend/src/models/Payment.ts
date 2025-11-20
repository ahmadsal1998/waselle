import mongoose, { Document, Schema } from 'mongoose';

export interface IPayment extends Document {
  driverId: mongoose.Types.ObjectId;
  amount: number;
  date: Date;
  notes?: string;
  createdAt: Date;
  updatedAt: Date;
}

const PaymentSchema: Schema = new Schema(
  {
    driverId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'Driver ID is required'],
      index: true,
    },
    amount: {
      type: Number,
      required: [true, 'Payment amount is required'],
      min: 0,
    },
    date: {
      type: Date,
      required: [true, 'Payment date is required'],
      default: Date.now,
    },
    notes: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: true,
  }
);

// Index for efficient queries
PaymentSchema.index({ driverId: 1, createdAt: -1 });

export default mongoose.model<IPayment>('Payment', PaymentSchema);

