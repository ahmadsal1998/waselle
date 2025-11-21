import { useEffect, useState } from 'react';
import { getDrivers, type DriverFilters, type DriversResponse } from '@/services/driverService';
import type { Driver } from '@/types';

export const useDrivers = (filters?: DriverFilters) => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [pagination, setPagination] = useState<DriversResponse['pagination'] | null>(null);

  useEffect(() => {
    let cancelled = false;

    const fetchDrivers = async () => {
      setIsLoading(true);
      setError(null);
      try {
        // Always include balance for drivers page, but use pagination
        const response = await getDrivers({
          ...filters,
          includeBalance: filters?.includeBalance ?? true,
          limit: filters?.limit ?? 50, // Default to 50 per page
        });
        if (!cancelled) {
          setDrivers(response.drivers);
          setPagination(response.pagination || null);
        }
      } catch (err: any) {
        if (!cancelled) {
          console.error('Failed to fetch drivers:', err);
          const errorMessage = err?.response?.data?.message || err?.message || 'Failed to fetch drivers';
          setError(errorMessage);
          setDrivers([]);
          setPagination(null);
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    };

    void fetchDrivers();

    return () => {
      cancelled = true;
    };
  }, [filters?.search, filters?.status, filters?.page]); // Depend on filter values, not the object

  const refresh = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const response = await getDrivers({
        ...filters,
        includeBalance: filters?.includeBalance ?? true,
        limit: filters?.limit ?? 50,
      });
      setDrivers(response.drivers);
      setPagination(response.pagination || null);
    } catch (err) {
      console.error('Failed to fetch drivers:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch drivers');
      setDrivers([]);
      setPagination(null);
    } finally {
      setIsLoading(false);
    }
  };

  return {
    drivers,
    isLoading,
    error,
    pagination,
    refresh,
  };
};
