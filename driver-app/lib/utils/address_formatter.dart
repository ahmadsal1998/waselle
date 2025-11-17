/// Utility functions for formatting addresses
class AddressFormatter {
  /// Format address from separate components (City-Village-StreetDetails)
  /// Falls back to old senderAddress format if components are not available
  static String formatAddress(Map<String, dynamic> order) {
    // Try to get new format components
    final city = order['senderCity']?.toString().trim();
    final village = order['senderVillage']?.toString().trim();
    final streetDetails = order['senderStreetDetails']?.toString().trim();

    // Build address from separate components if all are available
    if (city != null && city.isNotEmpty &&
        village != null && village.isNotEmpty &&
        streetDetails != null && streetDetails.isNotEmpty) {
      return '$city-$village-$streetDetails';
    }

    // Fall back to old senderAddress format if available
    final oldAddress = order['senderAddress']?.toString().trim();
    if (oldAddress != null && oldAddress.isNotEmpty) {
      return oldAddress;
    }

    // If no address is available, return N/A or empty string
    return 'N/A';
  }

  /// Get customer name from order (from populated customerId or senderName)
  static String getCustomerName(Map<String, dynamic> order) {
    // Try to get from populated customer data
    final customer = order['customerId'];
    if (customer is Map<String, dynamic>) {
      final name = customer['name']?.toString().trim();
      if (name != null && name.isNotEmpty) {
        return name;
      }
    }

    // Fall back to senderName
    final senderName = order['senderName']?.toString().trim();
    if (senderName != null && senderName.isNotEmpty) {
      return senderName;
    }

    return 'N/A';
  }

  /// Get customer phone from order (from populated customerId or senderPhoneNumber)
  static String getCustomerPhone(Map<String, dynamic> order) {
    // Try to get from populated customer data
    final customer = order['customerId'];
    if (customer is Map<String, dynamic>) {
      // Try phone first (from User model), then phoneNumber (legacy)
      final phone = customer['phone']?.toString().trim();
      if (phone != null && phone.isNotEmpty) {
        // Include country code if available
        final countryCode = customer['countryCode']?.toString().trim();
        if (countryCode != null && countryCode.isNotEmpty) {
          return '$countryCode$phone';
        }
        return phone;
      }
      
      // Fallback to phoneNumber field
      final phoneNumber = customer['phoneNumber']?.toString().trim();
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        return phoneNumber;
      }
    }

    // Fall back to senderPhoneNumber from order
    final senderPhone = order['senderPhoneNumber']?.toString().trim();
    if (senderPhone != null && senderPhone.isNotEmpty) {
      return senderPhone;
    }

    return 'N/A';
  }
}

