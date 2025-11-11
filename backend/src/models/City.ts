import mongoose, { Document, Schema } from 'mongoose';

export type IVillageSubdocument = mongoose.Types.Subdocument & {
  _id: mongoose.Types.ObjectId;
  name: string;
  isActive: boolean;
};

export interface ICity extends Document {
  name: string;
  isActive: boolean;
  villages: mongoose.Types.DocumentArray<IVillageSubdocument>;
  createdAt: Date;
  updatedAt: Date;
}

const VillageSubSchema = new Schema<IVillageSubdocument>(
  {
    name: {
      type: String,
      required: [true, 'Village name is required'],
      trim: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    _id: true,
    id: false,
  }
);

const CitySchema: Schema<ICity> = new Schema(
  {
    name: {
      type: String,
      required: [true, 'City name is required'],
      trim: true,
      unique: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    villages: {
      type: [VillageSubSchema],
      default: [],
    },
  },
  {
    timestamps: true,
  }
);

CitySchema.index(
  { name: 1 },
  {
    unique: true,
    collation: {
      locale: 'en',
      strength: 2,
    },
  }
);

export default mongoose.model<ICity>('City', CitySchema);

