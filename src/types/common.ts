export interface LocationPoint {
  lat: number;
  lng: number;
}

export interface ApiListResponse<T> {
  [key: string]: T[];
}


