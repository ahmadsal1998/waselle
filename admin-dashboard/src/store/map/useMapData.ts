import { useCallback, useEffect, useMemo, useState } from 'react';
import type { LatLngExpression, LatLngTuple } from 'leaflet';
import { getOrders } from '@/services/orderService';
import { getUsers } from '@/services/userService';
import { getRoute } from '@/services/routeService';
import type { ApiUser, Driver, Customer, Order, OrderStatus } from '@/types';

const DEFAULT_LOCATION: LatLngExpression = [51.505, -0.09];
const TRACKED_ORDER_STATUSES: readonly OrderStatus[] = ['pending', 'accepted', 'on_the_way'];

const isTrackedStatus = (status: string): status is OrderStatus =>
  TRACKED_ORDER_STATUSES.includes(status as OrderStatus);

const normalizeDriver = (driver: ApiUser): Driver => ({
  _id: driver._id,
  name: driver.name,
  email: driver.email,
  role: 'driver',
  isAvailable: Boolean(driver.isAvailable),
  vehicleType: driver.vehicleType,
  location: driver.location ?? null,
  createdAt: driver.createdAt,
  updatedAt: driver.updatedAt,
});

const normalizeCustomer = (customer: ApiUser): Customer & { location?: { lat: number; lng: number } | null } => ({
  _id: customer._id,
  name: customer.name,
  email: customer.email,
  role: 'customer',
  location: customer.location ?? null,
  createdAt: customer.createdAt,
  updatedAt: customer.updatedAt,
});

export const useMapData = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [customers, setCustomers] = useState<(Customer & { location?: { lat: number; lng: number } | null })[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [routes, setRoutes] = useState<Map<string, LatLngTuple[]>>(new Map());
  const [userLocation, setUserLocation] = useState<LatLngExpression | null>(null);
  const [dataLoading, setDataLoading] = useState(true);
  const [locationLoading, setLocationLoading] = useState(true);
  const [loadingRoutes, setLoadingRoutes] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  const calculateRoutes = useCallback(async (ordersList: Order[], driversList: Driver[]) => {
    setLoadingRoutes(true);
    const routesMap = new Map<string, LatLngTuple[]>();

    try {
      const routePromises = ordersList
        .filter((order) => order.driverId?._id && order.dropoffLocation)
        .map(async (order) => {
          const driver = driversList.find((candidate) => candidate._id === order.driverId?._id);
          if (!driver?.location || !order.dropoffLocation) {
            return;
          }

          const route = await getRoute(driver.location, order.dropoffLocation);
          routesMap.set(order._id, route);
        });

      await Promise.all(routePromises);
      setRoutes(routesMap);
    } catch (error) {
      console.error('Error calculating routes:', error);
    } finally {
      setLoadingRoutes(false);
    }
  }, []);

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    setDataLoading(true);

    try {
      const [usersResponse, ordersResponse] = await Promise.all([getUsers(), getOrders()]);

      const driverUsers = usersResponse
        .filter((user) => user.role === 'driver')
        .map((driver) => normalizeDriver(driver));

      const customerUsers = usersResponse
        .filter((user) => user.role === 'customer' && user.location)
        .map((customer) => normalizeCustomer(customer));

      const trackedOrders = ordersResponse.filter((order) => isTrackedStatus(order.status));

      setDrivers(driverUsers);
      setCustomers(customerUsers);
      setOrders(trackedOrders);

      await calculateRoutes(trackedOrders, driverUsers);
    } catch (error) {
      console.error('Error fetching map data:', error);
      setDrivers([]);
      setCustomers([]);
      setOrders([]);
      setRoutes(new Map());
    } finally {
      setDataLoading(false);
    }
  }, [calculateRoutes]);

  const determineUserLocation = useCallback(() => {
    setUserLocation(DEFAULT_LOCATION);
    setLocationLoading(false);

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation([position.coords.latitude, position.coords.longitude]);
        },
        () => {
          // Silent failure; retain default location
        },
        {
          timeout: 5000,
          enableHighAccuracy: false,
          maximumAge: 300000,
        }
      );
    }
  }, []);

  useEffect(() => {
    void fetchData();
    determineUserLocation();
  }, [fetchData, determineUserLocation]);

  useEffect(() => {
    if (!dataLoading && !locationLoading) {
      setIsLoading(false);
    }
  }, [dataLoading, locationLoading]);

  const mapCenter = useMemo<LatLngExpression>(() => userLocation ?? DEFAULT_LOCATION, [userLocation]);

  return {
    drivers,
    customers,
    orders,
    routes,
    loadingRoutes,
    isLoading,
    mapCenter,
    refresh: fetchData,
  };
};
