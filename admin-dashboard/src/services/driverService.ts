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
  page?: number;
  limit?: number;
  includeBalance?: boolean;
}

export interface DriversResponse {
  drivers: Driver[];
  pagination?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export const getDrivers = async (filters?: DriverFilters): Promise<DriversResponse> => {
  const params = new URLSearchParams();
  if (filters?.search) {
    params.append('search', filters.search);
  }
  if (filters?.status && filters.status !== 'all') {
    params.append('status', filters.status);
  }
  if (filters?.page) {
    params.append('page', filters.page.toString());
  }
  if (filters?.limit) {
    params.append('limit', filters.limit.toString());
  }
  if (filters?.includeBalance) {
    params.append('includeBalance', 'true');
  }

  const response = await apiClient.get<DriversResponse>(
    `/drivers${params.toString() ? `?${params.toString()}` : ''}`
  );
  return response.data;
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

// Payment related interfaces and functions
export interface Payment {
  _id: string;
  driverId: string;
  amount: number;
  date: string;
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface CreatePaymentData {
  amount: number;
  date?: string;
  notes?: string;
}

export interface DriverBalanceInfo {
  totalDeliveryRevenue: number;
  commissionPercentage: number;
  totalCommissionOwed: number;
  totalPaymentsMade: number;
  currentBalance: number;
  isSuspended: boolean;
}

export interface AddPaymentResponse {
  message: string;
  payment: Payment;
  balanceInfo: DriverBalanceInfo;
  driver?: Driver;
  suspensionStatus: {
    suspended: boolean;
    reactivated: boolean;
    balance: number;
    maxAllowed: number;
  };
}

export const addDriverPayment = async (
  driverId: string,
  data: CreatePaymentData
): Promise<AddPaymentResponse> => {
  const response = await apiClient.post<AddPaymentResponse>(
    `/payments/drivers/${driverId}`,
    data
  );
  return response.data;
};

export interface PaymentsResponse {
  payments: Payment[];
  pagination?: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
  };
}

export const getDriverPayments = async (
  driverId: string,
  page?: number,
  limit?: number
): Promise<PaymentsResponse> => {
  const params = new URLSearchParams();
  if (page) {
    params.append('page', page.toString());
  }
  if (limit) {
    params.append('limit', limit.toString());
  }

  const response = await apiClient.get<PaymentsResponse>(
    `/payments/drivers/${driverId}${params.toString() ? `?${params.toString()}` : ''}`
  );
  return response.data;
};

export const getDriverBalance = async (driverId: string): Promise<DriverBalanceInfo> => {
  const response = await apiClient.get<{ balanceInfo: DriverBalanceInfo }>(
    `/payments/drivers/${driverId}/balance`
  );
  return response.data.balanceInfo;
};

