import { apiClient } from './apiClient';

export interface VehicleTypeConfig {
  enabled: boolean;
  basePrice: number;
}

export interface Settings {
  _id?: string;
  internalOrderRadiusKm: number;
  externalOrderMinRadiusKm: number;
  externalOrderMaxRadiusKm: number;
  mapDefaultCenter?: {
    lat: number;
    lng: number;
  };
  mapDefaultZoom?: number;
  vehicleTypes?: {
    bike: VehicleTypeConfig;
    car: VehicleTypeConfig;
    cargo: VehicleTypeConfig;
  };
  commissionPercentage?: number;
  maxAllowedBalance?: number;
  otpMessageTemplate?: string;
  otpMessageTemplateAr?: string;
  otpMessageLanguage?: 'en' | 'ar';
  createdAt?: string;
  updatedAt?: string;
}

export const getSettings = async (): Promise<Settings> => {
  const { data } = await apiClient.get<{ settings: Settings }>('/settings');
  return data.settings;
};

export const updateSettings = async (
  settings: Partial<Settings>
): Promise<Settings> => {
  const { data } = await apiClient.put<{ settings: Settings }>(
    '/settings',
    settings
  );
  return data.settings;
};

