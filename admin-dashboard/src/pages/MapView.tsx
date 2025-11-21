import { useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, useMap, Polyline } from 'react-leaflet';
import { LatLngExpression } from 'leaflet';
import 'leaflet/dist/leaflet.css';
import L from 'leaflet';
import { useMapData } from '@/store/map/useMapData';

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

// Icon instances for different marker types (created once, reused)
const DriverIcon = L.icon({
  iconUrl: 'data:image/svg+xml;base64,' + btoa(`
    <svg xmlns="http://www.w3.org/2000/svg" width="25" height="41" viewBox="0 0 25 41">
      <path fill="#10B981" d="M12.5 0C5.596 0 0 5.596 0 12.5c0 12.5 12.5 28.5 12.5 28.5s12.5-16 12.5-28.5C25 5.596 19.404 0 12.5 0z"/>
      <text x="12.5" y="18" text-anchor="middle" fill="white" font-size="12" font-weight="bold">D</text>
    </svg>
  `),
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
});

const CustomerIcon = L.icon({
  iconUrl: 'data:image/svg+xml;base64,' + btoa(`
    <svg xmlns="http://www.w3.org/2000/svg" width="25" height="41" viewBox="0 0 25 41">
      <path fill="#8B5CF6" d="M12.5 0C5.596 0 0 5.596 0 12.5c0 12.5 12.5 28.5 12.5 28.5s12.5-16 12.5-28.5C25 5.596 19.404 0 12.5 0z"/>
      <text x="12.5" y="18" text-anchor="middle" fill="white" font-size="12" font-weight="bold">U</text>
    </svg>
  `),
  iconSize: [25, 41],
  iconAnchor: [12, 41],
  popupAnchor: [1, -34],
});

// Component to handle map centering
const MapCenter = ({ center }: { center: LatLngExpression }) => {
  const map = useMap();
  useEffect(() => {
    map.setView(center, map.getZoom());
  }, [map, center]);
  return null;
};

