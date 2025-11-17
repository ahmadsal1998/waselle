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
  vehicleType?: 'car' | 'bike';
  location?: LocationPoint | null;
}

export interface Customer extends BaseUser {
  role: 'customer';
}

export interface Admin extends BaseUser {
  role: 'admin';
}

export type ApiUser = BaseUser & Partial<Driver>;
