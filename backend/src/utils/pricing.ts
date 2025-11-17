import Settings from '../models/Settings';

interface EstimateParams {
  vehicleType: 'car' | 'bike' | 'cargo';
  distanceKm?: number | null;
}

export const calculateEstimatedPrice = async ({
  vehicleType,
  distanceKm,
}: EstimateParams): Promise<number> => {
  const settings = await Settings.getSettings();
  const vehicleConfig = settings.vehicleTypes[vehicleType];

  if (!vehicleConfig) {
    throw new Error(`Unsupported vehicle type: ${vehicleType}`);
  }

  if (!vehicleConfig.enabled) {
    throw new Error(`Vehicle type ${vehicleType} is not enabled`);
  }

  const basePrice = vehicleConfig.basePrice;

  if (distanceKm && distanceKm > 0) {
    // Placeholder for future distance-based calculation.
    // Currently returns base price per requirements.
    return basePrice;
  }

  return basePrice;
};

