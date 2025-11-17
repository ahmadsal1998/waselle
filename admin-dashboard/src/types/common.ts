export interface LocationPoint {
  lat: number;
  lng: number;
  address?: string;
}

export interface ApiListResponse<T> {
  [key: string]: T[];
}
