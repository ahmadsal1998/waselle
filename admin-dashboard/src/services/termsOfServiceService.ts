import { apiClient } from './apiClient';

export interface TermsOfService {
  _id?: string;
  content: string;
  contentAr?: string;
  lastUpdated?: string;
  updatedBy?: string;
  createdAt?: string;
  updatedAt?: string;
}

// Public endpoint - get terms of service (no auth required)
export const getTermsOfService = async (): Promise<TermsOfService> => {
  const { data } = await apiClient.get<{ termsOfService: TermsOfService }>('/terms-of-service');
  return data.termsOfService;
};

// Admin endpoint - update terms of service (requires auth)
export const updateTermsOfService = async (
  termsOfService: { content: string; contentAr?: string }
): Promise<TermsOfService> => {
  const { data } = await apiClient.put<{ termsOfService: TermsOfService }>(
    '/terms-of-service',
    termsOfService
  );
  return data.termsOfService;
};

