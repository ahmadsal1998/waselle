import type { LocationPoint } from '@/types';

export const formatCurrency = (value?: number | null, currency = 'NIS') => {
  if (value === undefined || value === null) {
    return 'N/A';
  }
  return `${value.toFixed(2)} ${currency}`;
};

export const formatCoordinates = (location?: LocationPoint | null) => {
  if (!location || location.lat === undefined || location.lng === undefined) {
    return 'N/A';
  }
  return `${location.lat.toFixed(4)}, ${location.lng.toFixed(4)}`;
};

export const formatDate = (value?: string, fallback = 'N/A') => {
  if (!value) {
    return fallback;
  }
  return new Date(value).toLocaleString();
};
