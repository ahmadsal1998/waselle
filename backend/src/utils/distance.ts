import { getDistance } from 'geolib';

export interface Location {
  lat: number;
  lng: number;
}

export const calculateDistance = (
  location1: Location,
  location2: Location
): number => {
  // Returns distance in kilometers
  const distanceInMeters = getDistance(
    { latitude: location1.lat, longitude: location1.lng },
    { latitude: location2.lat, longitude: location2.lng }
  );
  return distanceInMeters / 1000; // Convert to kilometers
};

export const findNearestDrivers = (
  drivers: Array<{ location: Location; _id: string }>,
  targetLocation: Location,
  limit: number = 5
): Array<{ driverId: string; distance: number }> => {
  const driversWithDistance = drivers
    .map((driver) => ({
      driverId: driver._id.toString(),
      distance: calculateDistance(driver.location, targetLocation),
    }))
    .sort((a, b) => a.distance - b.distance)
    .slice(0, limit);

  return driversWithDistance;
};

/**
 * City service center configuration
 */
export interface CityServiceCenter {
  cityId: string;
  cityName: string;
  center: Location;
  internalOrderRadiusKm: number;
  externalOrderMinRadiusKm: number;
  externalOrderMaxRadiusKm: number;
}

/**
 * Finds which city a location belongs to based on service centers
 * @param location The location to check
 * @param citiesWithServiceCenters Array of cities with service center configurations
 * @returns The city service center configuration if found, null otherwise
 */
export const findCityForLocation = (
  location: Location,
  citiesWithServiceCenters: Array<{
    _id: any;
    name: string;
    serviceCenter: {
      center: Location;
      internalOrderRadiusKm: number;
      externalOrderMinRadiusKm?: number;
      externalOrderMaxRadiusKm?: number;
      externalOrderRadiusKm?: number; // For backward compatibility during migration
    };
  }>
): CityServiceCenter | null => {
  // Find the nearest city based on center point
  let nearestCity: CityServiceCenter | null = null;
  let minDistance = Infinity;

  for (const city of citiesWithServiceCenters) {
    if (!city.serviceCenter || !city.serviceCenter.center) {
      continue;
    }

    const distanceFromCenter = calculateDistance(
      location,
      city.serviceCenter.center
    );

    // Find the nearest city
    if (distanceFromCenter < minDistance) {
      minDistance = distanceFromCenter;
      
      // Migrate old externalOrderRadiusKm to min/max if needed
      let externalOrderMinRadiusKm = city.serviceCenter.externalOrderMinRadiusKm;
      let externalOrderMaxRadiusKm = city.serviceCenter.externalOrderMaxRadiusKm;
      
      if (externalOrderMinRadiusKm === undefined || externalOrderMaxRadiusKm === undefined) {
        const oldExternalRadius = city.serviceCenter.externalOrderRadiusKm || 10;
        externalOrderMinRadiusKm = oldExternalRadius;
        externalOrderMaxRadiusKm = oldExternalRadius + 5; // Default range: old value to old value + 5km
      }
      
      nearestCity = {
        cityId: city._id.toString(),
        cityName: city.name,
        center: city.serviceCenter.center,
        internalOrderRadiusKm: city.serviceCenter.internalOrderRadiusKm,
        externalOrderMinRadiusKm,
        externalOrderMaxRadiusKm,
      };
    }
  }

  return nearestCity;
};
