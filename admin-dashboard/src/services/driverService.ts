import { apiClient } from './apiClient';
import type { Driver } from '@/types';

export interface CreateDriverData {
  name: string;
  email: string;
  phone: string;
  password: string;
  vehicleType: 'car' | 'bike' | 'cargo';
  isActive?: boolean;
}

export interface UpdateDriverData {
  name?: string;
  email?: string;
  phone?: string;
  vehicleType?: 'car' | 'bike' | 'cargo';
  isActive?: boolean;
}

export interface DriverFilters {
  search?: string;
  status?: 'active' | 'inactive' | 'all';
}

export const getDrivers = async (filters?: DriverFilters): Promise<Driver[]> => {
  const params = new URLSearchParams();
  if (filters?.search) {
    params.append('search', filters.search);
  }
  if (filters?.status && filters.status !== 'all') {
    params.append('status', filters.status);
  }

  const response = await apiClient.get<{ drivers: Driver[] }>(
    `/drivers${params.toString() ? `?${params.toString()}` : ''}`
  );
  return response.data.drivers;
};

export const getDriverById = async (driverId: string): Promise<Driver> => {
  const response = await apiClient.get<{ driver: Driver }>(`/drivers/${driverId}`);
  return response.data.driver;
};

export const createDriver = async (data: CreateDriverData): Promise<Driver> => {
  const response = await apiClient.post<{ driver: Driver }>('/drivers', data);
  return response.data.driver;
};

export const updateDriver = async (
  driverId: string,
  data: UpdateDriverData
): Promise<Driver> => {
  const response = await apiClient.patch<{ driver: Driver }>(`/drivers/${driverId}`, data);
  return response.data.driver;
};

export const resetDriverPassword = async (
  driverId: string,
  newPassword: string
): Promise<void> => {
  await apiClient.patch(`/drivers/${driverId}/password`, { newPassword });
};

export const toggleDriverStatus = async (driverId: string): Promise<Driver> => {
  const response = await apiClient.patch<{ driver: Driver }>(`/drivers/${driverId}/toggle-status`);
  return response.data.driver;
};

export const deleteDriver = async (driverId: string): Promise<void> => {
  await apiClient.delete(`/drivers/${driverId}`);
};

