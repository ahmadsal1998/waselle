import { useCallback, useEffect, useMemo, useState } from 'react';
import type { LatLngExpression, LatLngTuple } from 'leaflet';
import { getOrders } from '@/services/orderService';
import { getUsers } from '@/services/userService';
import { getRoute } from '@/services/routeService';
import { getSettings } from '@/services/settingsService';
import type { ApiUser, Driver, Customer, Order, OrderStatus } from '@/types';

// Default coordinates for Palestine (can be overridden by settings)
const DEFAULT_LOCATION: LatLngExpression = [32.462502185826004, 35.29172911766705];
const DEFAULT_ZOOM = 12;
const TRACKED_ORDER_STATUSES: readonly OrderStatus[] = ['pending', 'accepted', 'on_the_way'];

const isTrackedStatus = (status: string): status is OrderStatus =>
  TRACKED_ORDER_STATUSES.includes(status as OrderStatus);

const normalizeDriver = (driver: ApiUser): Driver => {
  // Normalize location data - handle various formats
  let location = null;
  if (driver.location) {
    // Handle both {lat, lng} and potentially other formats
    if (
      typeof driver.location === 'object' &&
      'lat' in driver.location &&
      'lng' in driver.location &&
      typeof driver.location.lat === 'number' &&
      typeof driver.location.lng === 'number' &&
      !isNaN(driver.location.lat) &&
      !isNaN(driver.location.lng)
    ) {
      location = {
        lat: driver.location.lat,
        lng: driver.location.lng,
        address: driver.location.address,
      };
    }
  }

  return {
    _id: driver._id,
    name: driver.name,
    email: driver.email || '',
    role: 'driver',
    isAvailable: Boolean(driver.isAvailable),
    vehicleType: driver.vehicleType,
    location,
    createdAt: driver.createdAt,
    updatedAt: driver.updatedAt,
  };
};

const normalizeCustomer = (customer: ApiUser): Customer & { location?: { lat: number; lng: number } | null } => {
  // Normalize location data - handle various formats
  let location = null;
  if (customer.location) {
    // Handle both {lat, lng} and potentially other formats
    if (
      typeof customer.location === 'object' &&
      'lat' in customer.location &&
      'lng' in customer.location &&
      typeof customer.location.lat === 'number' &&
      typeof customer.location.lng === 'number' &&
      !isNaN(customer.location.lat) &&
      !isNaN(customer.location.lng)
    ) {
      location = {
        lat: customer.location.lat,
        lng: customer.location.lng,
        address: customer.location.address,
      };
    }
  }

  return {
    _id: customer._id,
    name: customer.name,
    email: customer.email || '',
    role: 'customer',
    location,
    createdAt: customer.createdAt,
    updatedAt: customer.updatedAt,
  };
};

export const useMapData = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [customers, setCustomers] = useState<(Customer & { location?: { lat: number; lng: number } | null })[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [routes, setRoutes] = useState<Map<string, LatLngTuple[]>>(new Map());
  const [userLocation, setUserLocation] = useState<LatLngExpression | null>(null);
  const [mapDefaultCenter, setMapDefaultCenter] = useState<LatLngExpression>(DEFAULT_LOCATION);
  const [mapDefaultZoom, setMapDefaultZoom] = useState<number>(DEFAULT_ZOOM);
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
        .filter((user) => (user.role as string) === 'customer')
        .map((customer) => normalizeCustomer(customer));

      const trackedOrders = ordersResponse.filter((order) => isTrackedStatus(order.status));

      // Detailed logging to debug missing markers
      const driversWithLocation = driverUsers.filter(d => d.location && d.location.lat && d.location.lng);
      const customersWithLocation = customerUsers.filter(c => c.location && c.location.lat && c.location.lng);
      
      console.log('Map data fetched:', {
        totalUsers: usersResponse.length,
        drivers: driverUsers.length,
        customers: customerUsers.length,
        orders: trackedOrders.length,
        driversWithLocation: driversWithLocation.length,
        customersWithLocation: customersWithLocation.length,
      });

      // Log sample data to verify structure
      if (driverUsers.length > 0) {
        console.log('Sample driver data:', {
          firstDriver: {
            id: driverUsers[0]._id,
            name: driverUsers[0].name,
            hasLocation: !!driverUsers[0].location,
            location: driverUsers[0].location,
          },
        });
      }
      if (customerUsers.length > 0) {
        console.log('Sample customer data:', {
          firstCustomer: {
            id: customerUsers[0]._id,
            name: customerUsers[0].name,
            hasLocation: !!customerUsers[0].location,
            location: customerUsers[0].location,
          },
        });
      }
      
      // Log raw API response for debugging
      console.log('Raw users response sample:', usersResponse.slice(0, 3).map(u => ({
        id: u._id,
        name: u.name,
        role: u.role,
        location: u.location,
      })));

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

  const loadMapSettings = useCallback(async () => {
    try {
      const settings = await getSettings();
      if (settings.mapDefaultCenter) {
        setMapDefaultCenter([settings.mapDefaultCenter.lat, settings.mapDefaultCenter.lng]);
      }
      if (settings.mapDefaultZoom !== undefined) {
        setMapDefaultZoom(settings.mapDefaultZoom);
      }
    } catch (error) {
      console.error('Error loading map settings:', error);
      // Use defaults if settings fail to load
    }
  }, []);

  const determineUserLocation = useCallback(() => {
    // Use map default center from settings instead of hardcoded default
    setUserLocation(mapDefaultCenter);
    setLocationLoading(false);

    // Optionally try to get user's actual location, but fallback to settings default
    // Set to false to disable geolocation and eliminate browser console errors
    const ENABLE_GEOLOCATION = false; // Disabled to prevent CoreLocation console errors

    if (ENABLE_GEOLOCATION && navigator.geolocation) {
      // Use a more lenient approach to reduce browser console errors
      navigator.geolocation.getCurrentPosition(
        (position) => {
          // Only use user location if we have valid coordinates
          if (position?.coords?.latitude && position?.coords?.longitude) {
            setUserLocation([position.coords.latitude, position.coords.longitude]);
          }
        },
        (error) => {
          // Silently handle geolocation errors - these are expected in many scenarios
          // (e.g., user denied permission, location unavailable, etc.)
          // No need to log or handle - just use default location from settings
        },
        {
          timeout: 3000, // Reduced timeout to fail faster
          enableHighAccuracy: false, // Use less accurate but faster location
          maximumAge: 600000, // Accept cached location up to 10 minutes old
        }
      );
    }
  }, [mapDefaultCenter]);

  useEffect(() => {
    void loadMapSettings();
  }, [loadMapSettings]);

  useEffect(() => {
    void fetchData();
  }, [fetchData]);

  useEffect(() => {
    // Wait for map settings to load before determining location
    if (mapDefaultCenter) {
      determineUserLocation();
    }
  }, [mapDefaultCenter, determineUserLocation]);

  useEffect(() => {
    if (!dataLoading && !locationLoading) {
      setIsLoading(false);
    }
  }, [dataLoading, locationLoading]);

  const mapCenter = useMemo<LatLngExpression>(() => userLocation ?? mapDefaultCenter, [userLocation, mapDefaultCenter]);

  return {
    drivers,
    customers,
    orders,
    routes,
    loadingRoutes,
    isLoading,
    mapCenter,
    mapZoom: mapDefaultZoom,
    refresh: fetchData,
  };
};
