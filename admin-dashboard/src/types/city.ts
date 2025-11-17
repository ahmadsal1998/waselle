export interface City {
  _id: string;
  name: string;
  isActive: boolean;
  villagesCount?: number;
  serviceCenter?: {
    center: {
      lat: number;
      lng: number;
    };
    serviceAreaRadiusKm: number;
    internalOrderRadiusKm: number;
    externalOrderRadiusKm: number;
  };
  createdAt?: string;
  updatedAt?: string;
}

export interface Village {
  _id: string;
  cityId: string;
  name: string;
  isActive: boolean;
  createdAt?: string;
  updatedAt?: string;
}
