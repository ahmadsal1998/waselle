import { useCallback, useEffect, useState } from 'react';
import { getOrders } from '@/services/orderService';
import { getUsers } from '@/services/userService';
import type { OrderStatus } from '@/types';

export interface DashboardStats {
  totalUsers: number;
  totalDrivers: number;
  totalOrders: number;
  activeOrders: number;
  completedOrders: number;
  pendingOrders: number;
}

const ACTIVE_STATUSES: readonly OrderStatus[] = ['accepted', 'on_the_way'];
const COMPLETED_STATUSES: readonly OrderStatus[] = ['delivered'];
const PENDING_STATUSES: readonly OrderStatus[] = ['pending'];

const isStatusIncluded = (status: string, allowed: readonly OrderStatus[]) =>
  allowed.includes(status as OrderStatus);

export const useDashboardStats = () => {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchStats = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const [users, orders] = await Promise.all([getUsers(), getOrders()]);

      // Handle possible difference in user types and allow only matching users
      const customers = users.filter((user: any) => user.role && user.role.toLowerCase() === 'customer');
      const drivers = users.filter((user: any) => user.role && user.role.toLowerCase() === 'driver');

      const activeOrders = orders.filter((order: any) => isStatusIncluded(order.status, ACTIVE_STATUSES));
      const completedOrders = orders.filter((order: any) => isStatusIncluded(order.status, COMPLETED_STATUSES));
      const pendingOrders = orders.filter((order) => isStatusIncluded(order.status, PENDING_STATUSES));

      const dashboardStats: DashboardStats = {
        totalUsers: customers.length,
        totalDrivers: drivers.length,
        totalOrders: orders.length,
        activeOrders: activeOrders.length,
        completedOrders: completedOrders.length,
        pendingOrders: pendingOrders.length,
      };

      setStats(dashboardStats);
    } catch (err) {
      console.error('Failed to fetch dashboard stats:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch dashboard stats');
      setStats(null);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchStats();
  }, [fetchStats]);

  return {
    stats,
    isLoading,
    error,
    refresh: fetchStats,
  };
};
