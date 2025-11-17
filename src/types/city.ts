export interface City {
  _id: string;
  name: string;
  isActive: boolean;
  villagesCount?: number;
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


