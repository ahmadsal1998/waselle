/**
 * Normalizes phone numbers to the format: +9720XXXXXXXX
 * Handles various input formats:
ٍ * - +972593202026 -> +9720593202026 (removes leading zero after country code)
 * - +9720593202026 -> +9720593202026 (already correct)
 * - 972593202026 -> +9720593202026
 * - 0593202026 -> +9720593202026
 * 
 * IMPORTANT: This function ensures consistent normalization by:
 * 1. Removing any leading zero after the country code (972)
 * 2. Always adding the 0 after 972 if missing
 * 3. Ensuring the format is exactly +9720XXXXXXXX (13 digits total)
 */
export const normalizePhoneNumber = (phone: string | undefined | null): string | undefined => {
  if (!phone) {
    return undefined;
  }

  // Convert to string and remove all whitespace
  let normalized = String(phone).trim().replace(/\s+/g, '');

  // Remove all non-digit characters except leading +
  normalized = normalized.replace(/[^\d+]/g, '');

  // If it starts with +, remove it temporarily for processing
  const hasPlus = normalized.startsWith('+');
  if (hasPlus) {
    normalized = normalized.substring(1);
  }

  // Handle different formats
  // Case 1: Already in correct format +9720XXXXXXXX (13 digits starting with 9720)
  if (normalized.startsWith('9720') && normalized.length === 13) {
    return `+${normalized}`;
  }

  // Case 2: +972XXXXXXXX (12 digits starting with 972, missing the 0)
  // Example: 972593202026 -> should become 9720593202026
  if (normalized.startsWith('972') && normalized.length === 12) {
    // Insert 0 after 972: 972 + 0 + rest
    normalized = `9720${normalized.substring(3)}`;
    return `+${normalized}`;
  }

  // Case 2b: +9720XXXXXXXX but with extra digits (normalize to 13 digits)
  // Example: 9720593202026123 -> should become 9720593202026
  if (normalized.startsWith('9720') && normalized.length > 13) {
    normalized = normalized.substring(0, 13);
    return `+${normalized}`;
  }

  // Case 3: Starts with 0XXXXXXXX (local format, 10 digits)
  // Example: 0593202026 -> should become 9720593202026
  if (normalized.startsWith('0') && normalized.length === 10) {
    normalized = `972${normalized}`;
    return `+${normalized}`;
  }

  // Case 4: Just digits without country code (9 digits)
  // Example: 593202026 -> should become 9720593202026
  if (normalized.length === 9 && !normalized.startsWith('0')) {
    normalized = `9720${normalized}`;
    return `+${normalized}`;
  }

  // Case 5: Handle 972XXXXXXXX format (might have leading zero after 972)
  // This handles cases like 9720593202026 (already correct) or 972593202026 (needs 0)
  if (normalized.startsWith('972')) {
    const after972 = normalized.substring(3);
    // If it starts with 0, keep it; otherwise add 0
    if (after972.startsWith('0')) {
      // Already has 0, ensure it's exactly 13 digits total
      normalized = `972${after972}`;
      if (normalized.length > 13) {
        normalized = normalized.substring(0, 13);
      } else if (normalized.length < 13) {
        // Shouldn't happen, but pad if needed
        normalized = normalized.padEnd(13, '0');
      }
    } else {
      // Missing 0 after 972, add it
      normalized = `9720${after972}`;
      // Ensure it's exactly 13 digits
      if (normalized.length > 13) {
        normalized = normalized.substring(0, 13);
      } else if (normalized.length < 13) {
        normalized = normalized.padEnd(13, '0');
      }
    }
    return `+${normalized}`;
  }

  // Default: try to ensure it starts with +9720
  // If it starts with 0, prepend 972
  if (normalized.startsWith('0')) {
    normalized = `972${normalized}`;
  } else {
    // Otherwise, prepend 9720
    normalized = `9720${normalized}`;
  }

  // Ensure it's exactly 13 digits after country code
  if (normalized.length > 13) {
    normalized = normalized.substring(0, 13);
  } else if (normalized.length < 13) {
    // Pad with zeros if too short (shouldn't happen normally)
    normalized = normalized.padEnd(13, '0');
  }

  return `+${normalized}`;
};

/**
 * Splits a normalized phone number into country code and local number
 * @param phone - Normalized phone number (e.g., +9720593202026)
 * @returns Object with countryCode (e.g., "+972") and phone (e.g., "593202026")
 * 
 * Example:
 * - Input: "+9720593202026"
 * - Output: { countryCode: "+972", phone: "593202026" }
 */
export const splitPhoneNumber = (
  phone: string | undefined | null
): { countryCode: string; phone: string } | null => {
  if (!phone) {
    return null;
  }

  // First normalize the phone number
  const normalized = normalizePhoneNumber(phone);
  if (!normalized) {
    return null;
  }

  // Remove the + sign for processing
  const digits = normalized.replace(/^\+/, '');

  // For +9720XXXXXXXX format (13 digits)
  // Country code: +972
  // Local number: XXXXXXXXX (9 digits after 9720)
  if (digits.startsWith('9720') && digits.length === 13) {
    return {
      countryCode: '+972',
      phone: digits.substring(4), // Everything after "9720"
    };
  }

  // Fallback: try to extract +972 if present
  if (digits.startsWith('972')) {
    return {
      countryCode: '+972',
      phone: digits.substring(3), // Everything after "972"
    };
  }

  // If no country code found, default to +972
  return {
    countryCode: '+972',
    phone: digits,
  };
};

