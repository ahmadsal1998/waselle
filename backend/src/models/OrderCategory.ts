import mongoose, { Document, Schema } from 'mongoose';

export interface IOrderCategory extends Document {
  name: string;
  description?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const OrderCategorySchema: Schema<IOrderCategory> = new Schema(
  {
    name: {
      type: String,
      required: [true, 'Order category name is required'],
      trim: true,
      unique: true,
    },
    description: {
      type: String,
      trim: true,
      default: '',
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

OrderCategorySchema.index(
  { name: 1 },
  {
    unique: true,
    collation: {
      locale: 'en',
      strength: 2,
    },
  }
);

export default mongoose.model<IOrderCategory>('OrderCategory', OrderCategorySchema);


