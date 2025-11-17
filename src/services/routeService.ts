import type { LatLngTuple } from 'leaflet';
import type { LocationPoint } from '../types';

const buildRouteUrl = (start: LocationPoint, end: LocationPoint) =>
  `https://router.project-osrm.org/route/v1/driving/${start.lng},${start.lat};${end.lng},${end.lat}?overview=full&geometries=geojson`;

export const getRoute = async (start: LocationPoint, end: LocationPoint): Promise<LatLngTuple[]> => {
  try {
    const response = await fetch(buildRouteUrl(start, end));
    const data = await response.json();

    if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
      const geometry = data.routes[0]?.geometry;
      if (geometry?.coordinates) {
        return geometry.coordinates.map((coord: number[]) => [
          coord[1],
          coord[0],
        ]) as LatLngTuple[];
      }
    }
  } catch (error) {
    console.error('Error fetching route:', error);
  }

  return [
    [start.lat, start.lng],
    [end.lat, end.lng],
  ];
};


