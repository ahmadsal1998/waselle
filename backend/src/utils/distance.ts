import { getDistance } from 'geolib';

export interface Location {
  lat: number;
  lng: number;
}

export const calculateDistance = (
  location1: Location,
  location2: Location
): number => {
  // Validate that both locations have valid lat and lng
  if (
    location1?.lat === undefined ||
    location1?.lng === undefined ||
    location2?.lat === undefined ||
    location2?.lng === undefined ||
    isNaN(location1.lat) ||
    isNaN(location1.lng) ||
    isNaN(location2.lat) ||
    isNaN(location2.lng)
  ) {
    throw new Error('Invalid location: lat and lng must be valid numbers');
  }

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
    .filter((driver) => {
      // Filter out drivers with invalid data
      if (!driver._id) return false;
      if (!driver.location || driver.location.lat === undefined || driver.location.lng === undefined) return false;
      if (targetLocation.lat === undefined || targetLocation.lng === undefined) return false;
      return true;
    })
    .map((driver) => {
      try {
        return {
          driverId: driver._id.toString(),
          distance: calculateDistance(driver.location, targetLocation),
        };
      } catch (error) {
        return null;
      }
    })
    .filter((item): item is { driverId: string; distance: number } => item !== null)
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

    // Skip cities without a valid _id
    if (!city._id) {
      continue;
    }

    // Validate location and city center have valid coordinates
    if (
      location?.lat === undefined ||
      location?.lng === undefined ||
      city.serviceCenter.center?.lat === undefined ||
      city.serviceCenter.center?.lng === undefined ||
      isNaN(location.lat) ||
      isNaN(location.lng) ||
      isNaN(city.serviceCenter.center.lat) ||
      isNaN(city.serviceCenter.center.lng)
    ) {
      continue;
    }

    let distanceFromCenter: number;
    try {
      distanceFromCenter = calculateDistance(
        location,
        city.serviceCenter.center
      );
    } catch (error) {
      continue; // Skip this city if distance calculation fails
    }

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
        cityId: city._id ? (typeof city._id === 'string' ? city._id : city._id.toString()) : 'unknown',
        cityName: city.name ? String(city.name) : 'unknown',
        center: city.serviceCenter.center,
        internalOrderRadiusKm: city.serviceCenter.internalOrderRadiusKm ?? 2,
        externalOrderMinRadiusKm,
        externalOrderMaxRadiusKm,
      };
    }
  }

  return nearestCity;
};
