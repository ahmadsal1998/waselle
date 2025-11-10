import { useEffect, useState } from 'react';
import { api } from '../config/api';

interface Driver {
  _id: string;
  name: string;
  email: string;
  isAvailable: boolean;
  role: 'customer' | 'driver' | 'admin';
  vehicleType?: 'car' | 'bike';
  location?: {
    lat: number;
    lng: number;
  };
  createdAt: string;
}

const Drivers = () => {
  const [drivers, setDrivers] = useState<Driver[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchDrivers();
  }, []);

  const fetchDrivers = async () => {
    try {
      const response = await api.get('/users');
      setDrivers(response.data.users.filter((u: Driver) => u.role === 'driver'));
    } catch (error) {
      console.error('Error fetching drivers:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">Drivers Management</h1>

      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {drivers.map((driver) => (
            <li key={driver._id}>
              <div className="px-4 py-4 sm:px-6">
                <div className="flex items-center justify-between">
                  <div className="flex items-center">
                    <div className="flex-shrink-0 h-10 w-10 rounded-full bg-green-500 flex items-center justify-center text-white font-semibold">
                      {driver.name.charAt(0).toUpperCase()}
                    </div>
                    <div className="ml-4">
                      <div className="text-sm font-medium text-gray-900 flex items-center">
                        {driver.name}
                        <span
                          className={`ml-2 inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            driver.isAvailable
                              ? 'bg-green-100 text-green-800'
                              : 'bg-gray-100 text-gray-800'
                          }`}
                        >
                          {driver.isAvailable ? 'Available' : 'Offline'}
                        </span>
                      </div>
                      <div className="text-sm text-gray-500">{driver.email}</div>
                      <div className="text-sm text-gray-500">
                        Vehicle Type:{' '}
                        <span className="font-medium text-gray-900">
                          {driver.vehicleType
                            ? driver.vehicleType === 'car'
                              ? 'Car'
                              : 'Bike'
                            : 'N/A'}
                        </span>
                      </div>
                      {driver.location && (
                        <div className="text-xs text-gray-400">
                          Location: {driver.location.lat.toFixed(4)},{' '}
                          {driver.location.lng.toFixed(4)}
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="text-sm text-gray-500">
                    Joined: {new Date(driver.createdAt).toLocaleDateString()}
                  </div>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
};

export default Drivers;
