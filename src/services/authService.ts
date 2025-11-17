import { apiClient } from './apiClient';
import type { AuthResponse, AuthUser } from '../types';

export const login = async (email: string, password: string) => {
  const { data } = await apiClient.post<AuthResponse>('/auth/login', { email, password });
  return data;
};

export const getCurrentUser = async () => {
  const { data } = await apiClient.get<{ user: AuthUser }>('/auth/me');
  return data.user;
};

/**
 * Verify phone number using Firebase Phone Auth
 * Client sends Firebase ID token after verifying OTP with Firebase
 * Backend verifies token, creates/updates user, and returns JWT for session
 */
export const verifyPhoneAndLogin = async (
  idToken: string,
  countryCode?: string
) => {
  const { data } = await apiClient.post<{
    message: string;
    token: string;
    user: {
      id: string;
      name: string;
      phone: string;
      countryCode?: string;
      role: string;
      isNewUser: boolean;
    };
  }>('/auth/verify-phone', {
    idToken,
    countryCode,
  });
  return data;
};

/**
 * Check if a phone number exists in the database (optional helper)
 */
export const checkPhoneNumber = async (phone: string, countryCode?: string) => {
  const { data } = await apiClient.post<{
    exists: boolean;
    phone: string;
    message: string;
  }>('/auth/check-phone', {
    phone,
    countryCode,
  });
  return data;
};


