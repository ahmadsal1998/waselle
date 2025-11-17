import { useCallback, useEffect, useMemo, useState } from 'react';
import { getUsers } from '@/services/userService';
import type { ApiUser } from '@/types';

export interface UseUsersOptions {
  role?: ApiUser['role'];
}

export const useUsers = (options: UseUsersOptions = {}) => {
  const [users, setUsers] = useState<ApiUser[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const { role } = options;

  const fetchUsers = useCallback(async () => {
    setIsLoading(true);
    setError(null);

    try {
      const data = await getUsers();
      setUsers(data);
    } catch (err) {
      console.error('Failed to fetch users:', err);
      setError(err instanceof Error ? err.message : 'Failed to fetch users');
      setUsers([]);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    void fetchUsers();
  }, [fetchUsers]);

  const filteredUsers = useMemo(() => {
    if (!role) {
      return users;
    }

    return users.filter((user) => user.role === role);
  }, [role, users]);

  return {
    users: filteredUsers,
    isLoading,
    error,
    refresh: fetchUsers,
  };
};
