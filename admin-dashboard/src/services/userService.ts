import { apiClient } from './apiClient';
import type { ApiUser } from '@/types';

export const getUsers = async () => {
  const { data } = await apiClient.get<{ users: ApiUser[] }>('/users');
  return data.users ?? [];
};
