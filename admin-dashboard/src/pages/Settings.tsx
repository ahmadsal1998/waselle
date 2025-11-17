import { useState, useEffect } from 'react';
import { getSettings, updateSettings, type Settings as SettingsType } from '@/services/settingsService';

const Settings = () => {
  const [settings, setSettings] = useState<SettingsType | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [internalOrderRadius, setInternalOrderRadius] = useState<number>(5);
  const [externalOrderRadius, setExternalOrderRadius] = useState<number>(10);
  const [serviceAreaLat, setServiceAreaLat] = useState<number>(0);
  const [serviceAreaLng, setServiceAreaLng] = useState<number>(0);
  const [serviceAreaRadius, setServiceAreaRadius] = useState<number>(20);
  const [vehicleTypes, setVehicleTypes] = useState<{
    bike: { enabled: boolean; basePrice: number };
    car: { enabled: boolean; basePrice: number };
    cargo: { enabled: boolean; basePrice: number };
  }>({
    bike: { enabled: true, basePrice: 5 },
    car: { enabled: true, basePrice: 10 },
    cargo: { enabled: false, basePrice: 15 },
  });

  useEffect(() => {
    loadSettings();
  }, []);

  const loadSettings = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getSettings();
      setSettings(data);
      setInternalOrderRadius(data.internalOrderRadiusKm);
      setExternalOrderRadius(data.externalOrderRadiusKm);
      setServiceAreaLat(data.serviceAreaCenter.lat);
      setServiceAreaLng(data.serviceAreaCenter.lng);
      setServiceAreaRadius(data.serviceAreaRadiusKm);
      if (data.vehicleTypes) {
        setVehicleTypes(data.vehicleTypes);
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load settings');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    // Validate internal order radius
    if (internalOrderRadius < 1 || internalOrderRadius > 100) {
      setError('Internal order radius must be between 1 and 100 kilometers');
      return;
    }

    // Validate external order radius
    if (externalOrderRadius < 1 || externalOrderRadius > 100) {
      setError('External order radius must be between 1 and 100 kilometers');
      return;
    }

    // Validate service area center
    if (serviceAreaLat < -90 || serviceAreaLat > 90) {
      setError('Service area latitude must be between -90 and 90');
      return;
    }
    if (serviceAreaLng < -180 || serviceAreaLng > 180) {
      setError('Service area longitude must be between -180 and 180');
      return;
    }

    // Validate service area radius
    if (serviceAreaRadius < 1 || serviceAreaRadius > 500) {
      setError('Service area radius must be between 1 and 500 kilometers');
      return;
    }

    try {
      setSaving(true);
      setError(null);
      setSuccess(null);
      const updated = await updateSettings({
        internalOrderRadiusKm: internalOrderRadius,
        externalOrderRadiusKm: externalOrderRadius,
        serviceAreaCenter: {
          lat: serviceAreaLat,
          lng: serviceAreaLng,
        },
        serviceAreaRadiusKm: serviceAreaRadius,
        vehicleTypes: vehicleTypes,
      });
      setSettings(updated);
      setSuccess('Settings saved successfully!');
      setTimeout(() => setSuccess(null), 3000);
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to save settings');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-6">
        <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
        <div className="bg-white shadow rounded-lg p-6">
          <div className="flex items-center justify-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <span className="ml-3 text-gray-600">Loading settings...</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">Settings</h1>

      {error && (
        <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-md">
          {error}
        </div>
      )}

      {success && (
        <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-md">
          {success}
        </div>
      )}

      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">Order Distance Settings</h2>
        <div className="space-y-6">
          <div>
            <label
              htmlFor="internalOrderRadius"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Internal Orders Radius (kilometers)
            </label>
            <p className="text-sm text-gray-500 mb-3">
              Orders within the service area will be sent to drivers within this distance from the
              customer's pickup location. Range: 1-100 km
            </p>
            <div className="flex items-center space-x-4">
              <input
                type="number"
                id="internalOrderRadius"
                min="1"
                max="100"
                step="0.1"
                value={internalOrderRadius}
                onChange={(e) => setInternalOrderRadius(Number(e.target.value))}
                className="block w-32 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 border"
              />
              <span className="text-sm text-gray-600">km</span>
            </div>
            {settings && (
              <p className="mt-2 text-xs text-gray-500">
                Current value: {settings.internalOrderRadiusKm} km
              </p>
            )}
          </div>

          <div>
            <label
              htmlFor="externalOrderRadius"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              External Orders Radius (kilometers)
            </label>
            <p className="text-sm text-gray-500 mb-3">
              Orders outside the service area will be sent to drivers within this distance from the
              customer's pickup location. Range: 1-100 km
            </p>
            <div className="flex items-center space-x-4">
              <input
                type="number"
                id="externalOrderRadius"
                min="1"
                max="100"
                step="0.1"
                value={externalOrderRadius}
                onChange={(e) => setExternalOrderRadius(Number(e.target.value))}
                className="block w-32 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 border"
              />
              <span className="text-sm text-gray-600">km</span>
            </div>
            {settings && (
              <p className="mt-2 text-xs text-gray-500">
                Current value: {settings.externalOrderRadiusKm} km
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">Service Area Configuration</h2>
        <div className="space-y-6">
          <p className="text-sm text-gray-500 mb-4">
            Configure the service area center point and radius. Orders within this area are considered "internal",
            while orders outside are considered "external".
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label
                htmlFor="serviceAreaLat"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Service Area Center - Latitude
              </label>
              <input
                type="number"
                id="serviceAreaLat"
                min="-90"
                max="90"
                step="0.000001"
                value={serviceAreaLat}
                onChange={(e) => setServiceAreaLat(Number(e.target.value))}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 border"
                placeholder="0.0"
              />
              <p className="mt-1 text-xs text-gray-500">Range: -90 to 90</p>
            </div>

            <div>
              <label
                htmlFor="serviceAreaLng"
                className="block text-sm font-medium text-gray-700 mb-2"
              >
                Service Area Center - Longitude
              </label>
              <input
                type="number"
                id="serviceAreaLng"
                min="-180"
                max="180"
                step="0.000001"
                value={serviceAreaLng}
                onChange={(e) => setServiceAreaLng(Number(e.target.value))}
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 border"
                placeholder="0.0"
              />
              <p className="mt-1 text-xs text-gray-500">Range: -180 to 180</p>
            </div>
          </div>

          <div>
            <label
              htmlFor="serviceAreaRadius"
              className="block text-sm font-medium text-gray-700 mb-2"
            >
              Service Area Radius (kilometers)
            </label>
            <p className="text-sm text-gray-500 mb-3">
              The radius that defines the service area boundary. Range: 1-500 km
            </p>
            <div className="flex items-center space-x-4">
              <input
                type="number"
                id="serviceAreaRadius"
                min="1"
                max="500"
                step="0.1"
                value={serviceAreaRadius}
                onChange={(e) => setServiceAreaRadius(Number(e.target.value))}
                className="block w-32 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 border"
              />
              <span className="text-sm text-gray-600">km</span>
            </div>
            {settings && (
              <p className="mt-2 text-xs text-gray-500">
                Current value: {settings.serviceAreaRadiusKm} km
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <div className="flex justify-end">
          <button
            onClick={handleSave}
            disabled={
              saving ||
              internalOrderRadius < 1 ||
              internalOrderRadius > 100 ||
              externalOrderRadius < 1 ||
              externalOrderRadius > 100 ||
              serviceAreaLat < -90 ||
              serviceAreaLat > 90 ||
              serviceAreaLng < -180 ||
              serviceAreaLng > 180 ||
              serviceAreaRadius < 1 ||
              serviceAreaRadius > 500
            }
            className="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 disabled:cursor-not-allowed text-white px-8 py-3 rounded-md font-medium transition-colors text-lg"
          >
            {saving ? 'Saving...' : 'Save All Settings'}
          </button>
        </div>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">Vehicle Types Configuration</h2>
        <div className="space-y-6">
          <p className="text-sm text-gray-500 mb-4">
            Configure vehicle types availability and pricing. Users will only see enabled vehicle types.
          </p>
          {(['bike', 'car', 'cargo'] as const).map((type) => (
            <div key={type} className="border rounded-lg p-4">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h3 className="text-lg font-semibold capitalize">{type}</h3>
                  <p className="text-sm text-gray-500">
                    {type === 'bike' && 'Starting price: 5 ILS'}
                    {type === 'car' && 'Starting price: 10 ILS'}
                    {type === 'cargo' && 'Starting price: 15 ILS (default)'}
                  </p>
                </div>
                <label className="flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={vehicleTypes[type].enabled}
                    onChange={(e) =>
                      setVehicleTypes({
                        ...vehicleTypes,
                        [type]: { ...vehicleTypes[type], enabled: e.target.checked },
                      })
                    }
                    className="w-5 h-5 text-blue-600 rounded focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm font-medium text-gray-700">
                    {vehicleTypes[type].enabled ? 'Enabled' : 'Disabled'}
                  </span>
                </label>
              </div>
              <div>
                <label
                  htmlFor={`${type}-price`}
                  className="block text-sm font-medium text-gray-700 mb-2"
                >
                  Base Price (ILS)
                </label>
                <div className="flex items-center space-x-4">
                  <input
                    type="number"
                    id={`${type}-price`}
                    min="0"
                    step="0.01"
                    value={vehicleTypes[type].basePrice}
                    onChange={(e) =>
                      setVehicleTypes({
                        ...vehicleTypes,
                        [type]: {
                          ...vehicleTypes[type],
                          basePrice: parseFloat(e.target.value) || 0,
                        },
                      })
                    }
                    className="block w-32 rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm px-3 py-2 border"
                  />
                  <span className="text-sm text-gray-600">ILS</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">System Information</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Map Provider
            </label>
            <p className="mt-1 text-sm text-gray-500">
              Using OpenStreetMap (free, no API key required)
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings;
