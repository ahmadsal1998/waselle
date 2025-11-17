import React, { createContext, useContext, useState, useEffect } from 'react';
import { isAxiosError } from 'axios';
import { getCurrentUser, login as loginService } from '@/services/authService';
import type { AuthUser } from '@/types';

interface AuthContextType {
  user: AuthUser | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [user, setUser] = useState<AuthUser | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    // Check for existing token and validate it
    const token = localStorage.getItem('admin_token');
    if (token) {
      // Optimistically set authenticated state based on token presence
      // This prevents immediate redirect while we validate
      fetchCurrentUser();
    } else {
      // No token, no need to check
      setIsLoading(false);
    }
  }, []);

  const fetchCurrentUser = async () => {
    try {
      const currentUser = await getCurrentUser();
      setUser(currentUser);
      setIsAuthenticated(true);
    } catch (error) {
      localStorage.removeItem('admin_token');
      setUser(null);
      setIsAuthenticated(false);
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (email: string, password: string) => {
    try {
      const { token, user: authenticatedUser } = await loginService(email, password);
      localStorage.setItem('admin_token', token);
      setUser(authenticatedUser);
      setIsAuthenticated(true);
    } catch (error) {
      if (isAxiosError<{ message?: string }>(error)) {
        throw new Error(error.response?.data?.message ?? 'Login failed');
      }
      if (error instanceof Error) {
        throw error;
      }
      throw new Error('Login failed');
    }
  };

  const logout = () => {
    localStorage.removeItem('admin_token');
    setUser(null);
    setIsAuthenticated(false);
  };

  return (
    <AuthContext.Provider value={{ user, isAuthenticated, isLoading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
