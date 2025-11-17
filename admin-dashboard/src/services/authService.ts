import { apiClient } from './apiClient';
import type { AuthResponse, AuthUser } from '@/types';

export const login = async (email: string, password: string) => {
  const { data } = await apiClient.post<AuthResponse>('/auth/login', { email, password });
  return data;
};

export const getCurrentUser = async () => {
  const { data } = await apiClient.get<{ user: AuthUser }>('/auth/me');
  return data.user;
};
