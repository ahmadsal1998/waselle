import type { LocationPoint } from './common';

export type UserRole = 'customer' | 'driver' | 'admin';

export interface BaseUser {
  _id: string;
  name: string;
  email: string;
  role: UserRole | string;
  isAvailable?: boolean;
  createdAt?: string;
  updatedAt?: string;
}

export interface Driver extends BaseUser {
  role: 'driver';
  isAvailable: boolean;
  isActive?: boolean;
  vehicleType?: 'car' | 'bike' | 'cargo';
  location?: LocationPoint | null;
  phone?: string;
}

export interface Customer extends BaseUser {
  role: 'customer';
}

export interface Admin extends BaseUser {
  role: 'admin';
}

export type ApiUser = BaseUser & Partial<Driver>;
