import { apiClient } from './apiClient';

export interface PrivacyPolicy {
  _id?: string;
  content: string;
  contentAr?: string;
  lastUpdated?: string;
  updatedBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

// Public endpoint - get privacy policy (no auth required)
export const getPrivacyPolicy = async (): Promise<PrivacyPolicy> => {
  const { data } = await apiClient.get<{ privacyPolicy: PrivacyPolicy }>('/privacy-policy');
  return data.privacyPolicy;
};

// Admin endpoint - update privacy policy (requires auth)
export const updatePrivacyPolicy = async (
  privacyPolicy: { content: string; contentAr?: string }
): Promise<PrivacyPolicy> => {
  const { data } = await apiClient.put<{ privacyPolicy: PrivacyPolicy }>(
    '/privacy-policy',
    privacyPolicy
  );
  return data.privacyPolicy;
};

