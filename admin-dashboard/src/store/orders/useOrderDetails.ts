import { useCallback, useEffect, useState } from 'react';
import { getOrderById } from '@/services/orderService';
import type { OrderDetail } from '@/types';

export const useOrderDetails = (orderId: string | undefined) => {
  const [order, setOrder] = useState<OrderDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchOrder = useCallback(async () => {
    if (!orderId) {
      setOrder(null);
      setIsLoading(false);
      return;
    }

    setIsLoading(true);
    setError(null);

    try {
      const data = await getOrderById(orderId);
      setOrder(data);
    } catch (err) {
      console.error('Failed to fetch order details:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch order details');
      setOrder(null);
    } finally {
      setIsLoading(false);
    }
  }, [orderId]);

  useEffect(() => {
    void fetchOrder();
  }, [fetchOrder]);

  return {
    order,
    isLoading,
    error,
    refresh: fetchOrder,
  };
};
