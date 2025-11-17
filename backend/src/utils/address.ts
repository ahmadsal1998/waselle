/**
 * Normalizes address format to: City-Area/Village-ExtraDetails
 * Converts comma-separated addresses to hyphen-separated format
 */
export const normalizeAddress = (address: string | undefined | null): string => {
  if (!address || typeof address !== 'string') {
    return '';
  }

  const trimmed = address.trim();
  if (!trimmed) {
    return '';
  }

  // If already in hyphen format and properly formatted, return as is
  if (trimmed.includes('-') && !trimmed.includes(',')) {
    // Already in correct format (City-Area-Village-ExtraDetails)
    return trimmed;
  }

  // Convert comma-separated to hyphen-separated
  // Handle both "City, Area, Details" and "City,Area,Details" formats
  const normalized = trimmed
    .replace(/,\s+/g, '-') // Replace ", " with "-"
    .replace(/,/g, '-')     // Replace remaining "," with "-"
    .replace(/\s*-\s*/g, '-') // Normalize spaces around hyphens
    .replace(/-+/g, '-')   // Replace multiple hyphens with single hyphen
    .replace(/^-|-$/g, ''); // Remove leading/trailing hyphens

  return normalized;
};

