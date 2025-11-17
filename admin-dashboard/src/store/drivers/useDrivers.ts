import { useCallback, useEffect, useState } from 'react';
import { getUsers } from '@/services/userService';
import type { Driver } from '@/types';

export const useDrivers = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchDrivers = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const users = await getUsers();
      const driverUsers = users
        .filter((user) => user.role === 'driver')
        .map<Driver>((driver) => ({
          _id: driver._id,
          name: driver.name,
          email: driver.email,
          role: 'driver',
          isAvailable: Boolean(driver.isAvailable),
          vehicleType: driver.vehicleType,
          location: driver.location ?? null,
          createdAt: driver.createdAt,
          updatedAt: driver.updatedAt,
        }));
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
