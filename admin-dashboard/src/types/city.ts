export interface City {
  _id: string;
  name: string;
  nameEn?: string; // English name for reverse geocoding matching
  isActive: boolean;
  villagesCount?: number;
  serviceCenter?: {
    center: {
      lat: number;
      lng: number;
    };
    internalOrderRadiusKm: number;
    externalOrderMinRadiusKm: number;
    externalOrderMaxRadiusKm: number;
  };
  createdAt?: string;
  updatedAt?: string;
}

export interface Village {
  _id: string;
  cityId: string;
  name: string;
  nameEn?: string; // English name for reverse geocoding matching
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}
