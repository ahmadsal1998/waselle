import mongoose, { Document, Schema, Model } from 'mongoose';

export interface VehicleTypeConfig {
  enabled: boolean;
  basePrice: number; // Starting price in ILS
}

export interface ISettings extends Document {
  orderNotificationRadiusKm: number; // Distance in kilometers for order notifications (deprecated, kept for backward compatibility)
  internalOrderRadiusKm: number; // Distance in kilometers for internal orders (within service area)
  externalOrderRadiusKm: number; // Distance in kilometers for external orders (outside service area)
  serviceAreaCenter: {
    lat: number;
    lng: number;
  }; // Center point of the service area
  serviceAreaRadiusKm: number; // Radius in kilometers that defines the service area boundary
  mapDefaultCenter: {
    lat: number;
    lng: number;
  }; // Default center point for the map view
  mapDefaultZoom: number; // Default zoom level for the map view
  vehicleTypes: {
    bike: VehicleTypeConfig;
    car: VehicleTypeConfig;
    cargo: VehicleTypeConfig;
  };
  createdAt: Date;
  updatedAt: Date;
}

interface ISettingsModel extends Model<ISettings> {
  getSettings(): Promise<ISettings>;
}

const SettingsSchema: Schema = new Schema(
  {
    orderNotificationRadiusKm: {
      type: Number,
      default: 10, // Default 10 kilometers (deprecated, kept for backward compatibility)
      min: 1,
      max: 100,
    },
    internalOrderRadiusKm: {
      type: Number,
      required: true,
      default: 5, // Default 5 kilometers for internal orders
      min: 1,
      max: 100,
    },
    externalOrderRadiusKm: {
      type: Number,
      required: true,
      default: 10, // Default 10 kilometers for external orders
      min: 1,
      max: 100,
    },
    serviceAreaCenter: {
      lat: {
        type: Number,
        required: true,
        default: 0, // Default to 0,0 (should be configured by admin)
      },
      lng: {
        type: Number,
        required: true,
        default: 0,
      },
    },
    serviceAreaRadiusKm: {
      type: Number,
      required: true,
      default: 20, // Default 20 kilometers service area radius
      min: 1,
      max: 500,
    },
    mapDefaultCenter: {
      lat: {
        type: Number,
        required: true,
        default: 32.462502185826004, // Default coordinates for Palestine
      },
      lng: {
        type: Number,
        required: true,
        default: 35.29172911766705,
      },
    },
    mapDefaultZoom: {
      type: Number,
      required: true,
      default: 12, // Default zoom level
      min: 1,
      max: 18,
    },
    vehicleTypes: {
      bike: {
        enabled: {
          type: Boolean,
          default: true,
        },
        basePrice: {
          type: Number,
          default: 5, // Starting price 5 ILS
          min: 0,
        },
      },
      car: {
        enabled: {
          type: Boolean,
          default: true,
        },
        basePrice: {
          type: Number,
          default: 10, // Starting price 10 ILS
          min: 0,
        },
      },
      cargo: {
        enabled: {
          type: Boolean,
          default: false, // Inactive by default
        },
        basePrice: {
          type: Number,
          default: 15, // Default starting price (can be configured)
          min: 0,
        },
      },
    },
  },
  {
    timestamps: true,
  }
);

// Ensure only one settings document exists
SettingsSchema.statics.getSettings = async function (): Promise<ISettings> {
  let settings = await this.findOne();
  if (!settings) {
    settings = await this.create({
      orderNotificationRadiusKm: 10, // Backward compatibility
      internalOrderRadiusKm: 5,
      externalOrderRadiusKm: 10,
      serviceAreaCenter: { lat: 0, lng: 0 },
      serviceAreaRadiusKm: 20,
      mapDefaultCenter: { lat: 32.462502185826004, lng: 35.29172911766705 },
      mapDefaultZoom: 12,
      vehicleTypes: {
        bike: { enabled: true, basePrice: 5 },
        car: { enabled: true, basePrice: 10 },
        cargo: { enabled: false, basePrice: 15 },
      },
    });
  } else {
    // Migrate existing settings if needed
    if (settings.internalOrderRadiusKm === undefined) {
      settings.internalOrderRadiusKm = 5;
    }
    if (settings.externalOrderRadiusKm === undefined) {
      settings.externalOrderRadiusKm = settings.orderNotificationRadiusKm || 10;
    }
    if (!settings.serviceAreaCenter || !settings.serviceAreaCenter.lat) {
      settings.serviceAreaCenter = { lat: 0, lng: 0 };
    }
    if (settings.serviceAreaRadiusKm === undefined) {
      settings.serviceAreaRadiusKm = 20;
    }
    // Migrate map default center if needed
    if (!settings.mapDefaultCenter || settings.mapDefaultCenter.lat === undefined) {
      settings.mapDefaultCenter = { lat: 32.462502185826004, lng: 35.29172911766705 };
    }
    if (settings.mapDefaultZoom === undefined) {
      settings.mapDefaultZoom = 12;
    }
    // Migrate vehicle types if needed
    if (!settings.vehicleTypes) {
      settings.vehicleTypes = {
        bike: { enabled: true, basePrice: 5 },
        car: { enabled: true, basePrice: 10 },
        cargo: { enabled: false, basePrice: 15 },
      };
    } else {
      // Ensure all vehicle types exist with defaults
      if (!settings.vehicleTypes.bike) {
        settings.vehicleTypes.bike = { enabled: true, basePrice: 5 };
      }
      if (!settings.vehicleTypes.car) {
        settings.vehicleTypes.car = { enabled: true, basePrice: 10 };
      }
      if (!settings.vehicleTypes.cargo) {
        settings.vehicleTypes.cargo = { enabled: false, basePrice: 15 };
      }
    }
    await settings.save();
  }
  return settings;
};

const Settings = mongoose.model<ISettings, ISettingsModel>('Settings', SettingsSchema);

export default Settings;