const MapView = () => {
  const { drivers, customers, orders, routes, isLoading, loadingRoutes, mapCenter, mapZoom } = useMapData();

  // Debug logging to verify data is loaded and rendered
  useEffect(() => {
    if (!isLoading) {
      const driversWithValidLocation = drivers.filter(d => 
        d.location && 
        typeof d.location.lat === 'number' && 
        typeof d.location.lng === 'number' &&
        !isNaN(d.location.lat) &&
        !isNaN(d.location.lng)
      );
      const customersWithValidLocation = customers.filter(c => 
        c.location && 
        typeof c.location.lat === 'number' && 
        typeof c.location.lng === 'number' &&
        !isNaN(c.location.lat) &&
        !isNaN(c.location.lng)
      );
      
      console.log('MapView - Data ready for rendering:', {
        driversCount: drivers.length,
        customersCount: customers.length,
        ordersCount: orders.length,
        driversWithValidLocation: driversWithValidLocation.length,
        customersWithValidLocation: customersWithValidLocation.length,
        driversWithoutLocation: drivers.length - driversWithValidLocation.length,
        customersWithoutLocation: customers.length - customersWithValidLocation.length,
      });

      // Warn if drivers/customers are missing locations
      if (drivers.length > 0 && driversWithValidLocation.length === 0) {
        console.warn('⚠️ No drivers have valid location data. Drivers will not appear on the map.');
      }
      if (customers.length > 0 && customersWithValidLocation.length === 0) {
        console.warn('⚠️ No customers have valid location data. Customers will not appear on the map.');
      }
    }
  }, [isLoading, drivers, customers, orders]);

  if (isLoading) {
    return (
      <div className="space-y-6 page-transition">
        <h1 className="text-3xl font-bold text-slate-900">Map View</h1>
        <div className="flex items-center justify-center h-[calc(100vh-300px)] min-h-[600px]">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
            <p className="mt-4 text-slate-600">Loading map...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 page-transition">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Map View</h1>
        <p className="mt-2 text-slate-600">Real-time view of drivers, customers, and orders</p>
      </div>
      <div className="card overflow-hidden p-0">
        <MapContainer 
          center={mapCenter} 
          zoom={mapZoom} 
          style={{ height: 'calc(100vh - 300px)', minHeight: '600px', width: '100%' }} 
          scrollWheelZoom={true}
          className="z-0"
        >
          <MapCenter center={mapCenter} />
          <TileLayer
            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
          />

          {/* Render routes first (background layer) */}
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

          {/* Render order markers (pickup and dropoff points) */}
          {orders.map((order) => {
            const pickup = order.pickupLocation;
            const dropoff = order.dropoffLocation;

            return (
              <div key={`order-${order._id}`}>
                {pickup && (
                  <Marker
                    key={`pickup-${order._id}`}
                    position={[pickup.lat, pickup.lng]}
                    icon={L.icon({
                      ...DefaultIcon.options,
                      iconUrl:
                        'data:image/svg+xml;base64,' +
                        btoa(`
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
                    key={`dropoff-${order._id}`}
                    position={[dropoff.lat, dropoff.lng]}
                    icon={L.icon({
                      ...DefaultIcon.options,
                      iconUrl:
                        'data:image/svg+xml;base64,' +
                        btoa(`
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

          {/* Render drivers and customers LAST so they appear on top */}
          {drivers.map((driver) => {
            // Validate location data before rendering
            if (!driver.location || 
                typeof driver.location.lat !== 'number' || 
                typeof driver.location.lng !== 'number' ||
                isNaN(driver.location.lat) || 
                isNaN(driver.location.lng)) {
              console.log('Driver skipped - invalid location:', driver._id, driver.location);
              return null;
            }

            console.log('Rendering driver marker:', driver._id, driver.name, [driver.location.lat, driver.location.lng]);

            return (
              <Marker
                key={`driver-${driver._id}`}
                position={[driver.location.lat, driver.location.lng]}
                icon={DriverIcon}
              >
                <Popup>
                  <div>
                    <h3 className="font-bold">Driver: {driver.name}</h3>
                    <p className="text-sm text-gray-600">{driver.email}</p>
                    <p className="text-sm">
                      Status:{' '}
                      <span className={`font-semibold ${driver.isAvailable ? 'text-green-600' : 'text-gray-600'}`}>
                        {driver.isAvailable ? 'Available' : 'Offline'}
                      </span>
                    </p>
                    {driver.vehicleType && (
                      <p className="text-sm text-gray-600">Vehicle: {driver.vehicleType}</p>
                    )}
                  </div>
                </Popup>
              </Marker>
            );
          })}

          {customers.map((customer) => {
            // Validate location data before rendering
            if (!customer.location || 
                typeof customer.location.lat !== 'number' || 
                typeof customer.location.lng !== 'number' ||
                isNaN(customer.location.lat) || 
                isNaN(customer.location.lng)) {
              console.log('Customer skipped - invalid location:', customer._id, customer.location);
              return null;
            }

            console.log('Rendering customer marker:', customer._id, customer.name, [customer.location.lat, customer.location.lng]);

            return (
              <Marker
                key={`customer-${customer._id}`}
                position={[customer.location.lat, customer.location.lng]}
                icon={CustomerIcon}
              >
                <Popup>
                  <div>
                    <h3 className="font-bold">Customer: {customer.name}</h3>
                    <p className="text-sm text-gray-600">{customer.email}</p>
                  </div>
                </Popup>
              </Marker>
            );
          })}
        </MapContainer>
      </div>
      <div className="card p-4">
        <div className="flex items-center gap-4 flex-wrap">
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-green-500 rounded-full"></div>
            <span className="text-sm text-slate-700 font-medium">Drivers</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-purple-500 rounded-full"></div>
            <span className="text-sm text-slate-700 font-medium">Customers</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-red-500 rounded-full"></div>
            <span className="text-sm text-slate-700 font-medium">Pickup Points</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-4 h-4 bg-cyan-500 rounded-full"></div>
            <span className="text-sm text-slate-700 font-medium">Drop-off Points</span>
          </div>
          <div className="flex items-center gap-2">
            <div className="w-1 h-8 bg-blue-500"></div>
            <span className="text-sm text-slate-700 font-medium">Driver-Customer Routes</span>
          </div>
          {loadingRoutes && (
            <div className="flex items-center gap-2">
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
              <span className="text-sm text-slate-600">Calculating routes...</span>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default MapView;
