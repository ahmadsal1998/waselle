const STATIC_PRICING: Record<'bike' | 'car', number> = {
  bike: 10,
  car: 15,
};

interface EstimateParams {
  vehicleType: 'car' | 'bike';
  distanceKm?: number | null;
}

export const calculateEstimatedPrice = ({
  vehicleType,
  distanceKm,
}: EstimateParams): number => {
  const basePrice = STATIC_PRICING[vehicleType];

  if (basePrice === undefined) {
    throw new Error(`Unsupported vehicle type: ${vehicleType}`);
  }

  if (distanceKm && distanceKm > 0) {
    // Placeholder for future distance-based calculation.
    // Currently returns static price per requirements.
    return basePrice;
  }

  return basePrice;
};

