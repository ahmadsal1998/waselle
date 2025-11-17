import type { LocationPoint } from './common';
import type { BaseUser, Driver } from './user';

export type OrderStatus = 'pending' | 'accepted' | 'on_the_way' | 'delivered' | 'cancelled';
export type OrderType = 'send' | 'receive';

export interface Order {
  _id: string;
  customerId: Pick<BaseUser, '_id' | 'name' | 'email'> | null;
  driverId?: Pick<Driver, '_id' | 'name' | 'email'> | null;
  type: OrderType;
  vehicleType?: 'car' | 'bike';
  orderCategory?: string;
  senderName?: string;
  senderAddress?: string;
  senderPhoneNumber?: number;
  deliveryNotes?: string;
  status: OrderStatus | string;
  price: number;
  estimatedPrice?: number;
  createdAt: string;
  distance?: number;
  pickupLocation?: LocationPoint | null;
  dropoffLocation?: LocationPoint | null;
}

export interface OrderDetail extends Omit<Order, 'customerId' | 'driverId' | 'price' | 'estimatedPrice'> {
  price?: number;
  estimatedPrice?: number;
  updatedAt: string;
  customerId?: (Pick<BaseUser, '_id' | 'name' | 'email'> & { phoneNumber?: string }) | null;
  driverId?: (Pick<Driver, '_id' | 'name' | 'email'> & { phoneNumber?: string }) | null;
}
