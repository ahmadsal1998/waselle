import { useState, useEffect } from 'react';
import { useCitiesManager } from '@/store/cities/useCitiesManager';
import {
  Plus,
  Search,
  Edit,
  Trash2,
  Power,
  X,
  Check,
  MapPin,
  Building2,
  AlertCircle,
} from 'lucide-react';

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

  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [formErrors, setFormErrors] = useState<{ city?: string; village?: string }>({});

  // Show success message and clear after 3 seconds
  useEffect(() => {
    if (successMessage) {
      const timer = setTimeout(() => setSuccessMessage(null), 3000);
      return () => clearTimeout(timer);
    }
  }, [successMessage]);

  // Enhanced submit handlers with success messages
  const handleCitySubmitWithFeedback = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFormErrors({});

    if (!cityForm.name.trim()) {
      setFormErrors({ city: 'City name is required' });
      return;
    }

    try {
      await handleCitySubmit(e);
      setSuccessMessage(editingCity ? 'City updated successfully!' : 'City created successfully!');
      setFormErrors({});
    } catch (error) {
      setFormErrors({ city: 'Failed to save city. Please try again.' });
    }
  };

  const handleVillageSubmitWithFeedback = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    setFormErrors({});

    if (!villageForm.name.trim()) {
      setFormErrors({ village: 'Village name is required' });
      return;
    }

    try {
      await handleVillageSubmit(e);
      setSuccessMessage(editingVillage ? 'Village updated successfully!' : 'Village created successfully!');
      setFormErrors({});
    } catch (error) {
      setFormErrors({ village: 'Failed to save village. Please try again.' });
    }
  };

  return (
    <div className="space-y-6 page-transition">
      {/* Header */}
      <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 className="text-3xl font-bold text-slate-900">Cities & Villages Management</h1>
          <p className="text-slate-600 mt-2">
            Manage Palestinian cities and their villages in one unified view.
          </p>
        </div>
        <div className="flex flex-wrap gap-3">
          <button
            onClick={() => {
              openCityModal();
              setFormErrors({});
              setSuccessMessage(null);
            }}
            className="btn-primary flex items-center gap-2"
          >
            <Plus className="w-5 h-5" />
            Add City
          </button>
          <button
            onClick={() => {
              openVillageModal();
              setFormErrors({});
              setSuccessMessage(null);
            }}
            disabled={!selectedCityId}
            className="btn-primary flex items-center gap-2 bg-green-600 hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Plus className="w-5 h-5" />
            Add Village
          </button>
        </div>
      </div>

      {/* Success Message */}
      {successMessage && (
        <div className="card bg-green-50 border-green-200 p-4 flex items-center gap-3">
          <Check className="w-5 h-5 text-green-600 flex-shrink-0" />
          <p className="text-green-800 font-medium">{successMessage}</p>
          <button
            onClick={() => setSuccessMessage(null)}
            className="ml-auto text-green-600 hover:text-green-800"
          >
            <X className="w-4 h-4" />
          </button>
        </div>
      )}

      {/* Main Content Grid */}
      <div className="grid gap-6 lg:grid-cols-2">
        {/* Cities Section */}
        <section className="card p-6">
          <div className="flex items-center gap-2 mb-6">
            <Building2 className="w-6 h-6 text-blue-600" />
            <h2 className="text-xl font-semibold text-slate-900">Cities</h2>
          </div>

          {/* Search and Filter */}
          <div className="space-y-4 mb-6">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
              <input
                type="text"
                value={citySearch}
                onChange={(e) => setCitySearch(e.target.value)}
                placeholder="Search by city name..."
                className="input pl-10"
              />
            </div>
            <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
              <input
                type="checkbox"
                checked={showInactiveCities}
                onChange={(e) => setShowInactiveCities(e.target.checked)}
                className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
              />
              <span>Show inactive cities</span>
            </label>
          </div>

          {/* Error Message */}
          {citiesError && (
            <div className="mb-4 card bg-red-50 border-red-200 p-4 flex items-center gap-3">
              <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0" />
              <p className="text-red-800 text-sm">{citiesError}</p>
            </div>
          )}

          {/* Cities List */}
          {loadingCities ? (
            <div className="card p-12 text-center">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
              <p className="mt-4 text-slate-600">Loading cities...</p>
            </div>
          ) : filteredCities.length === 0 ? (
            <div className="card p-12 text-center text-slate-500">
              <MapPin className="w-12 h-12 mx-auto mb-3 text-slate-300" />
              <p>No cities match your filters.</p>
              <p className="text-sm mt-1">Try adjusting the search or toggle inactive cities.</p>
            </div>
          ) : (
            <div className="space-y-2">
              {filteredCities.map((city) => {
                const isSelected = city._id === selectedCityId;
                return (
                  <div
                    key={city._id}
                    onClick={() => setSelectedCityId(city._id)}
                    className={`
                      card p-4 cursor-pointer transition-all duration-200
                      ${isSelected ? 'ring-2 ring-blue-500 bg-blue-50' : 'hover:shadow-md'}
                    `}
                  >
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <div className="flex items-center gap-2 mb-2">
                          <h3 className="text-lg font-semibold text-slate-900">{city.name}</h3>
                          {city.nameEn && (
                            <span className="text-sm text-slate-500">({city.nameEn})</span>
                          )}
                          <span
                            className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                              city.isActive
                                ? 'bg-green-100 text-green-800'
                                : 'bg-slate-100 text-slate-700'
                            }`}
                          >
                            {city.isActive ? 'Active' : 'Inactive'}
                          </span>
                        </div>
                        <p className="text-sm text-slate-600">
                          {city.villagesCount ?? 0} village{city.villagesCount !== 1 ? 's' : ''}
                        </p>
                      </div>
                      <div className="flex items-center gap-2 ml-4">
                        <button
                          onClick={(e) => {
                            e.stopPropagation();
                            openCityModal(city);
                            setFormErrors({});
                          }}
                          className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Edit City"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={async (e) => {
                            e.stopPropagation();
                            await handleToggleCityStatus(city);
                          }}
                          className={`p-2 rounded-lg transition-colors ${
                            city.isActive
                              ? 'text-amber-600 hover:bg-amber-50'
                              : 'text-green-600 hover:bg-green-50'
                          }`}
                          title={city.isActive ? 'Deactivate' : 'Activate'}
                        >
                          <Power className="w-4 h-4" />
                        </button>
                        <button
                          onClick={async (e) => {
                            e.stopPropagation();
                            if (confirm(`Are you sure you want to delete "${city.name}"?`)) {
                              await handleDeleteCity(city);
                            }
                          }}
                          className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Delete City"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </section>

        {/* Villages Section */}
        <section className="card p-6">
          <div className="flex items-center gap-2 mb-6">
            <MapPin className="w-6 h-6 text-green-600" />
            <h2 className="text-xl font-semibold text-slate-900">
              {selectedCity ? `Villages in ${selectedCity.name}` : 'Villages'}
            </h2>
          </div>

          {/* Search and Filter */}
          {selectedCityId && (
            <div className="space-y-4 mb-6">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-400" />
                <input
                  type="text"
                  value={villageSearch}
                  onChange={(e) => setVillageSearch(e.target.value)}
                  placeholder="Search by village name..."
                  className="input pl-10"
                />
              </div>
              <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                <input
                  type="checkbox"
                  checked={showInactiveVillages}
                  onChange={(e) => setShowInactiveVillages(e.target.checked)}
                  className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                />
                <span>Show inactive villages</span>
              </label>
            </div>
          )}

          {/* Error Message */}
          {villagesError && (
            <div className="mb-4 card bg-red-50 border-red-200 p-4 flex items-center gap-3">
              <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0" />
              <p className="text-red-800 text-sm">{villagesError}</p>
            </div>
          )}

          {/* Villages List */}
          {!selectedCityId ? (
            <div className="card p-12 text-center text-slate-500">
              <MapPin className="w-12 h-12 mx-auto mb-3 text-slate-300" />
              <p>Select a city to view and manage its villages.</p>
            </div>
          ) : loadingVillages ? (
            <div className="card p-12 text-center">
              <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-green-600"></div>
              <p className="mt-4 text-slate-600">Loading villages...</p>
            </div>
          ) : filteredVillages.length === 0 ? (
            <div className="card p-12 text-center text-slate-500">
              <MapPin className="w-12 h-12 mx-auto mb-3 text-slate-300" />
              <p>No villages found for the selected city.</p>
              <p className="text-sm mt-1">Use the "Add Village" button to create one.</p>
            </div>
          ) : (
            <div className="space-y-2">
              {filteredVillages.map((village) => (
                <div
                  key={village._id}
                  className="card p-4 hover:shadow-md transition-all duration-200"
                >
                  <div className="flex items-center justify-between">
                    <div className="flex-1">
                      <div className="flex items-center gap-2">
                        <h3 className="text-lg font-semibold text-slate-900">{village.name}</h3>
                        {village.nameEn && (
                          <span className="text-sm text-slate-500">({village.nameEn})</span>
                        )}
                        <span
                          className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${
                            village.isActive
                              ? 'bg-green-100 text-green-800'
                              : 'bg-slate-100 text-slate-700'
                          }`}
                        >
                          {village.isActive ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                    </div>
                    <div className="flex items-center gap-2 ml-4">
                      <button
                        onClick={() => {
                          openVillageModal(village);
                          setFormErrors({});
                        }}
                        className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                        title="Edit Village"
                      >
                        <Edit className="w-4 h-4" />
                      </button>
                      <button
                        onClick={async () => {
                          await handleToggleVillageStatus(village);
                        }}
                        className={`p-2 rounded-lg transition-colors ${
                          village.isActive
                            ? 'text-amber-600 hover:bg-amber-50'
                            : 'text-green-600 hover:bg-green-50'
                        }`}
                        title={village.isActive ? 'Deactivate' : 'Activate'}
                      >
                        <Power className="w-4 h-4" />
                      </button>
                      <button
                        onClick={async () => {
                          if (confirm(`Are you sure you want to delete "${village.name}"?`)) {
                            await handleDeleteVillage(village);
                          }
                        }}
                        className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                        title="Delete Village"
                      >
                        <Trash2 className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </section>
      </div>

      {/* City Modal */}
      {isCityModalOpen && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
            <div className="flex items-center justify-between p-6 border-b border-slate-200 bg-slate-50">
              <div className="flex items-center gap-3">
                <Building2 className="w-6 h-6 text-blue-600" />
                <h2 className="text-xl font-semibold text-slate-900">
                  {editingCity ? 'Edit City' : 'Add New City'}
                </h2>
              </div>
              <button
                onClick={() => {
                  closeCityModal();
                  setFormErrors({});
                }}
                className="p-2 hover:bg-slate-200 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleCitySubmitWithFeedback} className="flex-1 overflow-y-auto p-6 space-y-6">
              {/* City Name */}
              <div>
                <label htmlFor="cityName" className="block text-sm font-medium text-slate-700 mb-2">
                  City Name (Arabic) *
                </label>
                <input
                  id="cityName"
                  type="text"
                  value={cityForm.name}
                  onChange={(e) => {
                    setCityForm((prev) => ({ ...prev, name: e.target.value }));
                    if (formErrors.city) setFormErrors({});
                  }}
                  className={`input ${formErrors.city ? 'border-red-300 focus:ring-red-500' : ''}`}
                  placeholder="Enter city name in Arabic (e.g., جنين)"
                  autoFocus
                />
                {formErrors.city && (
                  <p className="mt-1 text-sm text-red-600 flex items-center gap-1">
                    <AlertCircle className="w-4 h-4" />
                    {formErrors.city}
                  </p>
                )}
              </div>

              {/* City Name English */}
              <div>
                <label htmlFor="cityNameEn" className="block text-sm font-medium text-slate-700 mb-2">
                  City Name (English)
                  <span className="text-xs text-slate-500 ml-2 font-normal">
                    (Optional - for reverse geocoding matching)
                  </span>
                </label>
                <input
                  id="cityNameEn"
                  type="text"
                  value={cityForm.nameEn || ''}
                  onChange={(e) => {
                    setCityForm((prev) => ({ ...prev, nameEn: e.target.value }));
                  }}
                  className="input"
                  placeholder="Enter city name in English (e.g., Jenin)"
                />
                <p className="mt-1 text-xs text-slate-500">
                  This helps match cities when reverse geocoding returns English names.
                </p>
              </div>

              {/* Service Center Configuration */}
              <div className="pt-4 border-t border-slate-200">
                <div className="flex items-center justify-between mb-4">
                  <h3 className="text-sm font-semibold text-slate-900">Service Center Configuration</h3>
                  <label className="flex items-center gap-2 text-sm text-slate-700 cursor-pointer">
                    <input
                      type="checkbox"
                      checked={cityForm.serviceCenter !== null && cityForm.serviceCenter !== undefined}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setCityForm((prev) => ({
                            ...prev,
                            serviceCenter: {
                              center: { lat: 0, lng: 0 },
                              internalOrderRadiusKm: 2,
                              externalOrderMinRadiusKm: 10,
                              externalOrderMaxRadiusKm: 15,
                            },
                          }));
                        } else {
                          setCityForm((prev) => ({ ...prev, serviceCenter: null }));
                        }
                      }}
                      className="rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                    />
                    <span>Enable Service Center</span>
                  </label>
                </div>

                {cityForm.serviceCenter && (
                  <div className="space-y-4 mt-4 bg-slate-50 p-4 rounded-lg">
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label htmlFor="serviceCenterLat" className="block text-xs font-medium text-slate-700 mb-1">
                          Center Latitude
                        </label>
                        <input
                          id="serviceCenterLat"
                          type="number"
                          step="0.000001"
                          min="-90"
                          max="90"
                          value={cityForm.serviceCenter.center.lat}
                          onChange={(e) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    center: {
                                      ...prev.serviceCenter.center,
                                      lat: Number(e.target.value),
                                    },
                                  }
                                : undefined,
                            }))
                          }
                          className="input text-sm"
                          placeholder="0.0"
                        />
                      </div>
                      <div>
                        <label htmlFor="serviceCenterLng" className="block text-xs font-medium text-slate-700 mb-1">
                          Center Longitude
                        </label>
                        <input
                          id="serviceCenterLng"
                          type="number"
                          step="0.000001"
                          min="-180"
                          max="180"
                          value={cityForm.serviceCenter.center.lng}
                          onChange={(e) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    center: {
                                      ...prev.serviceCenter.center,
                                      lng: Number(e.target.value),
                                    },
                                  }
                                : undefined,
                            }))
                          }
                          className="input text-sm"
                          placeholder="0.0"
                        />
                      </div>
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                      <div>
                        <label htmlFor="internalOrderRadius" className="block text-xs font-medium text-slate-700 mb-1">
                          Internal Orders Radius (km)
                        </label>
                        <input
                          id="internalOrderRadius"
                          type="number"
                          step="0.1"
                          min="1"
                          max="100"
                          value={cityForm.serviceCenter.internalOrderRadiusKm}
                          onChange={(e) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    internalOrderRadiusKm: Number(e.target.value),
                                  }
                                : undefined,
                            }))
                          }
                          className="input text-sm"
                          placeholder="5"
                        />
                        <p className="mt-1 text-xs text-slate-500">For orders inside city</p>
                      </div>
                      <div>
                        <label htmlFor="externalOrderMinRadius" className="block text-xs font-medium text-slate-700 mb-1">
                          External Orders Min Radius (km)
                        </label>
                        <input
                          id="externalOrderMinRadius"
                          type="number"
                          step="0.1"
                          min="1"
                          max="100"
                          value={cityForm.serviceCenter.externalOrderMinRadiusKm}
                          onChange={(e) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    externalOrderMinRadiusKm: Number(e.target.value),
                                  }
                                : undefined,
                            }))
                          }
                          className="input text-sm"
                          placeholder="10"
                        />
                        <p className="mt-1 text-xs text-slate-500">Minimum distance for external orders</p>
                      </div>
                      <div>
                        <label htmlFor="externalOrderMaxRadius" className="block text-xs font-medium text-slate-700 mb-1">
                          External Orders Max Radius (km)
                        </label>
                        <input
                          id="externalOrderMaxRadius"
                          type="number"
                          step="0.1"
                          min="1"
                          max="100"
                          value={cityForm.serviceCenter.externalOrderMaxRadiusKm}
                          onChange={(e) =>
                            setCityForm((prev) => ({
                              ...prev,
                              serviceCenter: prev.serviceCenter
                                ? {
                                    ...prev.serviceCenter,
                                    externalOrderMaxRadiusKm: Number(e.target.value),
                                  }
                                : undefined,
                            }))
                          }
                          className="input text-sm"
                          placeholder="15"
                        />
                        <p className="mt-1 text-xs text-slate-500">Maximum distance for external orders</p>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Form Actions */}
              <div className="flex justify-end gap-3 pt-4 border-t border-slate-200">
                <button
                  type="button"
                  onClick={() => {
                    closeCityModal();
                    setFormErrors({});
                  }}
                  className="btn-secondary"
                  disabled={isSavingCity}
                >
                  Cancel
                </button>
                <button type="submit" className="btn-primary" disabled={isSavingCity}>
                  {isSavingCity ? 'Saving...' : editingCity ? 'Save Changes' : 'Create City'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Village Modal */}
      {isVillageModalOpen && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-md">
            <div className="flex items-center justify-between p-6 border-b border-slate-200 bg-slate-50">
              <div>
                <div className="flex items-center gap-3 mb-1">
                  <MapPin className="w-6 h-6 text-green-600" />
                  <h2 className="text-xl font-semibold text-slate-900">
                    {editingVillage ? 'Edit Village' : 'Add New Village'}
                  </h2>
                </div>
                {selectedCity && (
                  <p className="text-sm text-slate-600 ml-9">City: {selectedCity.name}</p>
                )}
              </div>
              <button
                onClick={() => {
                  closeVillageModal();
                  setFormErrors({});
                }}
                className="p-2 hover:bg-slate-200 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleVillageSubmitWithFeedback} className="p-6 space-y-4">
              <div>
                <label htmlFor="villageName" className="block text-sm font-medium text-slate-700 mb-2">
                  Village Name (Arabic) *
                </label>
                <input
                  id="villageName"
                  type="text"
                  value={villageForm.name}
                  onChange={(e) => {
                    setVillageForm((prev) => ({ ...prev, name: e.target.value }));
                    if (formErrors.village) setFormErrors({});
                  }}
                  className={`input ${formErrors.village ? 'border-red-300 focus:ring-red-500' : ''}`}
                  placeholder="Enter village name in Arabic (e.g., فقوعة)"
                  autoFocus
                />
                {formErrors.village && (
                  <p className="mt-1 text-sm text-red-600 flex items-center gap-1">
                    <AlertCircle className="w-4 h-4" />
                    {formErrors.village}
                  </p>
                )}
              </div>

              {/* Village Name English */}
              <div>
                <label htmlFor="villageNameEn" className="block text-sm font-medium text-slate-700 mb-2">
                  Village Name (English)
                  <span className="text-xs text-slate-500 ml-2 font-normal">
                    (Optional - for reverse geocoding matching)
                  </span>
                </label>
                <input
                  id="villageNameEn"
                  type="text"
                  value={villageForm.nameEn || ''}
                  onChange={(e) => {
                    setVillageForm((prev) => ({ ...prev, nameEn: e.target.value }));
                  }}
                  className="input"
                  placeholder="Enter village name in English (e.g., Faqqu'a)"
                />
                <p className="mt-1 text-xs text-slate-500">
                  This helps match villages when reverse geocoding returns English names like "Faqqu'a".
                </p>
              </div>
              <div className="flex justify-end gap-3 pt-4 border-t border-slate-200">
                <button
                  type="button"
                  onClick={() => {
                    closeVillageModal();
                    setFormErrors({});
                  }}
                  className="btn-secondary"
                  disabled={isSavingVillage}
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="btn-primary bg-green-600 hover:bg-green-700"
                  disabled={isSavingVillage}
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
