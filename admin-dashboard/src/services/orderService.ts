import { apiClient } from './apiClient';
import type { Order, OrderDetail } from '@/types';

export const getOrders = async () => {
  const { data } = await apiClient.get<{ orders: Order[] }>('/orders');
  return data.orders ?? [];
};

export const getOrderById = async (orderId: string) => {
  const { data } = await apiClient.get<{ order: OrderDetail }>(`/orders/${orderId}`);
  return data.order;
};
