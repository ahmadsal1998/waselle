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
 * Determines if a location is within the service area (internal) or outside (external)
 * @param location The location to check
 * @param serviceAreaCenter The center point of the service area
 * @param serviceAreaRadiusKm The radius of the service area in kilometers
 * @returns true if internal (within service area), false if external
 */
export const isInternalOrder = (
  location: Location,
  serviceAreaCenter: Location,
  serviceAreaRadiusKm: number
): boolean => {
  const distanceFromCenter = calculateDistance(location, serviceAreaCenter);
  return distanceFromCenter <= serviceAreaRadiusKm;
};

/**
 * City service center configuration
 */
export interface CityServiceCenter {
  cityId: string;
  cityName: string;
  center: Location;
  serviceAreaRadiusKm: number;
  internalOrderRadiusKm: number;
  externalOrderRadiusKm: number;
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
      serviceAreaRadiusKm: number;
      internalOrderRadiusKm: number;
      externalOrderRadiusKm: number;
    };
  }>
): CityServiceCenter | null => {
  // Find the city whose service area contains this location
  for (const city of citiesWithServiceCenters) {
    if (!city.serviceCenter || !city.serviceCenter.center) {
      continue;
    }

    const distanceFromCenter = calculateDistance(
      location,
      city.serviceCenter.center
    );

    // If location is within the city's service area radius, this is the city
    if (distanceFromCenter <= city.serviceCenter.serviceAreaRadiusKm) {
      return {
        cityId: city._id.toString(),
        cityName: city.name,
        center: city.serviceCenter.center,
        serviceAreaRadiusKm: city.serviceCenter.serviceAreaRadiusKm,
        internalOrderRadiusKm: city.serviceCenter.internalOrderRadiusKm,
        externalOrderRadiusKm: city.serviceCenter.externalOrderRadiusKm,
      };
    }
  }

  return null;
};
