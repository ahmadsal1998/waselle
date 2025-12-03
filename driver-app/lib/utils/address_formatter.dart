import 'package:flutter/material.dart';
import 'package:delivery_driver_app/l10n/app_localizations.dart';
import '../services/osm_geocoding_service.dart';

/// Utility functions for formatting addresses
class AddressFormatter {
  /// Format address from separate components (City-Village-StreetDetails)
  /// Falls back to old senderAddress format if components are not available
  /// This is a synchronous version for backward compatibility
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

  /// Format sender/pickup address with language awareness using OSM reverse geocoding
  /// Tries OSM geocoding first if coordinates are available, then falls back to formatAddress
  static Future<String> formatSenderAddress(
    Map<String, dynamic> order, {
    BuildContext? context,
  }) async {
    // Try to get from pickup location using OSM reverse geocoding
    final pickup = order['pickupLocation'];
    if (pickup is Map<String, dynamic> && context != null) {
      final lat = pickup['lat'];
      final lng = pickup['lng'];
      final storedAddress = pickup['address']?.toString().trim();
      
      // Use OSM reverse geocoding for language-aware location name
      if (lat != null && lng != null) {
        final latValue = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
        final lngValue = lng is num ? lng.toDouble() : double.tryParse(lng.toString());
        
        if (latValue != null && lngValue != null) {
          final locationName = await OSMGeocodingService.getLocationName(
            lat: latValue,
            lng: lngValue,
            storedAddress: storedAddress,
            context: context,
          );
          if (locationName != 'N/A') {
            return locationName;
          }
        }
      }
      
      // Fallback to stored address if geocoding fails
      if (storedAddress != null && storedAddress.isNotEmpty) {
        return storedAddress;
      }
    }

    // Fall back to formatAddress (synchronous version)
    return formatAddress(order);
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

  /// Format receiver/delivery address from separate components or dropoff location
  /// Uses OSM reverse geocoding for language-aware location names
  static Future<String> formatReceiverAddress(
    Map<String, dynamic> order, {
    BuildContext? context,
  }) async {
    // Try to get receiver address components (these are stored in Arabic)
    final receiverCity = order['receiverCity']?.toString().trim();
    final receiverVillage = order['receiverVillage']?.toString().trim();
    final receiverStreetDetails = order['receiverStreetDetails']?.toString().trim();

    // Build address from separate components if available
    if (receiverCity != null && receiverCity.isNotEmpty ||
        receiverVillage != null && receiverVillage.isNotEmpty ||
        receiverStreetDetails != null && receiverStreetDetails.isNotEmpty) {
      final addressParts = <String>[];
      if (receiverCity != null && receiverCity.isNotEmpty) addressParts.add(receiverCity);
      if (receiverVillage != null && receiverVillage.isNotEmpty) addressParts.add(receiverVillage);
      if (receiverStreetDetails != null && receiverStreetDetails.isNotEmpty) addressParts.add(receiverStreetDetails);
      if (addressParts.isNotEmpty) {
        return addressParts.join('-');
      }
    }

    // Try to get from dropoff location using OSM reverse geocoding
    final dropoff = order['dropoffLocation'];
    if (dropoff is Map<String, dynamic> && context != null) {
      final lat = dropoff['lat'];
      final lng = dropoff['lng'];
      final storedAddress = dropoff['address']?.toString().trim();
      
      // Use OSM reverse geocoding for language-aware location name
      if (lat != null && lng != null) {
        final latValue = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
        final lngValue = lng is num ? lng.toDouble() : double.tryParse(lng.toString());
        
        if (latValue != null && lngValue != null) {
          final locationName = await OSMGeocodingService.getLocationName(
            lat: latValue,
            lng: lngValue,
            storedAddress: storedAddress,
            context: context,
          );
          if (locationName != 'N/A') {
            return locationName;
          }
        }
      }
      
      // Fallback to stored address if geocoding fails
      if (storedAddress != null && storedAddress.isNotEmpty) {
        return storedAddress;
      }
    }

    // Fall back to receiverAddress format if available
    final receiverAddress = order['receiverAddress']?.toString().trim();
    if (receiverAddress != null && receiverAddress.isNotEmpty) {
      return receiverAddress;
    }

    return 'N/A';
  }

  /// Format pickup address with language awareness using OSM reverse geocoding
  static Future<String> formatPickupAddress(
    Map<String, dynamic> pickup, {
    BuildContext? context,
  }) async {
    if (pickup is Map<String, dynamic> && context != null) {
      final lat = pickup['lat'];
      final lng = pickup['lng'];
      final storedAddress = pickup['address']?.toString().trim();
      
      // Use OSM reverse geocoding for language-aware location name
      if (lat != null && lng != null) {
        final latValue = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
        final lngValue = lng is num ? lng.toDouble() : double.tryParse(lng.toString());
        
        if (latValue != null && lngValue != null) {
          final locationName = await OSMGeocodingService.getLocationName(
            lat: latValue,
            lng: lngValue,
            storedAddress: storedAddress,
            context: context,
          );
          if (locationName != 'N/A') {
            return locationName;
          }
        }
      }
      
      // Fallback to stored address if geocoding fails
      if (storedAddress != null && storedAddress.isNotEmpty) {
        return storedAddress;
      }
    }
    return 'N/A';
  }
}

