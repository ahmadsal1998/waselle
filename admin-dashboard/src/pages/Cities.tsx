import { useCallback, useEffect, useMemo, useState } from 'react';
import { api } from '../config/api';

interface City {
  _id: string;
  name: string;
  isActive: boolean;
  villagesCount?: number;
}

interface Village {
  _id: string;
  cityId: string;
  name: string;
  isActive: boolean;
}

interface CityFormState {
  name: string;
}

interface VillageFormState {
  name: string;
}

const initialCityForm: CityFormState = { name: '' };
const initialVillageForm: VillageFormState = { name: '' };

const Cities = () => {
  const [cities, setCities] = useState<City[]>([]);
  const [selectedCityId, setSelectedCityId] = useState<string>('');
  const [villages, setVillages] = useState<Village[]>([]);

  const [loadingCities, setLoadingCities] = useState(true);
  const [loadingVillages, setLoadingVillages] = useState(false);
  const [citiesError, setCitiesError] = useState<string | null>(null);
  const [villagesError, setVillagesError] = useState<string | null>(null);

  const [citySearch, setCitySearch] = useState('');
  const [villageSearch, setVillageSearch] = useState('');
  const [showInactiveCities, setShowInactiveCities] = useState(false);
  const [showInactiveVillages, setShowInactiveVillages] = useState(false);

  const [isCityModalOpen, setIsCityModalOpen] = useState(false);
  const [cityForm, setCityForm] = useState(initialCityForm);
  const [editingCity, setEditingCity] = useState<City | null>(null);
  const [isSavingCity, setIsSavingCity] = useState(false);

  const [isVillageModalOpen, setIsVillageModalOpen] = useState(false);
  const [villageForm, setVillageForm] = useState(initialVillageForm);
  const [editingVillage, setEditingVillage] = useState<Village | null>(null);
  const [isSavingVillage, setIsSavingVillage] = useState(false);

  const selectedCity = useMemo(
    () => cities.find((city) => city._id === selectedCityId) ?? null,
    [cities, selectedCityId]
  );

  const fetchCities = useCallback(async (options: { maintainSelection?: boolean } = {}) => {
    const { maintainSelection = true } = options;
    setLoadingCities(true);
    setCitiesError(null);
    try {
      const response = await api.get('/cities');
      const fetchedCities: City[] = response.data.cities ?? [];
      setCities(fetchedCities);
      setSelectedCityId((previousSelected) => {
        if (
          maintainSelection &&
          previousSelected &&
          fetchedCities.some((city) => city._id === previousSelected)
        ) {
          return previousSelected;
        }
        const firstActive = fetchedCities.find((city) => city.isActive);
        return firstActive?._id ?? fetchedCities[0]?._id ?? '';
      });
    } catch (err: any) {
      console.error('Failed to fetch cities:', err);
      setCitiesError(err.response?.data?.message ?? 'Failed to fetch cities');
      setCities([]);
      setSelectedCityId('');
    } finally {
      setLoadingCities(false);
    }
  }, []);

  const fetchVillages = useCallback(
    async (cityId: string) => {
      if (!cityId) return;
      setLoadingVillages(true);
      setVillagesError(null);
      try {
        const response = await api.get('/villages', {
          params: { cityId },
        });
        setVillages(response.data.villages ?? []);
      } catch (err: any) {
        console.error('Failed to fetch villages:', err);
        setVillagesError(err.response?.data?.message ?? 'Failed to fetch villages');
        setVillages([]);
      } finally {
        setLoadingVillages(false);
      }
    },
    []
  );

  useEffect(() => {
    void fetchCities();
  }, [fetchCities]);

  useEffect(() => {
    if (!selectedCityId) {
      setVillages([]);
      setVillagesError(null);
      return;
    }
    void fetchVillages(selectedCityId);
  }, [selectedCityId, fetchVillages]);

  useEffect(() => {
    if (!showInactiveCities && selectedCity && !selectedCity.isActive) {
      const nextActive = cities.find((city) => city.isActive && city._id !== selectedCity._id);
      setSelectedCityId(nextActive ? nextActive._id : '');
    }
  }, [showInactiveCities, selectedCity, cities]);

  const filteredCities = useMemo(() => {
    const normalizedQuery = citySearch.trim().toLowerCase();
    return [...cities]
      .filter((city) => (showInactiveCities ? true : city.isActive))
      .filter((city) =>
        normalizedQuery ? city.name.toLowerCase().includes(normalizedQuery) : true
      )
      .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));
  }, [cities, citySearch, showInactiveCities]);

  const filteredVillages = useMemo(() => {
    const normalizedQuery = villageSearch.trim().toLowerCase();
    return [...villages]
      .filter((village) => (showInactiveVillages ? true : village.isActive))
      .filter((village) =>
        normalizedQuery ? village.name.toLowerCase().includes(normalizedQuery) : true
      )
      .sort((a, b) => a.name.localeCompare(b.name, undefined, { sensitivity: 'base' }));
  }, [villages, villageSearch, showInactiveVillages]);

  const openCityModal = (city?: City) => {
    if (city) {
      setEditingCity(city);
      setCityForm({ name: city.name });
    } else {
      setEditingCity(null);
      setCityForm(initialCityForm);
    }
    setIsCityModalOpen(true);
  };

  const closeCityModal = () => {
    if (isSavingCity) return;
    setIsCityModalOpen(false);
    setCityForm(initialCityForm);
    setEditingCity(null);
  };

  const handleCitySubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    const trimmedName = cityForm.name.trim();
    if (!trimmedName) {
      setCitiesError('City name is required');
      return;
    }

    setIsSavingCity(true);
    setCitiesError(null);

    try {
      if (editingCity) {
        const response = await api.patch(`/cities/${editingCity._id}`, {
          name: trimmedName,
        });
        const updatedCity: City = response.data.city;
        setCities((prev) =>
          prev.map((city) => (city._id === updatedCity._id ? updatedCity : city))
        );
      } else {
        const response = await api.post('/cities', { name: trimmedName });
        const newCity: City = response.data.city;
        setCities((prev) => [...prev, newCity]);
        setSelectedCityId(newCity._id);
      }
      closeCityModal();
      await fetchCities();
    } catch (err: any) {
      console.error('Failed to save city:', err);
      setCitiesError(err.response?.data?.message ?? 'Failed to save city');
    } finally {
      setIsSavingCity(false);
    }
  };

  const handleToggleCityStatus = async (city: City) => {
    try {
      const response = await api.patch(`/cities/${city._id}`, {
        isActive: !city.isActive,
      });
      const updatedCity: City = response.data.city;
      setCities((prev) =>
        prev.map((item) => (item._id === updatedCity._id ? updatedCity : item))
      );
      if (updatedCity._id === selectedCityId) {
        await fetchVillages(updatedCity._id);
      }
      if (response.data.villagesDeactivated && !showInactiveVillages) {
        setVillages((prev) => prev.filter((village) => village.isActive));
      }
      await fetchCities();
      if (response.data.villagesDeactivated) {
        window.alert(
          'City deactivated. All associated villages were automatically marked as inactive.'
        );
      }
    } catch (err: any) {
      console.error('Failed to update city status:', err);
      window.alert(err.response?.data?.message ?? 'Failed to update city status.');
    }
  };

  const handleDeleteCity = async (city: City) => {
    const confirmed = window.confirm(
      `Delete ${city.name}? This will remove the city and all related villages.`
    );
    if (!confirmed) return;

    try {
      await api.delete(`/cities/${city._id}`);
      await fetchCities({ maintainSelection: false });
    } catch (err: any) {
      console.error('Failed to delete city:', err);
      window.alert(err.response?.data?.message ?? 'Failed to delete city.');
    }
  };

  const openVillageModal = (village?: Village) => {
    if (!selectedCityId) {
      window.alert('Please select a city first.');
      return;
    }

    if (village) {
      setEditingVillage(village);
      setVillageForm({ name: village.name });
    } else {
      setEditingVillage(null);
      setVillageForm(initialVillageForm);
    }
    setIsVillageModalOpen(true);
  };

  const closeVillageModal = () => {
    if (isSavingVillage) return;
    setIsVillageModalOpen(false);
    setVillageForm(initialVillageForm);
    setEditingVillage(null);
    setVillagesError(null);
  };

  const handleVillageSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (!selectedCityId) {
      setVillagesError('Please select a city first.');
      return;
    }

    const trimmedName = villageForm.name.trim();
    if (!trimmedName) {
      setVillagesError('Village name is required.');
      return;
    }

    setIsSavingVillage(true);
    setVillagesError(null);

    try {
      if (editingVillage) {
        await api.patch(`/villages/${editingVillage._id}`, {
          name: trimmedName,
        });
      } else {
        await api.post('/villages', {
          cityId: selectedCityId,
          name: trimmedName,
        });
      }

      await Promise.all([fetchVillages(selectedCityId), fetchCities()]);
      closeVillageModal();
    } catch (err: any) {
      console.error('Failed to save village:', err);
      setVillagesError(err.response?.data?.message ?? 'Failed to save village.');
    } finally {
      setIsSavingVillage(false);
    }
  };

  const handleToggleVillageStatus = async (village: Village) => {
    try {
      await api.patch(`/villages/${village._id}`, {
        isActive: !village.isActive,
      });
      await Promise.all([fetchVillages(village.cityId), fetchCities()]);
    } catch (err: any) {
      console.error('Failed to update village status:', err);
      window.alert(err.response?.data?.message ?? 'Failed to update village status.');
    }
  };

  const handleDeleteVillage = async (village: Village) => {
    const confirmed = window.confirm(`Delete village ${village.name}?`);
    if (!confirmed) return;

    try {
      await api.delete(`/villages/${village._id}`);
      await Promise.all([fetchVillages(village.cityId), fetchCities()]);
    } catch (err: any) {
      console.error('Failed to delete village:', err);
      window.alert(err.response?.data?.message ?? 'Failed to delete village.');
    }
  };

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
          <div className="bg-white rounded-lg shadow-xl w-full max-w-md">
            <div className="px-6 py-4 border-b border-gray-100 flex justify-between items-center">
              <h2 className="text-lg font-semibold text-gray-900">
                {editingCity ? 'Edit City' : 'Add City'}
              </h2>
              <button onClick={closeCityModal} className="text-gray-400 hover:text-gray-600">
                ✕
              </button>
            </div>
            <form onSubmit={handleCitySubmit} className="px-6 py-5 space-y-4">
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
              <div className="flex justify-end space-x-3 pt-2">
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

