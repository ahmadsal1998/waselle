import { useState, useEffect } from 'react';
import { getSettings, updateSettings, type Settings as SettingsType } from '@/services/settingsService';

const Settings = () => {
  const [settings, setSettings] = useState<SettingsType | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [internalOrderRadius, setInternalOrderRadius] = useState<number>(2);
  const [externalOrderMinRadius, setExternalOrderMinRadius] = useState<number>(10);
  const [externalOrderMaxRadius, setExternalOrderMaxRadius] = useState<number>(15);
  const [mapDefaultLat, setMapDefaultLat] = useState<number>(32.462502185826004);
  const [mapDefaultLng, setMapDefaultLng] = useState<number>(35.29172911766705);
  const [mapDefaultZoom, setMapDefaultZoom] = useState<number>(12);
  const [commissionPercentage, setCommissionPercentage] = useState<number>(2);
  const [maxAllowedBalance, setMaxAllowedBalance] = useState<number>(50);
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
      setExternalOrderMinRadius(data.externalOrderMinRadiusKm);
      setExternalOrderMaxRadius(data.externalOrderMaxRadiusKm);
      if (data.mapDefaultCenter) {
        setMapDefaultLat(data.mapDefaultCenter.lat);
        setMapDefaultLng(data.mapDefaultCenter.lng);
      }
      if (data.mapDefaultZoom !== undefined) {
        setMapDefaultZoom(data.mapDefaultZoom);
      }
      if (data.vehicleTypes) {
        setVehicleTypes(data.vehicleTypes);
      }
      if (data.commissionPercentage !== undefined) {
        setCommissionPercentage(data.commissionPercentage);
      }
      if (data.maxAllowedBalance !== undefined) {
        setMaxAllowedBalance(data.maxAllowedBalance);
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

    // Validate external order min radius
    if (externalOrderMinRadius < 1 || externalOrderMinRadius > 100) {
      setError('External order min radius must be between 1 and 100 kilometers');
      return;
    }

    // Validate external order max radius
    if (externalOrderMaxRadius < 1 || externalOrderMaxRadius > 100) {
      setError('External order max radius must be between 1 and 100 kilometers');
      return;
    }

    // Validate that min <= max
    if (externalOrderMinRadius > externalOrderMaxRadius) {
      setError('External order min radius must be less than or equal to max radius');
      return;
    }

    // Validate map default center
    if (mapDefaultLat < -90 || mapDefaultLat > 90) {
      setError('Map default latitude must be between -90 and 90');
      return;
    }
    if (mapDefaultLng < -180 || mapDefaultLng > 180) {
      setError('Map default longitude must be between -180 and 180');
      return;
    }

    // Validate map default zoom
    if (mapDefaultZoom < 1 || mapDefaultZoom > 18) {
      setError('Map default zoom must be between 1 and 18');
      return;
    }

    try {
      setSaving(true);
      setError(null);
      setSuccess(null);
      const updated = await updateSettings({
        internalOrderRadiusKm: internalOrderRadius,
        externalOrderMinRadiusKm: externalOrderMinRadius,
        externalOrderMaxRadiusKm: externalOrderMaxRadius,
        mapDefaultCenter: {
          lat: mapDefaultLat,
          lng: mapDefaultLng,
        },
        mapDefaultZoom: mapDefaultZoom,
        vehicleTypes: vehicleTypes,
        commissionPercentage: commissionPercentage,
        maxAllowedBalance: maxAllowedBalance,
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
      <div className="space-y-6 page-transition">
        <h1 className="text-3xl font-bold text-slate-900">Settings</h1>
        <div className="card p-12">
          <div className="flex items-center justify-center">
            <div className="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
            <span className="ml-3 text-slate-600">Loading settings...</span>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 page-transition">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Settings</h1>
        <p className="mt-2 text-slate-600">Configure system-wide settings and preferences</p>
      </div>

      {error && (
        <div className="card bg-red-50 border-red-200 p-4">
          <p className="text-red-800">{error}</p>
        </div>
      )}

      {success && (
        <div className="card bg-green-50 border-green-200 p-4">
          <p className="text-green-800">{success}</p>
        </div>
      )}

      <div className="card p-6">
        <h2 className="text-xl font-semibold mb-4 text-slate-900">Order Distance Settings</h2>
        <div className="space-y-6">
          <div>
            <label
              htmlFor="internalOrderRadius"
              className="block text-sm font-medium text-slate-700 mb-2"
            >
              Internal Orders Radius (kilometers)
            </label>
            <p className="text-sm text-slate-600 mb-3">
              Internal orders will be sent to drivers within this distance from the
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
                className="input w-32"
              />
              <span className="text-sm text-slate-600">km</span>
            </div>
            {settings && (
              <p className="mt-2 text-xs text-slate-500">
                Current value: {settings.internalOrderRadiusKm} km
              </p>
            )}
          </div>

          <div>
            <label
              htmlFor="externalOrderRadius"
              className="block text-sm font-medium text-slate-700 mb-2"
            >
              External Orders Radius Range (kilometers)
            </label>
            <p className="text-sm text-slate-600 mb-3">
              External orders will be sent to drivers within this distance range from the
              customer's location. Only drivers between min and max radius will receive notifications. Range: 1-100 km
            </p>
            <div className="flex items-center space-x-4">
              <div className="flex items-center space-x-2">
                <label htmlFor="externalOrderMinRadius" className="text-sm text-slate-600">
                  Min:
                </label>
                <input
                  type="number"
                  id="externalOrderMinRadius"
                  min="1"
                  max="100"
                  step="0.1"
                  value={externalOrderMinRadius}
                  onChange={(e) => setExternalOrderMinRadius(Number(e.target.value))}
                  className="input w-24"
                />
                <span className="text-sm text-slate-600">km</span>
              </div>
              <span className="text-slate-400">-</span>
              <div className="flex items-center space-x-2">
                <label htmlFor="externalOrderMaxRadius" className="text-sm text-slate-600">
                  Max:
                </label>
                <input
                  type="number"
                  id="externalOrderMaxRadius"
                  min="1"
                  max="100"
                  step="0.1"
                  value={externalOrderMaxRadius}
                  onChange={(e) => setExternalOrderMaxRadius(Number(e.target.value))}
                  className="input w-24"
                />
                <span className="text-sm text-slate-600">km</span>
              </div>
            </div>
            {settings && (
              <p className="mt-2 text-xs text-slate-500">
                Current range: {settings.externalOrderMinRadiusKm} - {settings.externalOrderMaxRadiusKm} km
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="card p-6">
        <h2 className="text-xl font-semibold mb-4 text-slate-900">Map Default Configuration</h2>
        <div className="space-y-6">
          <p className="text-sm text-slate-600 mb-4">
            Configure the default center point and zoom level for the map view. The map will open at these coordinates when first loaded.
          </p>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label
                htmlFor="mapDefaultLat"
                className="block text-sm font-medium text-slate-700 mb-2"
              >
                Map Default Center - Latitude *
              </label>
              <input
                type="number"
                id="mapDefaultLat"
                min="-90"
                max="90"
                step="0.000001"
                value={mapDefaultLat}
                onChange={(e) => setMapDefaultLat(Number(e.target.value))}
                className="input"
                placeholder="32.462502185826004"
              />
              <p className="mt-1 text-xs text-slate-500">Range: -90 to 90</p>
            </div>

            <div>
              <label
                htmlFor="mapDefaultLng"
                className="block text-sm font-medium text-slate-700 mb-2"
              >
                Map Default Center - Longitude *
              </label>
              <input
                type="number"
                id="mapDefaultLng"
                min="-180"
                max="180"
                step="0.000001"
                value={mapDefaultLng}
                onChange={(e) => setMapDefaultLng(Number(e.target.value))}
                className="input"
                placeholder="35.29172911766705"
              />
              <p className="mt-1 text-xs text-slate-500">Range: -180 to 180</p>
            </div>
          </div>

          <div>
            <label
              htmlFor="mapDefaultZoom"
              className="block text-sm font-medium text-slate-700 mb-2"
            >
              Map Default Zoom Level *
            </label>
            <p className="text-sm text-slate-600 mb-3">
              The initial zoom level when the map loads. Higher values zoom in more. Range: 1-18
            </p>
            <div className="flex items-center space-x-4">
              <input
                type="number"
                id="mapDefaultZoom"
                min="1"
                max="18"
                step="1"
                value={mapDefaultZoom}
                onChange={(e) => setMapDefaultZoom(Number(e.target.value))}
                className="input w-32"
              />
              <span className="text-sm text-slate-600">Level</span>
            </div>
            {settings && settings.mapDefaultZoom !== undefined && (
              <p className="mt-2 text-xs text-slate-500">
                Current value: {settings.mapDefaultZoom}
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="card p-6">
        <h2 className="text-xl font-semibold mb-4 text-slate-900">Vehicle Types Configuration</h2>
        <div className="space-y-6">
          <p className="text-sm text-slate-600 mb-4">
            Configure vehicle types availability and pricing. Users will only see enabled vehicle types.
          </p>
          {(['bike', 'car', 'cargo'] as const).map((type) => (
            <div key={type} className="card p-4">
              <div className="flex items-center justify-between mb-4">
                <div>
                  <h3 className="text-lg font-semibold capitalize text-slate-900">{type}</h3>
                  <p className="text-sm text-slate-500">
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
                    className="w-5 h-5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="ml-2 text-sm font-medium text-slate-700">
                    {vehicleTypes[type].enabled ? 'Enabled' : 'Disabled'}
                  </span>
                </label>
              </div>
              <div>
                <label
                  htmlFor={`${type}-price`}
                  className="block text-sm font-medium text-slate-700 mb-2"
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
                    className="input w-32"
                  />
                  <span className="text-sm text-slate-600">ILS</span>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="card p-6">
        <h2 className="text-xl font-semibold mb-4 text-slate-900">Driver Commission Settings</h2>
        <div className="space-y-6">
          <p className="text-sm text-slate-600 mb-4">
            Configure commission percentage and maximum allowed balance for drivers. When a driver's balance reaches the maximum, their account will be automatically suspended.
          </p>

          <div>
            <label
              htmlFor="commissionPercentage"
              className="block text-sm font-medium text-slate-700 mb-2"
            >
              Commission Percentage (%)
            </label>
            <p className="text-sm text-slate-600 mb-3">
              The percentage of delivery revenue that drivers owe to the admin. Range: 0-100%
            </p>
            <div className="flex items-center space-x-4">
              <input
                type="number"
                id="commissionPercentage"
                min="0"
                max="100"
                step="0.1"
                value={commissionPercentage}
                onChange={(e) => setCommissionPercentage(Number(e.target.value))}
                className="input w-32"
              />
              <span className="text-sm text-slate-600">%</span>
            </div>
            {settings && (
              <p className="mt-2 text-xs text-slate-500">
                Current value: {settings.commissionPercentage || 2}%
              </p>
            )}
          </div>

          <div>
            <label
              htmlFor="maxAllowedBalance"
              className="block text-sm font-medium text-slate-700 mb-2"
            >
              Maximum Allowed Balance (NIS)
            </label>
            <p className="text-sm text-slate-600 mb-3">
              The maximum balance a driver can accumulate before automatic account suspension. Range: 0+
            </p>
            <div className="flex items-center space-x-4">
              <input
                type="number"
                id="maxAllowedBalance"
                min="0"
                step="0.01"
                value={maxAllowedBalance}
                onChange={(e) => setMaxAllowedBalance(Number(e.target.value))}
                className="input w-32"
              />
              <span className="text-sm text-slate-600">NIS</span>
            </div>
            {settings && (
              <p className="mt-2 text-xs text-slate-500">
                Current value: {settings.maxAllowedBalance || 50} NIS
              </p>
            )}
          </div>
        </div>
      </div>

      <div className="card p-6">
        <h2 className="text-xl font-semibold mb-4 text-slate-900">System Information</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-slate-700">
              Map Provider
            </label>
            <p className="mt-1 text-sm text-slate-600">
              Using OpenStreetMap (free, no API key required)
            </p>
          </div>
        </div>
      </div>

      <div className="card p-6">
        <div className="flex justify-end">
          <button
            onClick={handleSave}
            disabled={
              saving ||
              internalOrderRadius < 1 ||
              internalOrderRadius > 100 ||
              externalOrderMinRadius < 1 ||
              externalOrderMinRadius > 100 ||
              externalOrderMaxRadius < 1 ||
              externalOrderMaxRadius > 100 ||
              externalOrderMinRadius > externalOrderMaxRadius ||
              mapDefaultLat < -90 ||
              mapDefaultLat > 90 ||
              mapDefaultLng < -180 ||
              mapDefaultLng > 180 ||
              mapDefaultZoom < 1 ||
              mapDefaultZoom > 18 ||
              commissionPercentage < 0 ||
              commissionPercentage > 100 ||
              maxAllowedBalance < 0
            }
            className="btn-primary px-8 py-3 text-lg disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {saving ? 'Saving...' : 'Save All Settings'}
          </button>
        </div>
      </div>
    </div>
  );
};

export default Settings;
