import { apiClient } from './apiClient';
import type { Order, OrderDetail } from '../types';

export const getOrders = async () => {
  const { data } = await apiClient.get<{ orders: Order[] }>('/orders');
  return data.orders ?? [];
};

export const getOrderById = async (orderId: string) => {
  const { data } = await apiClient.get<{ order: OrderDetail }>(`/orders/${orderId}`);
  return data.order;
};

/**
 * Create order using Firebase Phone Auth
 * @param idToken Firebase ID token from Firebase Phone Auth
 * @param orderData Order creation data
 */
export const createOrderWithFirebase = async (
  idToken: string,
  orderData: {
    type: string;
    deliveryType: string;
    pickupLocation: { lat: number; lng: number };
    dropoffLocation: { lat: number; lng: number };
    vehicleType: string;
    orderCategory: string;
    senderName: string;
    senderCity: string;
    senderVillage: string;
    senderStreetDetails: string;
    deliveryNotes?: string;
  }
) => {
  const { data } = await apiClient.post<{
    message: string;
    order: OrderDetail;
    token: string;
    user: any;
    firebaseUid: string;
  }>('/orders/create-with-firebase', {
    idToken,
    ...orderData,
  });
  return data;
};
