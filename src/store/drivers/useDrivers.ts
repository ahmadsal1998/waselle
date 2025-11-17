import { useCallback, useEffect, useState } from 'react';
import { getUsers } from '../../services/userService';
import type { Driver } from '../../types';

export const useDrivers = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDrivers = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const users = await getUsers();
      const driverUsers = users.filter((user): user is Driver => user.role === 'driver');
      setDrivers(driverUsers);
    } catch (err) {
      console.error('Failed to fetch drivers:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch drivers');
      setDrivers([]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchDrivers();
  }, [fetchDrivers]);

  return {
    drivers,
    isLoading,
    error,
    refresh: fetchDrivers,
  };
};


