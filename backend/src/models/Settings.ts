import mongoose, { Document, Schema, Model } from 'mongoose';

export interface VehicleTypeConfig {
  enabled: boolean;
  basePrice: number; // Starting price in ILS
}

export interface ISettings extends Document {
  internalOrderRadiusKm: number; // Fixed distance in kilometers for internal orders (always 2km)
  externalOrderMinRadiusKm: number; // Minimum distance in kilometers for external orders
  externalOrderMaxRadiusKm: number; // Maximum distance in kilometers for external orders
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
  commissionPercentage: number; // Commission percentage (e.g., 2 for 2%)
  maxAllowedBalance: number; // Maximum allowed balance in NIS before suspension
  otpMessageTemplate?: string; // Custom OTP SMS message template (supports ${otp} placeholder) - Default/English
  otpMessageTemplateAr?: string; // Arabic OTP SMS message template (supports ${otp} placeholder)
  otpMessageLanguage?: 'en' | 'ar'; // Default language for OTP messages ('en' or 'ar')
  createdAt: Date;
  updatedAt: Date;
}

interface ISettingsModel extends Model<ISettings> {
  getSettings(): Promise<ISettings>;
}

const SettingsSchema: Schema = new Schema(
  {
    internalOrderRadiusKm: {
      type: Number,
      required: true,
      default: 2, // Fixed 2 kilometers for internal orders
      min: 1,
      max: 100,
    },
    externalOrderMinRadiusKm: {
      type: Number,
      required: true,
      default: 10, // Default minimum 10 kilometers for external orders
      min: 1,
      max: 100,
    },
    externalOrderMaxRadiusKm: {
      type: Number,
      required: true,
      default: 15, // Default maximum 15 kilometers for external orders
      min: 1,
      max: 100,
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
    commissionPercentage: {
      type: Number,
      required: true,
      default: 2, // Default 2%
      min: 0,
      max: 100,
    },
    maxAllowedBalance: {
      type: Number,
      required: true,
      default: 50, // Default 50 NIS
      min: 0,
    },
    otpMessageTemplate: {
      type: String,
      required: false,
      trim: true,
      maxlength: 500, // SMS messages are typically limited to 160 characters, but allow longer for template
      // Default will be handled in getSettings() method
    },
    otpMessageTemplateAr: {
      type: String,
      required: false,
      trim: true,
      maxlength: 500, // SMS messages are typically limited to 160 characters, but allow longer for template
      // Arabic template - optional, falls back to otpMessageTemplate if not set
    },
    otpMessageLanguage: {
      type: String,
      required: false,
      enum: ['en', 'ar'],
      default: 'en', // Default to English
      // Language preference for OTP messages
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
      internalOrderRadiusKm: 2,
      externalOrderMinRadiusKm: 10,
      externalOrderMaxRadiusKm: 15,
      mapDefaultCenter: { lat: 32.462502185826004, lng: 35.29172911766705 },
      mapDefaultZoom: 12,
      vehicleTypes: {
        bike: { enabled: true, basePrice: 5 },
        car: { enabled: true, basePrice: 10 },
        cargo: { enabled: false, basePrice: 15 },
      },
      commissionPercentage: 2,
      maxAllowedBalance: 50,
      otpMessageTemplate: 'Your OTP code is: ${otp}. This code will expire in 10 minutes.',
      otpMessageTemplateAr: 'رمز التحقق الخاص بك هو: ${otp}. هذا الرمز صالح لمدة 10 دقائق فقط.',
      otpMessageLanguage: 'en',
    });
    return settings;
  } else {
    // Migrate existing settings if needed
    if (settings.internalOrderRadiusKm === undefined) {
      settings.internalOrderRadiusKm = 2;
    }
    // Migrate externalOrderRadiusKm to min/max if needed
    if (settings.externalOrderMinRadiusKm === undefined || settings.externalOrderMaxRadiusKm === undefined) {
      const oldExternalRadius = (settings as any).externalOrderRadiusKm || 10;
      settings.externalOrderMinRadiusKm = oldExternalRadius;
      settings.externalOrderMaxRadiusKm = oldExternalRadius + 5; // Default range: old value to old value + 5km
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
    // Migrate commission settings if needed
    if (settings.commissionPercentage === undefined) {
      settings.commissionPercentage = 2;
    }
    if (settings.maxAllowedBalance === undefined) {
      settings.maxAllowedBalance = 50;
    }
    // Set default OTP message template if not set
    if (!settings.otpMessageTemplate) {
      settings.otpMessageTemplate = 'Your OTP code is: ${otp}. This code will expire in 10 minutes.';
    }
    // Set default Arabic OTP message template if not set
    if (!settings.otpMessageTemplateAr) {
      settings.otpMessageTemplateAr = 'رمز التحقق الخاص بك هو: ${otp}. هذا الرمز صالح لمدة 10 دقائق فقط.';
    }
    // Set default OTP message language if not set
    if (!settings.otpMessageLanguage) {
      settings.otpMessageLanguage = 'en';
    }
    await settings.save();
  }
  return settings;
};

const Settings = mongoose.model<ISettings, ISettingsModel>('Settings', SettingsSchema);

export default Settings;

