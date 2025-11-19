import { useEffect, useState } from 'react';
import { getDrivers, type DriverFilters } from '@/services/driverService';
import type { Driver } from '@/types';

export const useDrivers = (filters?: DriverFilters) => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;

    const fetchDrivers = async () => {
      setIsLoading(true);
      setError(null);
      try {
        const driverUsers = await getDrivers(filters);
        if (!cancelled) {
          setDrivers(driverUsers);
        }
      } catch (err: any) {
        if (!cancelled) {
          console.error('Failed to fetch drivers:', err);
          const errorMessage = err?.response?.data?.message || err?.message || 'Failed to fetch drivers';
          setError(errorMessage);
          setDrivers([]);
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
  }, [filters?.search, filters?.status]); // Depend on filter values, not the object

  const refresh = async () => {
    setIsLoading(true);
    setError(null);
    try {
      const driverUsers = await getDrivers(filters);
      setDrivers(driverUsers);
    } catch (err) {
      console.error('Failed to fetch drivers:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch drivers');
      setDrivers([]);
    } finally {
      setIsLoading(false);
    }
  };

  return {
    drivers,
    isLoading,
    error,
    refresh,
  };
};
