import { useEffect, useState } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap, Polyline } from 'react-leaflet';
import { LatLngExpression, LatLngTuple } from 'leaflet';
import { api } from '../config/api';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';

// Fix for default marker icons in React-Leaflet
import icon from 'leaflet/dist/images/marker-icon.png';
import iconShadow from 'leaflet/dist/images/marker-shadow.png';

const DefaultIcon = L.icon({
  iconUrl: icon,
  shadowUrl: iconShadow,
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
  shadowSize: [41, 41],
});

L.Marker.prototype.options.icon = DefaultIcon;

// Component to handle map centering
const MapCenter = ({ center }: { center: LatLngExpression }) => {
  const map = useMap();
  useEffect(() => {
    map.setView(center, map.getZoom());
  }, [map, center]);
  return null;
};

// Route service to get route from OSRM
const getRoute = async (
  startLat: number,
  startLng: number,
  endLat: number,
  endLng: number
): Promise<LatLngTuple[]> => {
  try {
    const url = `https://router.project-osrm.org/route/v1/driving/${startLng},${startLat};${endLng},${endLat}?overview=full&geometries=geojson`;
    const response = await fetch(url);
    const data = await response.json();

    if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
      const route = data.routes[0];
      const geometry = route.geometry;

      if (geometry && geometry.coordinates) {
        // GeoJSON format is [lng, lat], convert to [lat, lng] for Leaflet
        return geometry.coordinates.map((coord: number[]) => [
          coord[1],
          coord[0],
        ]) as LatLngTuple[];
      }
    }
  } catch (error) {
    console.error('Error fetching route:', error);
  }

  // Fallback: return straight line if routing fails
  return [
    [startLat, startLng],
    [endLat, endLng],
  ] as LatLngTuple[];
};

