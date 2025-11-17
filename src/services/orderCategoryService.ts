import { apiClient } from './apiClient';
import type { OrderCategory } from '../types';

interface OrderCategoryPayload {
  name?: string;
  description?: string | null;
  isActive?: boolean;
}

export const getOrderCategories = async () => {
  const { data } = await apiClient.get<{ categories: OrderCategory[] }>('/order-categories');
  return data.categories ?? [];
};

export const createOrderCategory = async (payload: Required<Pick<OrderCategoryPayload, 'name'>> & {
  description?: string;
}) => {
  const { data } = await apiClient.post<{ category: OrderCategory }>('/order-categories', payload);
  return data.category;
};

export const updateOrderCategory = async (
  categoryId: string,
  payload: OrderCategoryPayload
) => {
  const { data } = await apiClient.patch<{ category: OrderCategory }>(
    `/order-categories/${categoryId}`,
    payload
  );
  return data.category;
};

export const deleteOrderCategory = async (categoryId: string) => {
  await apiClient.delete(`/order-categories/${categoryId}`);
};


