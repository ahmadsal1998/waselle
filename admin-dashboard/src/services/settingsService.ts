import { apiClient } from './apiClient';

export interface VehicleTypeConfig {
  enabled: boolean;
  basePrice: number;
}

export interface Settings {
  _id?: string;
  orderNotificationRadiusKm?: number; // Deprecated, kept for backward compatibility
  internalOrderRadiusKm: number;
  externalOrderRadiusKm: number;
  serviceAreaCenter: {
    lat: number;
    lng: number;
  };
  serviceAreaRadiusKm: number;
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

