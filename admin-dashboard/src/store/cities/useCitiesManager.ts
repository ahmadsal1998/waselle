import {
  useCallback,
  useEffect,
  useMemo,
  useState,
} from 'react';
import {
  createCity,
  createVillage,
  deleteCity,
  deleteVillage,
  getCities,
  getVillages,
  updateCity,
  updateVillage,
} from '@/services/cityService';
import type { City, Village } from '@/types';

interface CityFormState {
  name: string;
  nameEn?: string;
  serviceCenter?: {
    center: {
      lat: number;
      lng: number;
    };
    internalOrderRadiusKm: number;
    externalOrderMinRadiusKm: number;
    externalOrderMaxRadiusKm: number;
  } | null;
}

interface VillageFormState {
  name: string;
  nameEn?: string;
}

const initialCityForm: CityFormState = { name: '', nameEn: '' };
const initialVillageForm: VillageFormState = { name: '', nameEn: '' };

export const useCitiesManager = () => {
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

  const fetchCities = useCallback(
    async (options: { maintainSelection?: boolean } = {}) => {
      const { maintainSelection = true } = options;
      setLoadingCities(true);
      setCitiesError(null);
      try {
        const fetchedCities = await getCities();
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
      } catch (err) {
        console.error('Failed to fetch cities:', err);
        setCitiesError(err instanceof Error ? err.message : 'Failed to fetch cities');
        setCities([]);
        setSelectedCityId('');
      } finally {
        setLoadingCities(false);
      }
    },
    []
  );

  const fetchVillages = useCallback(async (cityId: string) => {
    if (!cityId) return;
    setLoadingVillages(true);
    setVillagesError(null);
    try {
      const fetchedVillages = await getVillages(cityId);
      setVillages(fetchedVillages);
    } catch (err) {
      console.error('Failed to fetch villages:', err);
      setVillagesError(err instanceof Error ? err.message : 'Failed to fetch villages');
      setVillages([]);
    } finally {
      setLoadingVillages(false);
    }
  }, []);

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
      const nextActive = cities.find(
        (city) => city.isActive && city._id !== selectedCity._id
      );
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
      setCityForm({
        name: city.name,
        nameEn: city.nameEn || '',
        serviceCenter: city.serviceCenter || null,
      });
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
        const { city, villagesDeactivated } = await updateCity(editingCity._id, {
          name: trimmedName,
          nameEn: cityForm.nameEn?.trim() || undefined,
          serviceCenter: cityForm.serviceCenter,
        });
        setCities((prev) =>
          prev.map((item) => (item._id === city._id ? city : item))
        );
        if (villagesDeactivated && !showInactiveVillages) {
          setVillages((prev) => prev.filter((village) => village.isActive));
        }
      } else {
        const newCity = await createCity({ 
          name: trimmedName,
          nameEn: cityForm.nameEn?.trim() || undefined,
        });
        setCities((prev) => [...prev, newCity]);
        setSelectedCityId(newCity._id);
      }
      closeCityModal();
      await fetchCities();
    } catch (err) {
      console.error('Failed to save city:', err);
      setCitiesError(
        err instanceof Error ? err.message : 'Failed to save city'
      );
    } finally {
      setIsSavingCity(false);
    }
  };

  const handleToggleCityStatus = async (city: City) => {
    try {
      const { city: updatedCity, villagesDeactivated } = await updateCity(city._id, {
        isActive: !city.isActive,
      });
      setCities((prev) =>
        prev.map((item) => (item._id === updatedCity._id ? updatedCity : item))
      );
      if (updatedCity._id === selectedCityId) {
        await fetchVillages(updatedCity._id);
      }
      if (villagesDeactivated && !showInactiveVillages) {
        setVillages((prev) => prev.filter((village) => village.isActive));
      }
      await fetchCities();
      if (villagesDeactivated) {
        window.alert(
          'City deactivated. All associated villages were automatically marked as inactive.'
        );
      }
    } catch (err) {
      console.error('Failed to update city status:', err);
      window.alert(
        err instanceof Error ? err.message : 'Failed to update city status.'
      );
    }
  };

  const handleDeleteCity = async (city: City) => {
    const confirmed = window.confirm(
      `Delete ${city.name}? This will remove the city and all related villages.`
    );
    if (!confirmed) return;

    try {
      await deleteCity(city._id);
      await fetchCities({ maintainSelection: false });
    } catch (err) {
      console.error('Failed to delete city:', err);
      window.alert(err instanceof Error ? err.message : 'Failed to delete city.');
    }
  };

  const openVillageModal = (village?: Village) => {
    if (!selectedCityId) {
      window.alert('Please select a city first.');
      return;
    }

    if (village) {
      setEditingVillage(village);
      setVillageForm({ 
        name: village.name,
        nameEn: village.nameEn || '',
      });
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
        await updateVillage(editingVillage._id, { 
          name: trimmedName,
          nameEn: villageForm.nameEn?.trim() || undefined,
        });
      } else {
        await createVillage({
          cityId: selectedCityId,
          name: trimmedName,
          nameEn: villageForm.nameEn?.trim() || undefined,
        });
      }

      await Promise.all([fetchVillages(selectedCityId), fetchCities()]);
      closeVillageModal();
    } catch (err) {
      console.error('Failed to save village:', err);
      setVillagesError(
        err instanceof Error ? err.message : 'Failed to save village.'
      );
    } finally {
      setIsSavingVillage(false);
    }
  };

  const handleToggleVillageStatus = async (village: Village) => {
    try {
      await updateVillage(village._id, { isActive: !village.isActive });
      await Promise.all([fetchVillages(village.cityId), fetchCities()]);
    } catch (err) {
      console.error('Failed to update village status:', err);
      window.alert(
        err instanceof Error ? err.message : 'Failed to update village status.'
      );
    }
  };

  const handleDeleteVillage = async (village: Village) => {
    const confirmed = window.confirm(`Delete village ${village.name}?`);
    if (!confirmed) return;

    try {
      await deleteVillage(village._id);
      await Promise.all([fetchVillages(village.cityId), fetchCities()]);
    } catch (err) {
      console.error('Failed to delete village:', err);
      window.alert(err instanceof Error ? err.message : 'Failed to delete village.');
    }
  };

  return {
    cities,
    selectedCityId,
    setSelectedCityId,
    selectedCity,
    villages,
    loadingCities,
    loadingVillages,
    citiesError,
    villagesError,
    citySearch,
    setCitySearch,
    villageSearch,
    setVillageSearch,
    showInactiveCities,
    setShowInactiveCities,
    showInactiveVillages,
    setShowInactiveVillages,
    filteredCities,
    filteredVillages,
    isCityModalOpen,
    openCityModal,
    closeCityModal,
    cityForm,
    setCityForm,
    editingCity,
    isSavingCity,
    handleCitySubmit,
    handleToggleCityStatus,
    handleDeleteCity,
    isVillageModalOpen,
    openVillageModal,
    closeVillageModal,
    villageForm,
    setVillageForm,
    editingVillage,
    isSavingVillage,
    handleVillageSubmit,
    handleToggleVillageStatus,
    handleDeleteVillage,
  };
};
