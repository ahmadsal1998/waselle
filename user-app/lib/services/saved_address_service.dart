import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_address.dart';

class SavedAddressService {
  static const String _key = 'saved_addresses';

  /// Get all saved addresses
  static Future<List<SavedAddress>> getSavedAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = prefs.getString(_key);
      
      if (addressesJson == null || addressesJson.isEmpty) {
        return [];
      }

      final List<dynamic> addressesList = json.decode(addressesJson);
      return addressesList
          .map((json) => SavedAddress.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save a new address
  static Future<bool> saveAddress(SavedAddress address) async {
    try {
      final addresses = await getSavedAddresses();
      addresses.add(address);
      return await _saveAddresses(addresses);
    } catch (e) {
      return false;
    }
  }

  /// Update an existing address
  static Future<bool> updateAddress(SavedAddress address) async {
    try {
      final addresses = await getSavedAddresses();
      final index = addresses.indexWhere((a) => a.id == address.id);
      
      if (index == -1) {
        return false;
      }

      addresses[index] = address;
      return await _saveAddresses(addresses);
    } catch (e) {
      return false;
    }
  }

  /// Delete an address
  static Future<bool> deleteAddress(String addressId) async {
    try {
      final addresses = await getSavedAddresses();
      addresses.removeWhere((a) => a.id == addressId);
      return await _saveAddresses(addresses);
    } catch (e) {
      return false;
    }
  }

  /// Get a specific address by ID
  static Future<SavedAddress?> getAddressById(String addressId) async {
    try {
      final addresses = await getSavedAddresses();
      return addresses.firstWhere(
        (a) => a.id == addressId,
        orElse: () => throw Exception('Address not found'),
      );
    } catch (e) {
      return null;
    }
  }

  /// Save all addresses to SharedPreferences
  static Future<bool> _saveAddresses(List<SavedAddress> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final addressesJson = json.encode(
        addresses.map((a) => a.toJson()).toList(),
      );
      return await prefs.setString(_key, addressesJson);
    } catch (e) {
      return false;
    }
  }

  /// Generate a unique ID for a new address
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

