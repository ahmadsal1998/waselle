import { useCitiesManager } from '@/store/cities/useCitiesManager';

const Cities = () => {
  const {
    citySearch,
    setCitySearch,
    showInactiveCities,
    setShowInactiveCities,
    citiesError,
    loadingCities,
    filteredCities,
    selectedCityId,
    setSelectedCityId,
    openCityModal,
    handleToggleCityStatus,
    handleDeleteCity,
    selectedCity,
    openVillageModal,
    villagesError,
    villageSearch,
    setVillageSearch,
    showInactiveVillages,
    setShowInactiveVillages,
    loadingVillages,
    filteredVillages,
    handleToggleVillageStatus,
    handleDeleteVillage,
    isCityModalOpen,
    closeCityModal,
    editingCity,
    cityForm,
    setCityForm,
    handleCitySubmit,
    isSavingCity,
    isVillageModalOpen,
    closeVillageModal,
    editingVillage,
    villageForm,
    setVillageForm,
    handleVillageSubmit,
    isSavingVillage,
  } = useCitiesManager();

return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Cities & Villages Management</h1>
          <p className="text-gray-600 mt-1">
            Manage Palestinian cities and their villages in one unified view.
          </p>
        </div>
        <div className="flex gap-3">
          <button
            onClick={() => openCityModal()}
            className="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-md shadow-sm transition"
          >
            + Add City
          </button>
          <button
            onClick={() => openVillageModal()}
            disabled={!selectedCityId}
            className="inline-flex items-center px-4 py-2 bg-green-600 hover:bg-green-700 text-white rounded-md shadow-sm transition disabled:opacity-60 disabled:cursor-not-allowed"
          >
            + Add Village
          </button>
        </div>
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        <section className="space-y-4">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex-1">
              <label className="block text-sm font-medium text-gray-700">Search Cities</label>
              <input
                type="text"
                value={citySearch}
                onChange={(event) => setCitySearch(event.target.value)}
                placeholder="Search by city name"
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            </div>
            <label className="flex items-center gap-2 text-sm text-gray-700">
              <input
                type="checkbox"
                checked={showInactiveCities}
                onChange={(event) => setShowInactiveCities(event.target.checked)}
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              Show inactive
            </label>
          </div>

          {citiesError && (
            <div className="bg-red-50 border border-red-100 text-red-600 px-4 py-3 rounded-md">
              {citiesError}
            </div>
          )}

          {loadingCities ? (
            <div className="bg-white shadow rounded-md p-6 text-center text-gray-500">
              Loading cities...
            </div>
          ) : filteredCities.length === 0 ? (
            <div className="bg-white shadow rounded-md p-6 text-center text-gray-500">
              No cities match your filters. Try adjusting the search or toggle inactive cities.
            </div>
          ) : (
            <div className="bg-white shadow rounded-lg overflow-hidden">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      City
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Villages
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredCities.map((city) => {
                    const isSelected = city._id === selectedCityId;
                    return (
                      <tr
                        key={city._id}
                        className={`cursor-pointer transition ${
                          isSelected ? 'bg-blue-50' : 'hover:bg-gray-50'
                        }`}
                        onClick={() => setSelectedCityId(city._id)}
                      >
                        <td className="px-6 py-4 whitespace-nowrap">
                          <div className="text-sm font-medium text-gray-900">{city.name}</div>
                          <div className="text-sm text-gray-500">
                            Villages: {city.villagesCount ?? 0}
                          </div>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap">
                          <span
                            className={`inline-flex px-3 py-1 rounded-full text-xs font-semibold ${
                              city.isActive
                                ? 'bg-green-100 text-green-800'
                                : 'bg-gray-100 text-gray-700'
                            }`}
                          >
                            {city.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-700">
                          {city.villagesCount ?? 0}
                        </td>
                        <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                          <button
                            onClick={(event) => {
                              event.stopPropagation();
                              openCityModal(city);
                            }}
                            className="text-blue-600 hover:text-blue-800"
                          >
                            Edit
                          </button>
                          <button
                            onClick={async (event) => {
                              event.stopPropagation();
                              await handleToggleCityStatus(city);
                            }}
                            className="text-yellow-600 hover:text-yellow-800"
                          >
                            {city.isActive ? 'Deactivate' : 'Activate'}
                          </button>
                          <button
                            onClick={async (event) => {
                              event.stopPropagation();
                              await handleDeleteCity(city);
                            }}
                            className="text-red-600 hover:text-red-800"
                          >
                            Delete
                          </button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </section>

        <section className="space-y-4">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex-1">
              <label className="block text-sm font-medium text-gray-700">
                {selectedCity ? `Villages in ${selectedCity.name}` : 'Village List'}
              </label>
              <input
                type="text"
                value={villageSearch}
                onChange={(event) => setVillageSearch(event.target.value)}
                placeholder="Search by village name"
                className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
              />
            </div>
            <label className="flex items-center gap-2 text-sm text-gray-700">
              <input
                type="checkbox"
                checked={showInactiveVillages}
                onChange={(event) => setShowInactiveVillages(event.target.checked)}
                className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              Show inactive
            </label>
          </div>

          {villagesError && (
            <div className="bg-red-50 border border-red-100 text-red-600 px-4 py-3 rounded-md">
              {villagesError}
            </div>
          )}

          {!selectedCityId ? (
            <div className="bg-white shadow rounded-md p-6 text-center text-gray-500">
              Select a city to view and manage its villages.
            </div>
          ) : loadingVillages ? (
            <div className="bg-white shadow rounded-md p-6 text-center text-gray-500">
              Loading villages...
            </div>
          ) : filteredVillages.length === 0 ? (
            <div className="bg-white shadow rounded-md p-6 text-center text-gray-500">
              No villages found for the selected city. Use the &ldquo;Add Village&rdquo; button to
              create one.
            </div>
          ) : (
            <div className="bg-white shadow rounded-lg overflow-hidden">
              <table className="min-w-full divide-y divide-gray-200">
                <thead className="bg-gray-50">
                  <tr>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Village
                    </th>
                    <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Status
                    </th>
                    <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wider">
                      Actions
                    </th>
                  </tr>
                </thead>
                <tbody className="bg-white divide-y divide-gray-200">
                  {filteredVillages.map((village) => (
                    <tr key={village._id}>
                      <td className="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">
                        {village.name}
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap">
                        <span
                          className={`inline-flex px-3 py-1 rounded-full text-xs font-semibold ${
                            village.isActive
                              ? 'bg-green-100 text-green-800'
                              : 'bg-gray-100 text-gray-700'
                          }`}
                        >
                          {village.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </td>
                      <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                        <button
                          onClick={() => openVillageModal(village)}
                          className="text-blue-600 hover:text-blue-800"
                        >
                          Edit
                        </button>
                        <button
                          onClick={async () => {
                            await handleToggleVillageStatus(village);
                          }}
                          className="text-yellow-600 hover:text-yellow-800"
                        >
                          {village.isActive ? 'Deactivate' : 'Activate'}
                        </button>
                        <button
                          onClick={async () => {
                            await handleDeleteVillage(village);
                          }}
                          className="text-red-600 hover:text-red-800"
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </section>
      </div>

      {isCityModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-2xl">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
              <h2 className="text-lg font-semibold text-gray-900">
                {editingCity ? 'Edit City' : 'Add City'}
              </h2>
              <button onClick={closeCityModal} className="text-gray-400 hover:text-gray-600">
                ✕
              </button>
            </div>
            <form onSubmit={handleCitySubmit} className="px-6 py-5 space-y-4 max-h-[80vh] overflow-y-auto">
              <div>
                <label htmlFor="cityName" className="block text-sm font-medium text-gray-700">
                  City Name
                </label>
                <input
                  id="cityName"
                  type="text"
                  value={cityForm.name}
                  onChange={(event) =>
                    setCityForm((prev) => ({ ...prev, name: event.target.value }))
                  }
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  placeholder="Enter city name"
                  autoFocus
                />
              </div>

              <div className="pt-4 border-t border-gray-200">
                <div className="flex items-center justify-between mb-3">
                  <h3 className="text-sm font-medium text-gray-900">Service Center Configuration</h3>
                  <label className="flex items-center gap-2 text-sm text-gray-700">
                    <input
                      type="checkbox"
                      checked={cityForm.serviceCenter !== null && cityForm.serviceCenter !== undefined}
                      onChange={(event) => {
                        if (event.target.checked) {
                          setCityForm((prev) => ({
                            ...prev,
                            serviceCenter: {
                              center: { lat: 0, lng: 0 },
                              serviceAreaRadiusKm: 20,
                              internalOrderRadiusKm: 5,
                              externalOrderRadiusKm: 10,
                            },
                          }));
                        } else {
                          setCityForm((prev) => ({ ...prev, serviceCenter: null }));
                        }
                      }}
                      className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                    Enable Service Center
                  </label>
                </div>

                {cityForm.serviceCenter && (
                  <div className="space-y-4 mt-4">
                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label htmlFor="serviceCenterLat" className="block text-xs font-medium text-gray-700 mb-1">
                          Center Latitude
                        </label>
                        <input
                          id="serviceCenterLat"
                          type="number"
                          step="0.000001"
                          min="-90"
                          max="90"
                          value={cityForm.serviceCenter.center.lat}
                          onChange={(event) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    center: {
                                      ...prev.serviceCenter.center,
                                      lat: Number(event.target.value),
                                    },
                                  }
                                : undefined,
                            }))
                          }
                          className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                          placeholder="0.0"
                        />
                      </div>
                      <div>
                        <label htmlFor="serviceCenterLng" className="block text-xs font-medium text-gray-700 mb-1">
                          Center Longitude
                        </label>
                        <input
                          id="serviceCenterLng"
                          type="number"
                          step="0.000001"
                          min="-180"
                          max="180"
                          value={cityForm.serviceCenter.center.lng}
                          onChange={(event) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    center: {
                                      ...prev.serviceCenter.center,
                                      lng: Number(event.target.value),
                                    },
                                  }
                                : undefined,
                            }))
                          }
                          className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                          placeholder="0.0"
                        />
                      </div>
                    </div>

                    <div>
                      <label htmlFor="serviceAreaRadius" className="block text-xs font-medium text-gray-700 mb-1">
                        Service Area Radius (km)
                      </label>
                      <input
                        id="serviceAreaRadius"
                        type="number"
                        step="0.1"
                        min="1"
                        max="500"
                        value={cityForm.serviceCenter.serviceAreaRadiusKm}
                        onChange={(event) =>
                          setCityForm((prev) => ({
                            ...prev,
                            serviceCenter: prev.serviceCenter
                              ? {
                                  ...prev.serviceCenter,
                                  serviceAreaRadiusKm: Number(event.target.value),
                                }
                              : undefined,
                          }))
                        }
                        className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                        placeholder="20"
                      />
                      <p className="mt-1 text-xs text-gray-500">Coverage radius for this city (1-500 km)</p>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                      <div>
                        <label htmlFor="internalOrderRadius" className="block text-xs font-medium text-gray-700 mb-1">
                          Internal Orders Radius (km)
                        </label>
                        <input
                          id="internalOrderRadius"
                          type="number"
                          step="0.1"
                          min="1"
                          max="100"
                          value={cityForm.serviceCenter.internalOrderRadiusKm}
                          onChange={(event) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    internalOrderRadiusKm: Number(event.target.value),
                                  }
                                : undefined,
                            }))
                          }
                          className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                          placeholder="5"
                        />
                        <p className="mt-1 text-xs text-gray-500">For orders inside city</p>
                      </div>
                      <div>
                        <label htmlFor="externalOrderRadius" className="block text-xs font-medium text-gray-700 mb-1">
                          External Orders Radius (km)
                        </label>
                        <input
                          id="externalOrderRadius"
                          type="number"
                          step="0.1"
                          min="1"
                          max="100"
                          value={cityForm.serviceCenter.externalOrderRadiusKm}
                          onChange={(event) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    externalOrderRadiusKm: Number(event.target.value),
                                  }
                                : undefined,
                            }))
                          }
                          className="block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 text-sm"
                          placeholder="10"
                        />
                        <p className="mt-1 text-xs text-gray-500">For orders outside city</p>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              <div className="flex justify-end space-x-3 pt-2 border-t border-gray-200">
                <button
                  type="button"
                  onClick={closeCityModal}
                  className="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSavingCity}
                  className="px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 disabled:opacity-60"
                >
                  {isSavingCity ? 'Saving...' : editingCity ? 'Save Changes' : 'Create City'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {isVillageModalOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-40 flex items-center justify-center z-50 px-4">
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
              <div>
                <h2 className="text-lg font-semibold text-gray-900">
                  {editingVillage ? 'Edit Village' : 'Add Village'}
                </h2>
                {selectedCity && (
                  <p className="text-sm text-gray-500">City: {selectedCity.name}</p>
                )}
              </div>
              <button onClick={closeVillageModal} className="text-gray-400 hover:text-gray-600">
                ✕
              </button>
            </div>
            <form onSubmit={handleVillageSubmit} className="px-6 py-5 space-y-4">
              <div>
                <label htmlFor="villageName" className="block text-sm font-medium text-gray-700">
                  Village Name
                </label>
                <input
                  id="villageName"
                  type="text"
                  value={villageForm.name}
                  onChange={(event) =>
                    setVillageForm((prev) => ({ ...prev, name: event.target.value }))
                  }
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                  placeholder="Enter village name"
                  autoFocus
                />
              </div>
              {villagesError && (
                <div className="text-sm text-red-600">{villagesError}</div>
              )}
              <div className="flex justify-end space-x-3 pt-2">
                <button
                  type="button"
                  onClick={closeVillageModal}
                  className="px-4 py-2 bg-gray-100 text-gray-700 rounded-md hover:bg-gray-200"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={isSavingVillage}
                  className="px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 disabled:opacity-60"
                >
                  {isSavingVillage ? 'Saving...' : editingVillage ? 'Save Changes' : 'Create Village'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default Cities;

