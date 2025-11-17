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
  serviceCenter?: {
    center: {
      lat: number;
      lng: number;
    };
    serviceAreaRadiusKm: number; // Coverage radius for the city
    internalOrderRadiusKm: number; // For orders inside the city
    externalOrderRadiusKm: number; // For orders outside but near the city
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
      serviceAreaRadiusKm: {
        type: Number,
        min: 1,
        max: 500,
        default: 20,
      },
      internalOrderRadiusKm: {
        type: Number,
        min: 1,
        max: 100,
        default: 5,
      },
      externalOrderRadiusKm: {
        type: Number,
        min: 1,
        max: 100,
        default: 10,
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