const MapView = () => {
  const [drivers, setDrivers] = useState<any[]>([]);
  const [orders, setOrders] = useState<any[]>([]);
  const [userLocation, setUserLocation] = useState<LatLngExpression | null>(null);
  const [loading, setLoading] = useState(true);
  const [dataLoading, setDataLoading] = useState(true);
  const [locationLoading, setLocationLoading] = useState(true);
  const [routes, setRoutes] = useState<Map<string, LatLngTuple[]>>(new Map());
  const [loadingRoutes, setLoadingRoutes] = useState(false);

  useEffect(() => {
    fetchData();
    getUserLocation();
  }, []);

  const getUserLocation = () => {
    // Set default location immediately so map can render
    setUserLocation([51.505, -0.09]); // Default location (London)
    setLocationLoading(false);

    // Try to get user's location, but don't block rendering
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation([position.coords.latitude, position.coords.longitude]);
        },
        () => {
          // Silently handle geolocation errors - use default location
          // Don't log errors to avoid console noise
          // Error types: PERMISSION_DENIED, POSITION_UNAVAILABLE, TIMEOUT
        },
        {
          timeout: 5000,
          enableHighAccuracy: false,
          maximumAge: 300000, // Use cached location if available
        }
      );
    }
  };

  const fetchData = async () => {
    try {
      const [driversRes, ordersRes] = await Promise.all([
        api.get('/users'),
        api.get('/orders'),
      ]);

      const allUsers = driversRes.data.users || [];
      const allOrders = ordersRes.data.orders || [];

      const filteredDrivers = allUsers.filter((u: any) => u.role === 'driver' && u.location);
      const filteredOrders = allOrders.filter((o: any) => 
        ['pending', 'accepted', 'on_the_way'].includes(o.status)
      );

      setDrivers(filteredDrivers);
      setOrders(filteredOrders);

      // Calculate routes for orders with assigned drivers
      await calculateRoutes(filteredOrders, filteredDrivers);
    } catch (error) {
      console.error('Error fetching map data:', error);
    } finally {
      setDataLoading(false);
    }
  };

  const calculateRoutes = async (ordersList: any[], driversList: any[]) => {
    setLoadingRoutes(true);
    const routesMap = new Map<string, LatLngTuple[]>();

    try {
      // Process routes for orders that have assigned drivers
      const routePromises = ordersList
        .filter((order) => {
          // Only calculate route if order has a driver assigned
          return order.driverId && order.driverId.location && order.dropoffLocation;
        })
        .map(async (order) => {
          const driver = driversList.find((d) => d._id === order.driverId._id);
          if (!driver || !driver.location) return;

          const driverLoc = driver.location;
          const customerLoc = order.dropoffLocation;

          try {
            const route = await getRoute(
              driverLoc.lat,
              driverLoc.lng,
              customerLoc.lat,
              customerLoc.lng
            );
            routesMap.set(order._id, route);
          } catch (error) {
            console.error(`Error calculating route for order ${order._id}:`, error);
          }
        });

      await Promise.all(routePromises);
      setRoutes(routesMap);
    } catch (error) {
      console.error('Error calculating routes:', error);
    } finally {
      setLoadingRoutes(false);
    }
  };

  // Update main loading state when both data and location are ready
  useEffect(() => {
    if (!dataLoading && !locationLoading) {
      setLoading(false);
    }
  }, [dataLoading, locationLoading]);

  if (loading) {
    return (
      <div className="space-y-6">
        <h1 className="text-3xl font-bold text-gray-900">Map View</h1>
        <div className="flex items-center justify-center h-[600px]">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-gray-600">Loading map...</p>
          </div>
        </div>
      </div>
    );
  }

  // Use default location if userLocation is not set
  const mapCenter = userLocation || [51.505, -0.09];

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">Map View</h1>
      <div className="bg-white rounded-lg shadow-lg overflow-hidden">
        <MapContainer
          center={mapCenter}
          zoom={2}
          style={{ height: '600px', width: '100%' }}
          scrollWheelZoom={true}
        >
          <MapCenter center={mapCenter} />
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          {/* Route Polylines - Draw routes between drivers and customers */}
          {Array.from(routes.entries()).map(([orderId, routePoints]) => {
            const order = orders.find((o) => o._id === orderId);
            if (!order || routePoints.length < 2) return null;

            return (
              <Polyline
                key={`route-${orderId}`}
                positions={routePoints}
                pathOptions={{
                  color: '#3B82F6',
                  weight: 4,
                  opacity: 0.7,
                }}
              />
            );
          })}

          {/* Driver Markers */}
          {drivers.map((driver) => {
            if (!driver.location) return null;
            return (
              <Marker
                key={`driver-${driver._id}`}
                position={[driver.location.lat, driver.location.lng]}
              >
                <Popup>
                  <div>
                    <h3 className="font-bold">{driver.name}</h3>
                    <p className="text-sm text-gray-600">{driver.email}</p>
                    <p className="text-sm">
                      Status:{' '}
                      <span
                        className={`font-semibold ${
                          driver.isAvailable ? 'text-green-600' : 'text-gray-600'
                        }`}
                      >
                        {driver.isAvailable ? 'Available' : 'Offline'}
                      </span>
                    </p>
                  </div>
                </Popup>
              </Marker>
            );
          })}

          {/* Order Markers */}
          {orders.map((order) => {
            const pickup = order.pickupLocation;
            const dropoff = order.dropoffLocation;

            return (
              <div key={`order-${order._id}`}>
                {pickup && (
                  <Marker
                    position={[pickup.lat, pickup.lng]}
                    icon={L.icon({
                      ...DefaultIcon.options,
                      iconUrl: 'data:image/svg+xml;base64,' + btoa(`
                        <svg xmlns="http://www.w3.org/2000/svg" width="25" height="41" viewBox="0 0 25 41">
                          <path fill="#FF6B6B" d="M12.5 0C5.596 0 0 5.596 0 12.5c0 12.5 12.5 28.5 12.5 28.5s12.5-16 12.5-28.5C25 5.596 19.404 0 12.5 0z"/>
                          <text x="12.5" y="18" text-anchor="middle" fill="white" font-size="12" font-weight="bold">P</text>
                        </svg>
                      `),
                    })}
                  >
                    <Popup>
                      <div>
                        <h3 className="font-bold">Pickup Point</h3>
                        <p className="text-sm">Order #{order._id.substring(0, 8)}</p>
                        <p className="text-sm">Status: {order.status}</p>
                      </div>
                    </Popup>
                  </Marker>
                )}
                {dropoff && (
                  <Marker
                    position={[dropoff.lat, dropoff.lng]}
                    icon={L.icon({
                      ...DefaultIcon.options,
                      iconUrl: 'data:image/svg+xml;base64,' + btoa(`
                        <svg xmlns="http://www.w3.org/2000/svg" width="25" height="41" viewBox="0 0 25 41">
                          <path fill="#4ECDC4" d="M12.5 0C5.596 0 0 5.596 0 12.5c0 12.5 12.5 28.5 12.5 28.5s12.5-16 12.5-28.5C25 5.596 19.404 0 12.5 0z"/>
                          <text x="12.5" y="18" text-anchor="middle" fill="white" font-size="12" font-weight="bold">D</text>
                        </svg>
                      `),
                    })}
                  >
                    <Popup>
                      <div>
                        <h3 className="font-bold">Drop-off Point</h3>
                        <p className="text-sm">Order #{order._id.substring(0, 8)}</p>
                        <p className="text-sm">Status: {order.status}</p>
                      </div>
                    </Popup>
                  </Marker>
                )}
              </div>
            );
          })}
        </MapContainer>
      </div>
      <div className="bg-white p-4 rounded-lg shadow">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-green-500 rounded-full"></div>
            <span className="text-sm">Available Drivers</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-red-500 rounded-full"></div>
            <span className="text-sm">Pickup Points</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-cyan-500 rounded-full"></div>
            <span className="text-sm">Drop-off Points</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-1 h-8 bg-blue-500"></div>
            <span className="text-sm">Driver-Customer Routes</span>
          </div>
          {loadingRoutes && (
            <div className="flex items-center gap-2">
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
              <span className="text-sm text-gray-600">Calculating routes...</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MapView;