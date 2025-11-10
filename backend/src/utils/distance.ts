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
