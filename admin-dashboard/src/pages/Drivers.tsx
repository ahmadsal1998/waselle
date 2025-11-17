import { useDrivers } from '@/store/drivers/useDrivers';

const Drivers = () => {
  const { drivers, isLoading, error } = useDrivers();

  if (isLoading) {
    return <div className="text-center py-12">Loading...</div>;
  }

  if (error) {
    return (
      <div className="space-y-4">
        <h1 className="text-3xl font-bold text-gray-900">Drivers Management</h1>
        <div className="bg-red-50 border border-red-100 text-red-600 px-4 py-3 rounded-md">
          {error}
        </div>
      </div>
    );
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
                          Location: {driver.location.lat.toFixed(4)}, {driver.location.lng.toFixed(4)}
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="text-sm text-gray-500">
                    Joined: {driver.createdAt ? new Date(driver.createdAt).toLocaleDateString() : 'N/A'}
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
