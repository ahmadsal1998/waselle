import mongoose, { Document, Schema } from 'mongoose';

export type IVillageSubdocument = mongoose.Types.Subdocument & {
  _id: mongoose.Types.ObjectId;
  name: string;
  nameEn?: string; // English name for reverse geocoding matching
  isActive: boolean;
};

export interface ICity extends Document {
  name: string;
  nameEn?: string; // English name for reverse geocoding matching
  isActive: boolean;
  villages: mongoose.Types.DocumentArray<IVillageSubdocument>;
  serviceCenter?: {
    center: {
      lat: number;
      lng: number;
    };
    internalOrderRadiusKm: number; // Fixed radius for internal orders (always 2km)
    externalOrderMinRadiusKm: number; // Minimum radius for external orders
    externalOrderMaxRadiusKm: number; // Maximum radius for external orders
  };
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
    nameEn: {
      type: String,
      trim: true,
      default: undefined, // Optional field
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
    nameEn: {
      type: String,
      trim: true,
      default: undefined, // Optional field
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    villages: {
      type: [VillageSubSchema],
      default: [],
    },
    serviceCenter: {
      center: {
        lat: {
          type: Number,
          min: -90,
          max: 90,
        },
        lng: {
          type: Number,
          min: -180,
          max: 180,
        },
      },
      internalOrderRadiusKm: {
        type: Number,
        min: 1,
        max: 100,
        default: 2,
      },
      externalOrderMinRadiusKm: {
        type: Number,
        min: 1,
        max: 100,
        default: 10,
      },
      externalOrderMaxRadiusKm: {
        type: Number,
        min: 1,
        max: 100,
        default: 15,
      },
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

