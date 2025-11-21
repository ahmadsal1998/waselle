import { apiClient } from './apiClient';
import type { City, Village } from '@/types';

interface CityPayload {
  name?: string;
  nameEn?: string;
  isActive?: boolean;
  serviceCenter?: {
    center?: {
      lat: number;
      lng: number;
    };
    internalOrderRadiusKm?: number;
    externalOrderMinRadiusKm?: number;
    externalOrderMaxRadiusKm?: number;
  } | null;
}

interface VillagePayload {
  name?: string;
  nameEn?: string;
  isActive?: boolean;
}

export const getCities = async () => {
  const { data } = await apiClient.get<{ cities: City[] }>('/cities');
  return data.cities ?? [];
};

export const createCity = async (payload: { name: string; nameEn?: string }) => {
  const { data } = await apiClient.post<{ city: City }>('/cities', payload);
  return data.city;
};

export const updateCity = async (cityId: string, payload: CityPayload) => {
  const { data } = await apiClient.patch<{ city: City; villagesDeactivated?: boolean }>(
    `/cities/${cityId}`,
    payload
  );
  return data;
};

export const deleteCity = async (cityId: string) => {
  await apiClient.delete(`/cities/${cityId}`);
};

export const getVillages = async (cityId: string) => {
  const { data } = await apiClient.get<{ villages: Village[] }>('/villages', {
    params: { cityId },
  });
  return data.villages ?? [];
};

export const createVillage = async (payload: { cityId: string; name: string; nameEn?: string }) => {
  const { data } = await apiClient.post<{ village: Village }>('/villages', payload);
  return data.village;
};

export const updateVillage = async (villageId: string, payload: VillagePayload) => {
  const { data } = await apiClient.patch<{ village: Village }>(`/villages/${villageId}`, payload);
  return data.village;
};

export const deleteVillage = async (villageId: string) => {
  await apiClient.delete(`/villages/${villageId}`);
};
