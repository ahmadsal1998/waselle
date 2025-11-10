const Settings = () => {
  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">Settings</h1>

      <div className="bg-white shadow rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-4">System Configuration</h2>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Map Provider
            </label>
            <p className="mt-1 text-sm text-gray-500">
              Using OpenStreetMap (free, no API key required)
            </p>
          </div>
          <div>
            <label className="block text-sm font-medium text-gray-700">
              Notification Settings
            </label>
            <div className="mt-2 space-y-2">
              <label className="flex items-center">
                <input type="checkbox" className="rounded border-gray-300" />
                <span className="ml-2 text-sm text-gray-700">
                  Email notifications
                </span>
              </label>
              <label className="flex items-center">
                <input type="checkbox" className="rounded border-gray-300" />
                <span className="ml-2 text-sm text-gray-700">
                  Push notifications
                </span>
              </label>
            </div>
          </div>
          <button className="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-md">
            Save Settings
          </button>
        </div>
      </div>
    </div>
  );
};

export default Settings;
