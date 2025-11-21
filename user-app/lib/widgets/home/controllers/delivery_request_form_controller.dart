import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../view_models/location_view_model.dart';
import '../../../../view_models/order_view_model.dart';
import '../../../../view_models/region_view_model.dart';
import '../../../../view_models/auth_view_model.dart';
import '../../../../repositories/api_service.dart';
import '../../../../services/socket_service.dart';
import '../../../../services/firebase_auth_service.dart';
import '../../../../services/saved_address_service.dart';
import '../../../../models/saved_address.dart';
import '../../../../utils/phone_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DeliveryRequestFormMessageType { info, success, error }

class DeliveryRequestFormMessage {
  final String message;
  final DeliveryRequestFormMessageType type;

  const DeliveryRequestFormMessage(
    this.message, {
    this.type = DeliveryRequestFormMessageType.info,
  });
}

class DeliveryRequestSubmitResult {
  final bool success;
  final String? message;

  const DeliveryRequestSubmitResult._(this.success, this.message);

  factory DeliveryRequestSubmitResult.success(String message) =>
      DeliveryRequestSubmitResult._(true, message);

  factory DeliveryRequestSubmitResult.failure([String? message]) =>
      DeliveryRequestSubmitResult._(false, message);
}

class DeliveryRequestFormController extends ChangeNotifier {
  DeliveryRequestFormController({required this.requestType});

  final String requestType;

  final formKey = GlobalKey<FormState>();
  final senderNameController = TextEditingController();
  final senderAddressController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final notesController = TextEditingController();
  final otpController = TextEditingController();

  String _selectedCountryCode = '+970'; // Default to +970

  final ValueNotifier<DeliveryRequestFormMessage?> messageNotifier =
      ValueNotifier<DeliveryRequestFormMessage?>(null);

  Timer? _debounceTimer;
  String _selectedVehicle = 'bike';
  String? _selectedOrderCategoryId;
  String? _selectedDeliveryType = 'internal'; // Default to internal delivery
  double? _estimatedPrice;
  bool _isEstimating = false;
  bool _isSubmitting = false;
  String? _selectedCityId;
  String? _selectedVillageId;
  String? _selectedSavedAddressId; // Selected saved address ID
  bool _useCurrentLocation = true; // Whether to use current location or saved address
  bool _isInitialized = false;
  bool _isDisposed = false;
  List<Map<String, dynamic>> _vehicleTypes = [];
  bool _isLoadingVehicleTypes = false;
  String? _vehicleTypesError;

  String get selectedVehicle => _selectedVehicle;
  String? get selectedOrderCategoryId => _selectedOrderCategoryId;
  String? get selectedDeliveryType => _selectedDeliveryType;
  double? get estimatedPrice => _estimatedPrice;
  bool get isEstimating => _isEstimating;
  bool get isSubmitting => _isSubmitting;
  String? get selectedCityId => _selectedCityId;
  String? get selectedVillageId => _selectedVillageId;
  String? get selectedSavedAddressId => _selectedSavedAddressId;
  bool get useCurrentLocation => _useCurrentLocation;
  List<Map<String, dynamic>> get vehicleTypes => _vehicleTypes;
  bool get isLoadingVehicleTypes => _isLoadingVehicleTypes;
  String? get vehicleTypesError => _vehicleTypesError;
  String get selectedCountryCode => _selectedCountryCode;
  
  bool _isSendingOTP = false;
  bool _isVerifyingOTP = false;
  bool _otpSent = false;
  String? _otpError;
  String? _firebaseVerificationId; // Store Firebase verification ID
  final FirebaseAuthService _firebaseAuth = FirebaseAuthService();
  
  // Localization callback for getting localized messages
  String? Function(String key)? _getLocalizedMessage;
  
  bool get isSendingOTP => _isSendingOTP;
  bool get isVerifyingOTP => _isVerifyingOTP;
  bool get otpSent => _otpSent;
  String? get otpError => _otpError;
  
  /// Set the localization callback function
  void setLocalizationCallback(String? Function(String key)? getLocalizedMessage) {
    _getLocalizedMessage = getLocalizedMessage;
  }

  void initialize({
    required LocationViewModel locationProvider,
    required RegionViewModel regionProvider,
    required OrderViewModel orderProvider,
    AuthViewModel? authProvider,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;
    
    // Set up socket listeners for order notifications (async, but don't await)
    _setupSocketListeners();
    
    // Ensure address field is empty for new orders
    // User must enter street address/details manually for each order
    senderAddressController.clear();

    // Auto-fill user data if authenticated (only on initialization)
    // This provides default values, but user can modify them
    // The form will always use the current input, not these defaults
    if (authProvider != null && authProvider.isAuthenticated && authProvider.user != null) {
      final user = authProvider.user!;
      
      // Auto-fill name (only if field is empty)
      if (user['name'] != null && senderNameController.text.isEmpty) {
        senderNameController.text = user['name'].toString();
      }
      
      // Auto-fill phone and country code (only if field is empty)
      if (user['phone'] != null && phoneNumberController.text.isEmpty) {
        final phone = user['phone'].toString();
        
        // Split the phone number into country code and local number
        // This handles formats like +972593202026 or +9720593202026
        final phoneParts = PhoneUtils.splitPhoneNumber(phone);
        
        if (phoneParts != null) {
          // Set the local phone number (without country code)
          phoneNumberController.text = phoneParts['phone'] ?? '';
          
          // Set the country code
          final countryCode = phoneParts['countryCode'] ?? '+972';
          if (_selectedCountryCode != countryCode) {
            _selectedCountryCode = countryCode;
          }
        } else {
          // Fallback: try to use countryCode from user if available
          final countryCode = user['countryCode']?.toString() ?? '+972';
          String phoneNumber = phone;
          
          // Try to remove country code if phone starts with it
          if (phone.startsWith(countryCode)) {
            phoneNumber = phone.substring(countryCode.length);
          } else if (phone.startsWith('+972')) {
            // Handle +972593202026 or +9720593202026 format
            phoneNumber = phone.substring(4); // Remove +972
            if (phoneNumber.isNotEmpty && phoneNumber[0] == '0') {
              phoneNumber = phoneNumber.substring(1); // Remove leading 0
            }
          }
          
          phoneNumberController.text = phoneNumber;
          if (_selectedCountryCode != countryCode) {
            _selectedCountryCode = countryCode;
          }
        }
      }
      
      // NOTE: Street address/details field is intentionally NOT auto-filled
      // User must enter this manually for each new order to ensure current/accurate information
      // This prevents old address data from being reused incorrectly
      
      _notifyListenersSafely();
    }

    if (locationProvider.currentPosition == null &&
        !locationProvider.isLoading) {
      locationProvider.getCurrentLocation();
    }

    regionProvider.loadCities();
    orderProvider.loadOrderCategories();
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    if (_isLoadingVehicleTypes) return;
    _isLoadingVehicleTypes = true;
    _vehicleTypesError = null;
    _notifyListenersSafely();

    try {
      final types = await ApiService.getVehicleTypes();
      if (_isDisposed) return;
      _vehicleTypes = types;
      // Auto-select first vehicle type if available
      if (_vehicleTypes.isNotEmpty && !_vehicleTypes.any((vt) => vt['id'] == _selectedVehicle)) {
        _selectedVehicle = _vehicleTypes.first['id'] as String? ?? 'bike';
      }
      _vehicleTypesError = null;
    } catch (e) {
      if (_isDisposed) return;
      _vehicleTypesError = e.toString();
      // Fallback to default vehicle types if API fails
      _vehicleTypes = [
        {'id': 'bike', 'label': 'Bike', 'enabled': true, 'basePrice': 5},
        {'id': 'car', 'label': 'Car', 'enabled': true, 'basePrice': 10},
      ];
    } finally {
      _isLoadingVehicleTypes = false;
      _notifyListenersSafely();
    }
  }

  void refreshLocation(LocationViewModel locationProvider) {
    if (locationProvider.isLoading) return;
    locationProvider.getCurrentLocation();
  }

  void syncOrderCategorySelection(OrderViewModel orderProvider) {
    if (_selectedOrderCategoryId == null) {
      return;
    }

    final exists = orderProvider.orderCategories.any(
      (category) => category.id == _selectedOrderCategoryId,
    );

    if (!exists) {
      _selectedOrderCategoryId = null;
      _notifyListenersSafely();
    }
  }

  void onVehicleSelected(
    String vehicleId, {
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
  }) {
    if (_selectedVehicle == vehicleId) return;
    _selectedVehicle = vehicleId;
    _notifyListenersSafely();
    scheduleEstimate(
      regionProvider: regionProvider,
      locationProvider: locationProvider,
      orderProvider: orderProvider,
    );
  }

  void onOrderCategoryChanged(
    String? categoryId, {
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
  }) {
    _selectedOrderCategoryId = categoryId;
    _notifyListenersSafely();
    scheduleEstimate(
      regionProvider: regionProvider,
      locationProvider: locationProvider,
      orderProvider: orderProvider,
    );
  }

  void onDeliveryTypeChanged(String? deliveryType) {
    if (_selectedDeliveryType == deliveryType) return;
    _selectedDeliveryType = deliveryType;
    _notifyListenersSafely();
  }

  void onCountryCodeChanged(String countryCode) {
    if (_selectedCountryCode == countryCode) return;
    _selectedCountryCode = countryCode;
    _notifyListenersSafely();
  }

  void onCityChanged(
    String? cityId, {
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
  }) {
    if (_selectedCityId == cityId) return;
    _selectedCityId = cityId;
    _selectedVillageId = null;
    _notifyListenersSafely();

    if (cityId != null) {
      regionProvider.loadVillages(cityId);
      scheduleEstimate(
        regionProvider: regionProvider,
        locationProvider: locationProvider,
        orderProvider: orderProvider,
      );
    } else {
      _updateEstimatedPrice(null);
    }
  }

  void onVillageChanged(
    String? villageId, {
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
  }) {
    if (_selectedVillageId == villageId) return;
    _selectedVillageId = villageId;
    _notifyListenersSafely();
    scheduleEstimate(
      regionProvider: regionProvider,
      locationProvider: locationProvider,
      orderProvider: orderProvider,
    );
  }

  /// Select a saved address
  Future<void> selectSavedAddress(
    String? addressId, {
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
  }) async {
    if (_selectedSavedAddressId == addressId) return;
    
    _selectedSavedAddressId = addressId;
    _useCurrentLocation = addressId == null;
    
    if (addressId != null) {
      final address = await SavedAddressService.getAddressById(addressId);
      if (address != null) {
        // Ensure cities are loaded before trying to match
        if (!regionProvider.citiesLoaded) {
          await regionProvider.loadCities();
        }
        
        debugPrint('📍 Loading saved address: ${address.label}');
        debugPrint('   - cityId: ${address.cityId}');
        debugPrint('   - villageId: ${address.villageId}');
        debugPrint('   - address: ${address.address}');
        debugPrint('   - coordinates: ${address.latitude}, ${address.longitude}');
        
        // STEP 1: Try to use saved cityId/villageId first (most reliable)
        String? validCityId = address.cityId;
        String? validVillageId = address.villageId;
        bool cityMatched = false;
        bool villageMatched = false;
        
        // Validate city ID if it exists
        if (validCityId != null && validCityId.isNotEmpty) {
          final city = regionProvider.cityById(validCityId);
          if (city != null) {
            _selectedCityId = validCityId;
            cityMatched = true;
            debugPrint('✅ Using saved cityId: $validCityId (${city.name})');
            
            // Load villages for this city
            await regionProvider.loadVillages(validCityId);
            
            // Validate village ID if it exists
            if (validVillageId != null && validVillageId.isNotEmpty) {
              final village = regionProvider.villageById(validCityId, validVillageId);
              if (village != null) {
                _selectedVillageId = validVillageId;
                villageMatched = true;
                debugPrint('✅ Using saved villageId: $validVillageId (${village.name})');
              } else {
                debugPrint('⚠️ Saved villageId $validVillageId not found, will try to match');
                validVillageId = null;
              }
            }
          } else {
            debugPrint('⚠️ Saved cityId $validCityId not found, will try to match');
            validCityId = null;
          }
        }
        
        // STEP 2: If city not matched, try to match from address string or coordinates
        if (!cityMatched) {
          // First try matching from saved address string
          if (address.address != null && address.address!.isNotEmpty) {
            debugPrint('🔍 Trying to match city from address string: ${address.address}');
            cityMatched = await _tryMatchCityFromAddress(address.address!, regionProvider);
            if (cityMatched) {
              validCityId = _selectedCityId;
              debugPrint('✅ City matched from address string: $validCityId');
              // Load villages for matched city
              if (validCityId != null) {
                await regionProvider.loadVillages(validCityId);
              }
            }
          }
          
          // If still not matched, try reverse geocoding from coordinates
          if (!cityMatched) {
            try {
              debugPrint('🔍 Trying reverse geocoding for coordinates: ${address.latitude}, ${address.longitude}');
              final placemarks = await placemarkFromCoordinates(
                address.latitude,
                address.longitude,
              );
              if (placemarks.isNotEmpty) {
                final placemark = placemarks.first;
                debugPrint('📍 Placemark data: locality=${placemark.locality}, subAdmin=${placemark.subAdministrativeArea}, admin=${placemark.administrativeArea}');
                
                // Try multiple combinations from placemark data
                final addressStrings = <String>[];
                
                // Add individual fields if they exist
                if (placemark.locality != null && placemark.locality!.isNotEmpty) {
                  addressStrings.add(placemark.locality!);
                }
                if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
                  addressStrings.add(placemark.subAdministrativeArea!);
                }
                if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
                  addressStrings.add(placemark.administrativeArea!);
                }
                
                // Add combinations
                if (placemark.locality != null && placemark.locality!.isNotEmpty &&
                    placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
                  addressStrings.add('${placemark.locality} - ${placemark.subAdministrativeArea}');
                }
                if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty &&
                    placemark.locality != null && placemark.locality!.isNotEmpty) {
                  addressStrings.add('${placemark.subAdministrativeArea} - ${placemark.locality}');
                }
                
                for (final addressString in addressStrings) {
                  if (addressString.trim().isEmpty) continue;
                  debugPrint('🔍 Trying to match city from: $addressString');
                  cityMatched = await _tryMatchCityFromAddress(addressString.trim(), regionProvider);
                  if (cityMatched) {
                    validCityId = _selectedCityId;
                    debugPrint('✅ City matched from reverse geocoding: $validCityId');
                    // Load villages for matched city
                    if (validCityId != null) {
                      await regionProvider.loadVillages(validCityId);
                    }
                    break;
                  }
                }
              }
            } catch (e) {
              debugPrint('❌ Error reverse geocoding saved address: $e');
            }
          }
        }
        
        // STEP 3: If village not matched yet, try to match from address string or coordinates
        if (cityMatched && validCityId != null && !villageMatched) {
          // First try matching from saved address string
          if (address.address != null && address.address!.isNotEmpty) {
            debugPrint('🔍 Trying to match village from address string: ${address.address}');
            villageMatched = await _tryMatchVillageFromAddress(address.address!, regionProvider);
            if (villageMatched) {
              validVillageId = _selectedVillageId;
              debugPrint('✅ Village matched from address string: $validVillageId');
            }
          }
          
          // If still not matched, try reverse geocoding
          if (!villageMatched) {
            try {
              debugPrint('🔍 Trying reverse geocoding for village at: ${address.latitude}, ${address.longitude}');
              final placemarks = await placemarkFromCoordinates(
                address.latitude,
                address.longitude,
              );
              if (placemarks.isNotEmpty) {
                final placemark = placemarks.first;
                debugPrint('📍 Placemark for village: subLocality=${placemark.subLocality}, locality=${placemark.locality}, thoroughfare=${placemark.thoroughfare}');
                
                // Try multiple combinations from placemark data
                final addressStrings = <String>[];
                
                // Add individual fields if they exist
                if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
                  addressStrings.add(placemark.subLocality!);
                }
                if (placemark.locality != null && placemark.locality!.isNotEmpty) {
                  addressStrings.add(placemark.locality!);
                }
                if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
                  addressStrings.add(placemark.thoroughfare!);
                }
                
                // Add combinations
                if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty &&
                    placemark.locality != null && placemark.locality!.isNotEmpty) {
                  addressStrings.add('${placemark.subLocality} - ${placemark.locality}');
                }
                if (placemark.locality != null && placemark.locality!.isNotEmpty &&
                    placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
                  addressStrings.add('${placemark.locality} - ${placemark.subLocality}');
                }
                
                for (final addressString in addressStrings) {
                  if (addressString.trim().isEmpty) continue;
                  debugPrint('🔍 Trying to match village from: $addressString');
                  villageMatched = await _tryMatchVillageFromAddress(addressString.trim(), regionProvider);
                  if (villageMatched) {
                    validVillageId = _selectedVillageId;
                    debugPrint('✅ Village matched from reverse geocoding: $validVillageId');
                    break;
                  }
                }
              }
            } catch (e) {
              debugPrint('❌ Error reverse geocoding village for saved address: $e');
            }
          }
        }
        
        // Set final values
        _selectedCityId = cityMatched ? validCityId : null;
        _selectedVillageId = villageMatched ? validVillageId : null;
        
        if (!cityMatched) {
          debugPrint('❌ Failed to match city for saved address');
        } else if (!villageMatched) {
          debugPrint('⚠️ Village not matched for saved address (village is optional)');
        } else {
          debugPrint('✅ Successfully matched city and village for saved address');
        }
        
        // Only set street details if the saved address has them
        // Otherwise, keep the current value or leave empty
        if (address.streetDetails != null && address.streetDetails!.isNotEmpty) {
          senderAddressController.text = address.streetDetails!;
        }
        
        // Notify listeners to update UI (city/village fields are hidden when saved address is selected)
        _notifyListenersSafely();
        
        // Only schedule estimate if we have the required data
        if (_selectedCityId != null && _selectedCityId!.isNotEmpty) {
          scheduleEstimate(
            regionProvider: regionProvider,
            locationProvider: locationProvider,
            orderProvider: orderProvider,
          );
        }
      } else {
        // Address not found, reset to current location
        _useCurrentLocation = true;
        _selectedSavedAddressId = null;
        _notifyListenersSafely();
      }
    } else {
      // Reset to current location
      senderAddressController.clear();
      _selectedCityId = null;
      _selectedVillageId = null;
      _notifyListenersSafely();
    }
  }

  /// Use current location instead of saved address
  void useCurrentLocationForPickup({
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
  }) {
    _useCurrentLocation = true;
    _selectedSavedAddressId = null;
    senderAddressController.clear();
    _selectedCityId = null;
    _selectedVillageId = null;
    _notifyListenersSafely();
    scheduleEstimate(
      regionProvider: regionProvider,
      locationProvider: locationProvider,
      orderProvider: orderProvider,
    );
  }

  void onSenderAddressChanged({
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
  }) {
    scheduleEstimate(
      regionProvider: regionProvider,
      locationProvider: locationProvider,
      orderProvider: orderProvider,
    );
  }

  /// Normalize string for comparison (handles Arabic and special characters)
  String _normalizeForComparison(String text) {
    // Remove extra whitespace and normalize
    return text.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }
  
  /// Check if two strings match (handles Arabic and special characters)
  bool _stringsMatch(String str1, String str2) {
    final normalized1 = _normalizeForComparison(str1);
    final normalized2 = _normalizeForComparison(str2);
    
    // Exact match
    if (normalized1 == normalized2) return true;
    
    // Contains match (either direction)
    if (normalized1.contains(normalized2) || normalized2.contains(normalized1)) {
      // Only consider it a match if the shorter string is at least 3 characters
      // This prevents false matches on very short strings
      final shorter = normalized1.length < normalized2.length ? normalized1 : normalized2;
      if (shorter.length >= 3) {
        return true;
      }
    }
    
    return false;
  }

  /// Try to match city from address string
  /// Only matches against database fields: name (Arabic) and nameEn (English)
  Future<bool> _tryMatchCityFromAddress(String addressString, RegionViewModel regionProvider) async {
    // Ensure cities are loaded
    if (!regionProvider.citiesLoaded) {
      await regionProvider.loadCities();
    }
    
    final cities = regionProvider.activeCities;
    if (cities.isEmpty) {
      debugPrint('⚠️ No cities available for matching');
      return false;
    }
    
    debugPrint('🔍 Matching city from: "$addressString" (checking ${cities.length} cities)');
    
    // Match against database fields only: name (Arabic) and nameEn (English)
    for (final city in cities) {
      // Check Arabic name
      if (_stringsMatch(addressString, city.name)) {
        _selectedCityId = city.id;
        await regionProvider.loadVillages(city.id);
        _notifyListenersSafely();
        debugPrint('✅ City matched: ${city.name} (ID: ${city.id})');
        return true;
      }
      
      // Check English name if available
      if (city.nameEn != null && city.nameEn!.isNotEmpty) {
        if (_stringsMatch(addressString, city.nameEn!)) {
          _selectedCityId = city.id;
          await regionProvider.loadVillages(city.id);
          _notifyListenersSafely();
          debugPrint('✅ City matched (English): ${city.nameEn} (ID: ${city.id})');
          return true;
        }
      }
    }
    
    // If no city match found, try matching as a village name to find parent city
    debugPrint('🔍 No direct city match found, trying to match as village name...');
    
    for (final city in cities) {
      // Load villages for this city
      await regionProvider.loadVillages(city.id);
      final villages = regionProvider.activeVillagesForCity(city.id);
      
      for (final village in villages) {
        // Check Arabic name
        if (_stringsMatch(addressString, village.name)) {
          _selectedCityId = city.id;
          await regionProvider.loadVillages(city.id);
          _notifyListenersSafely();
          debugPrint('✅ City matched via village: ${city.name} (village: ${village.name}, ID: ${city.id})');
          return true;
        }
        
        // Check English name if available
        if (village.nameEn != null && village.nameEn!.isNotEmpty) {
          if (_stringsMatch(addressString, village.nameEn!)) {
            _selectedCityId = city.id;
            await regionProvider.loadVillages(city.id);
            _notifyListenersSafely();
            debugPrint('✅ City matched via village (English): ${city.name} (village: ${village.nameEn}, ID: ${city.id})');
            return true;
          }
        }
      }
    }
    
    debugPrint('❌ No city or village match found for: "$addressString"');
    
    return false;
  }

  /// Try to match village from address string
  /// Only matches against database fields: name (Arabic) and nameEn (English)
  Future<bool> _tryMatchVillageFromAddress(String addressString, RegionViewModel regionProvider) async {
    if (_selectedCityId == null || _selectedCityId!.isEmpty) {
      debugPrint('⚠️ Cannot match village: no city selected');
      return false;
    }
    
    // Ensure villages are loaded for the selected city
    if (!regionProvider.villagesForCity(_selectedCityId!).isNotEmpty) {
      await regionProvider.loadVillages(_selectedCityId!);
    }
    
    final villages = regionProvider.activeVillagesForCity(_selectedCityId!);
    if (villages.isEmpty) {
      debugPrint('⚠️ No villages available for city ${_selectedCityId}');
      return false;
    }
    
    debugPrint('🔍 Matching village from: "$addressString" (checking ${villages.length} villages in city ${_selectedCityId})');
    
    // Match against database fields only: name (Arabic) and nameEn (English)
    for (final village in villages) {
      // Check Arabic name
      if (_stringsMatch(addressString, village.name)) {
        _selectedVillageId = village.id;
        _notifyListenersSafely();
        debugPrint('✅ Village matched: ${village.name} (ID: ${village.id})');
        return true;
      }
      
      // Check English name if available
      if (village.nameEn != null && village.nameEn!.isNotEmpty) {
        if (_stringsMatch(addressString, village.nameEn!)) {
          _selectedVillageId = village.id;
          _notifyListenersSafely();
          debugPrint('✅ Village matched (English): ${village.nameEn} (ID: ${village.id})');
          return true;
        }
      }
    }
    
    debugPrint('❌ No village match found for: "$addressString"');
    
    return false;
  }

  void scheduleEstimate({
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
  }) {
    _debounceTimer?.cancel();

    if (_selectedVehicle.isEmpty ||
        composeAddress(regionProvider).trim().isEmpty) {
      _updateEstimatedPrice(null);
      return;
    }

    _debounceTimer = Timer(
      const Duration(milliseconds: 500),
      () {
        // Note: getLocalizedErrorMessage is not available here, 
        // so we'll use the default English message
        fetchEstimate(
          regionProvider: regionProvider,
          locationProvider: locationProvider,
          orderProvider: orderProvider,
        );
      },
    );
  }

  Future<void> fetchEstimate({
    required RegionViewModel regionProvider,
    required LocationViewModel locationProvider,
    required OrderViewModel orderProvider,
    String Function()? getLocalizedErrorMessage,
  }) async {
    final position = locationProvider.currentPosition;
    final address = composeAddress(regionProvider).trim();

    if (_selectedVehicle.isEmpty || address.isEmpty) {
      _updateEstimatedPrice(null);
      return;
    }

    _setEstimating(true);

    final pickupLocation = position != null
        ? {
            'lat': position.latitude,
            'lng': position.longitude,
            if (address.isNotEmpty) 'address': address,
            if (_selectedCityId != null) 'cityId': _selectedCityId,
            if (_selectedVillageId != null) 'villageId': _selectedVillageId,
            'cityName': regionProvider.cityById(_selectedCityId ?? '')?.name,
            'villageName': regionProvider
                .villageById(_selectedCityId ?? '', _selectedVillageId ?? '')
                ?.name,
          }
        : (address.isNotEmpty ? {'address': address} : null);

    final cost = await orderProvider.estimateOrderCost(
      vehicleType: _selectedVehicle,
      pickupLocation: pickupLocation,
      dropoffLocation: pickupLocation,
    );

    if (_isDisposed) return;

    _setEstimating(false);
    _updateEstimatedPrice(cost);

    if (cost == null) {
      final errorMessage = getLocalizedErrorMessage?.call() ?? 
          'Unable to calculate estimated delivery cost.';
      _emitMessage(
        errorMessage,
        type: DeliveryRequestFormMessageType.error,
      );
    }
  }

  // Send OTP using Firebase Phone Authentication
  Future<void> sendOTP({
    required LocationViewModel locationProvider,
    required RegionViewModel regionProvider,
    required OrderViewModel orderProvider,
  }) async {
    if (_isSendingOTP) return;

    // Validate phone number
    final trimmedPhone = phoneNumberController.text.trim();
    if (trimmedPhone.isEmpty || trimmedPhone.length < 9 || trimmedPhone.length > 10) {
      _otpError = 'Please enter a valid phone number (9-10 digits)';
      _notifyListenersSafely();
      return;
    }

    _isSendingOTP = true;
    _otpError = null;
    _firebaseVerificationId = null;
    _notifyListenersSafely();

    try {
      // Format phone number with country code
      String fullPhoneNumber = trimmedPhone;
      if (!fullPhoneNumber.startsWith('+')) {
        fullPhoneNumber = '$_selectedCountryCode$fullPhoneNumber';
      }

      print('📱 Sending Firebase OTP to: $fullPhoneNumber');

      // Use Firebase Phone Auth
      final completer = Completer<bool>();
      
      _firebaseAuth.sendOTPWithCallback(
        fullPhoneNumber,
        (verificationId) {
          print('✅ Firebase OTP sent. Verification ID received.');
          _firebaseVerificationId = verificationId;
          _otpSent = true;
          _otpError = null;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        (error) {
          print('❌ Firebase OTP error: $error');
          _otpError = error;
          _otpSent = false;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Wait for callback with timeout
      await completer.future.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          _otpError = 'OTP request timed out. Please try again.';
          _otpSent = false;
          return false;
        },
      );
    } catch (e) {
      print('❌ Exception in sendOTP: $e');
      _otpError = e.toString().replaceAll('Exception: ', '');
      _otpSent = false;
    } finally {
      _isSendingOTP = false;
      _notifyListenersSafely();
    }
  }

  void resetOTPState() {
    _otpSent = false;
    _otpError = null;
    _firebaseVerificationId = null;
    otpController.clear();
    _notifyListenersSafely();
  }

  Future<DeliveryRequestSubmitResult> validateFormAndSubmitOrder({
    required LocationViewModel locationProvider,
    required RegionViewModel regionProvider,
    required OrderViewModel orderProvider,
    required AuthViewModel authProvider,
    String Function(String key)? getLocalizedMessage,
  }) async {
    String localized(String key, String fallback) => 
        getLocalizedMessage?.call(key) ?? fallback;

    // Validate form first
    if (_selectedVehicle.isEmpty) {
      return DeliveryRequestSubmitResult.failure(
        localized('pleaseSelectDeliveryVehicle', 'Please select a delivery vehicle.'),
      );
    }

    // City and Village are only required when using Current Location
    // When using a saved address, try to match city/village from address string if missing
    if (_useCurrentLocation) {
      if (_selectedCityId == null || _selectedCityId!.isEmpty) {
        return DeliveryRequestSubmitResult.failure(
          localized('pleaseSelectYourCity', 'Please select your city.'),
        );
      }

      if (_selectedVillageId == null || _selectedVillageId!.isEmpty) {
        return DeliveryRequestSubmitResult.failure(
          localized('pleaseSelectYourVillage', 'Please select your village.'),
        );
      }
    } else if (_selectedSavedAddressId != null) {
      // When using saved address, try to match city/village if missing
      final savedAddress = await SavedAddressService.getAddressById(_selectedSavedAddressId!);
      if (savedAddress != null) {
        // Ensure cities are loaded
        if (!regionProvider.citiesLoaded) {
          await regionProvider.loadCities();
        }
        
        // Validate city ID exists in current cities list
        String? validCityId = _selectedCityId;
        if (validCityId != null && validCityId.isNotEmpty) {
          final cityExists = regionProvider.cityById(validCityId) != null;
          if (!cityExists) {
            validCityId = null;
            _selectedCityId = null;
          }
        }
        
        // Try to match city from address string if missing or invalid
        bool cityMatched = false;
        if (validCityId == null || validCityId.isEmpty) {
          // First try matching from saved address string
          if (savedAddress.address != null && savedAddress.address!.isNotEmpty) {
            debugPrint('🔍 Trying to match city from address string (validation): ${savedAddress.address}');
            cityMatched = await _tryMatchCityFromAddress(savedAddress.address!, regionProvider);
            if (cityMatched) {
              validCityId = _selectedCityId;
              debugPrint('✅ City matched from address string (validation): $validCityId');
            }
          }
          
          // If still not matched, try reverse geocoding
          if (!cityMatched) {
            try {
              debugPrint('🔍 Trying reverse geocoding for coordinates (validation): ${savedAddress.latitude}, ${savedAddress.longitude}');
              final placemarks = await placemarkFromCoordinates(
                savedAddress.latitude,
                savedAddress.longitude,
              );
              if (placemarks.isNotEmpty) {
                final placemark = placemarks.first;
                debugPrint('📍 Placemark data (validation): locality=${placemark.locality}, subAdmin=${placemark.subAdministrativeArea}, admin=${placemark.administrativeArea}');
                
                // Try multiple combinations from placemark data
                final addressStrings = <String>[];
                
                // Add individual fields if they exist
                if (placemark.locality != null && placemark.locality!.isNotEmpty) {
                  addressStrings.add(placemark.locality!);
                }
                if (placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
                  addressStrings.add(placemark.subAdministrativeArea!);
                }
                if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
                  addressStrings.add(placemark.administrativeArea!);
                }
                
                // Add combinations
                if (placemark.locality != null && placemark.locality!.isNotEmpty &&
                    placemark.subAdministrativeArea != null && placemark.subAdministrativeArea!.isNotEmpty) {
                  addressStrings.add('${placemark.locality} - ${placemark.subAdministrativeArea}');
                }
                
                for (final addressString in addressStrings) {
                  if (addressString.trim().isEmpty) continue;
                  debugPrint('🔍 Trying to match city from (validation): $addressString');
                  cityMatched = await _tryMatchCityFromAddress(addressString.trim(), regionProvider);
                  if (cityMatched) {
                    validCityId = _selectedCityId;
                    debugPrint('✅ City matched from reverse geocoding (validation): $validCityId');
                    break;
                  }
                }
              }
            } catch (e) {
              debugPrint('❌ Error reverse geocoding city for saved address validation: $e');
            }
          }
        } else {
          // City ID exists and is valid
          cityMatched = true;
          debugPrint('✅ Using saved cityId (validation): $validCityId');
        }
        
        // Update selected city ID
        _selectedCityId = cityMatched ? validCityId : null;
        
        // Validate village ID exists if city is matched
        String? validVillageId = _selectedVillageId;
        bool villageMatched = false;
        
        if (cityMatched && validCityId != null && validCityId.isNotEmpty) {
          await regionProvider.loadVillages(validCityId);
          
          // Validate village ID exists in current villages list
          if (validVillageId != null && validVillageId.isNotEmpty) {
            final villageExists = regionProvider.villageById(validCityId, validVillageId) != null;
            if (!villageExists) {
              validVillageId = null;
              _selectedVillageId = null;
            }
          }
          
          // Try to match village from address string if missing or invalid
          if ((validVillageId == null || validVillageId.isEmpty) && savedAddress.address != null) {
            villageMatched = await _tryMatchVillageFromAddress(savedAddress.address!, regionProvider);
            if (villageMatched) {
              validVillageId = _selectedVillageId;
            }
          } else if (validVillageId != null && validVillageId.isNotEmpty) {
            villageMatched = true;
          }
          
          // If still not matched and we have coordinates, try reverse geocoding
          if (!villageMatched) {
            try {
              debugPrint('🔍 Trying reverse geocoding for village (validation) at: ${savedAddress.latitude}, ${savedAddress.longitude}');
              final placemarks = await placemarkFromCoordinates(
                savedAddress.latitude,
                savedAddress.longitude,
              );
              if (placemarks.isNotEmpty) {
                final placemark = placemarks.first;
                debugPrint('📍 Placemark for village (validation): subLocality=${placemark.subLocality}, locality=${placemark.locality}, thoroughfare=${placemark.thoroughfare}');
                
                // Try multiple combinations from placemark data
                final addressStrings = <String>[];
                
                // Add individual fields if they exist
                if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
                  addressStrings.add(placemark.subLocality!);
                }
                if (placemark.locality != null && placemark.locality!.isNotEmpty) {
                  addressStrings.add(placemark.locality!);
                }
                if (placemark.thoroughfare != null && placemark.thoroughfare!.isNotEmpty) {
                  addressStrings.add(placemark.thoroughfare!);
                }
                
                // Add combinations
                if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty &&
                    placemark.locality != null && placemark.locality!.isNotEmpty) {
                  addressStrings.add('${placemark.subLocality} - ${placemark.locality}');
                }
                
                for (final addressString in addressStrings) {
                  if (addressString.trim().isEmpty) continue;
                  debugPrint('🔍 Trying to match village from (validation): $addressString');
                  villageMatched = await _tryMatchVillageFromAddress(addressString.trim(), regionProvider);
                  if (villageMatched) {
                    validVillageId = _selectedVillageId;
                    debugPrint('✅ Village matched from reverse geocoding (validation): $validVillageId');
                    break;
                  }
                }
              }
            } catch (e) {
              debugPrint('❌ Error reverse geocoding village for saved address validation: $e');
            }
          }
        }
        
        // Update selected village ID
        _selectedVillageId = villageMatched ? validVillageId : null;
        
        // If city still missing after all matching attempts, show error
        // Village is optional in backend, so we allow proceeding without it if city is matched
        if (!cityMatched) {
          _notifyListenersSafely();
          return DeliveryRequestSubmitResult.failure(
            'Unable to determine city from saved address. Please use current location or update the saved address.',
          );
        }

        // Village is optional - if not matched, we'll proceed without it
        // This is acceptable for city center addresses where village might not be available
        // If village not matched, try one more thing: check if city name itself is a village
        if (!villageMatched && validCityId != null && validCityId.isNotEmpty) {
          final city = regionProvider.cityById(validCityId);
          if (city != null) {
            final villages = regionProvider.activeVillagesForCity(validCityId);
            // Check if any village name matches the city name (for city center villages)
            for (final village in villages) {
              if (village.name.toLowerCase() == city.name.toLowerCase() ||
                  village.name.toLowerCase().contains(city.name.toLowerCase()) ||
                  city.name.toLowerCase().contains(village.name.toLowerCase())) {
                _selectedVillageId = village.id;
                villageMatched = true;
                debugPrint('✅ Village matched (city center): ${village.name}');
                break;
              }
            }
          }
        }
        
        // If still not matched, proceed without village (village is optional for saved addresses)
        if (!villageMatched) {
          debugPrint('⚠️ Village not matched, but proceeding without it (village is optional for saved addresses)');
          _selectedVillageId = null; // Clear village ID to proceed without it
        }
      } else {
        return DeliveryRequestSubmitResult.failure(
          'Selected saved address not found. Please select another address.',
        );
      }
    }

    if (formKey.currentState?.validate() != true) {
      return DeliveryRequestSubmitResult.failure(
        'Please fill all required fields correctly.',
      );
    }

    final trimmedPhone = phoneNumberController.text.trim();
    
    if (trimmedPhone.isEmpty || trimmedPhone.length < 9 || trimmedPhone.length > 10) {
      return DeliveryRequestSubmitResult.failure(
        localized('pleaseEnterValidPhoneNumber', 'Please enter a valid phone number (9-10 digits).'),
      );
    }

    if (_estimatedPrice == null) {
      return DeliveryRequestSubmitResult.failure(
        localized('waitForEstimatedCost', 'Please wait for the estimated cost before submitting.'),
      );
    }

    if (_selectedOrderCategoryId == null) {
      return DeliveryRequestSubmitResult.failure(
        localized('pleaseSelectOrderCategory', 'Please select the order category.'),
      );
    }

    if (_selectedDeliveryType == null || _selectedDeliveryType!.isEmpty) {
      return DeliveryRequestSubmitResult.failure(
        localized('pleaseSelectDeliveryType', 'Please select a delivery type.'),
      );
    }

    // Get position - either from current location or saved address
    Position? position;
    if (_useCurrentLocation) {
      position = locationProvider.currentPosition;
      if (position == null) {
        return DeliveryRequestSubmitResult.failure(
          localized('waitingForLocation', 'Waiting for your current location. Please enable location services and try again.'),
        );
      }
    } else if (_selectedSavedAddressId != null) {
      final savedAddress = await SavedAddressService.getAddressById(_selectedSavedAddressId!);
      if (savedAddress == null) {
        return DeliveryRequestSubmitResult.failure(
          'Selected saved address not found. Please select another address.',
        );
      }
      // Create a Position object from saved address coordinates
      position = Position(
        latitude: savedAddress.latitude,
        longitude: savedAddress.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } else {
      return DeliveryRequestSubmitResult.failure(
        localized('waitingForLocation', 'Please select a pickup location.'),
      );
    }

    // Check if user is already authenticated
    if (authProvider.isAuthenticated) {
      // User is authenticated - use existing token to create order directly
      return await _createOrderWithToken(
        locationProvider: locationProvider,
        regionProvider: regionProvider,
        orderProvider: orderProvider,
        getLocalizedMessage: getLocalizedMessage,
      );
    }

    // User not authenticated - proceed with OTP flow
    // If OTP already sent, just return success to show dialog
    if (_otpSent) {
      return DeliveryRequestSubmitResult.success('OTP already sent');
    }

    // Send OTP
    await sendOTP(
      locationProvider: locationProvider,
      regionProvider: regionProvider,
      orderProvider: orderProvider,
    );

    if (_otpSent) {
      return DeliveryRequestSubmitResult.success('OTP sent successfully');
    } else {
      return DeliveryRequestSubmitResult.failure(_otpError ?? 'Failed to send OTP');
    }
  }

  Future<DeliveryRequestSubmitResult> _createOrderWithToken({
    required LocationViewModel locationProvider,
    required RegionViewModel regionProvider,
    required OrderViewModel orderProvider,
    String Function(String key)? getLocalizedMessage,
  }) async {
    String localized(String key, String fallback) => 
        getLocalizedMessage?.call(key) ?? fallback;

    final selectedCategory = orderProvider.categoryById(_selectedOrderCategoryId!);
    if (selectedCategory == null) {
      await orderProvider.loadOrderCategories(forceRefresh: true);
      return DeliveryRequestSubmitResult.failure(
        localized('orderCategoryNoLongerAvailable', 'The selected order category is no longer available. Please choose another.'),
      );
    }

    // Get position - either from current location or saved address
    Position? position;
    if (_useCurrentLocation) {
      position = locationProvider.currentPosition;
      if (position == null) {
        return DeliveryRequestSubmitResult.failure(
          localized('waitingForLocation', 'Waiting for your current location. Please enable location services and try again.'),
        );
      }
    } else if (_selectedSavedAddressId != null) {
      final savedAddress = await SavedAddressService.getAddressById(_selectedSavedAddressId!);
      if (savedAddress == null) {
        return DeliveryRequestSubmitResult.failure(
          'Selected saved address not found. Please select another address.',
        );
      }
      // Create a Position object from saved address coordinates
      position = Position(
        latitude: savedAddress.latitude,
        longitude: savedAddress.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } else {
      return DeliveryRequestSubmitResult.failure(
        localized('waitingForLocation', 'Please select a pickup location.'),
      );
    }

    final trimmedPhone = phoneNumberController.text.trim();
    final parsedPhoneNumber = int.tryParse(trimmedPhone);
    if (parsedPhoneNumber == null) {
      return DeliveryRequestSubmitResult.failure(
        localized('pleaseEnterValidPhoneNumber', 'Please enter a valid phone number.'),
      );
    }

    _setSubmitting(true);

    // Get address string - use saved address if available, otherwise compose from form
    String addressString;
    if (!_useCurrentLocation && _selectedSavedAddressId != null) {
      final savedAddress = await SavedAddressService.getAddressById(_selectedSavedAddressId!);
      addressString = savedAddress?.address ?? composeAddress(regionProvider);
    } else {
      addressString = locationProvider.currentAddress ?? composeAddress(regionProvider);
    }

    final pickupLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': addressString,
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) 'cityId': _selectedCityId,
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) 
        'cityName': regionProvider.cityById(_selectedCityId!)?.name,
      if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty) 'villageId': _selectedVillageId,
      if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty)
        'villageName': regionProvider
            .villageById(_selectedCityId ?? '', _selectedVillageId!)
            ?.name,
    };

    final dropoffLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': addressString,
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) 'cityId': _selectedCityId,
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) 
        'cityName': regionProvider.cityById(_selectedCityId!)?.name,
      if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty) 'villageId': _selectedVillageId,
      if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty)
        'villageName': regionProvider
            .villageById(_selectedCityId ?? '', _selectedVillageId!)
            ?.name,
    };

    // Get separate address components from form
    final city = _selectedCityId != null && _selectedCityId!.isNotEmpty
        ? regionProvider.cityById(_selectedCityId!)
        : null;
    final cityName = city?.name ?? '';
    
    final village = _selectedCityId != null && 
            _selectedCityId!.isNotEmpty && 
            _selectedVillageId != null && 
            _selectedVillageId!.isNotEmpty
        ? regionProvider.villageById(_selectedCityId!, _selectedVillageId!)
        : null;
    final villageName = village?.name ?? '';
    
    final streetDetails = senderAddressController.text.trim();

    // Validate that we have city name (required)
    if (cityName.isEmpty) {
      _setSubmitting(false);
      return DeliveryRequestSubmitResult.failure(
        'City information is required. Please select a city or use current location.',
      );
    }
    
    // Village is optional in backend, but required when using current location
    // When using saved address, village can be empty (for city center addresses)
    if (_useCurrentLocation && villageName.isEmpty) {
      _setSubmitting(false);
      return DeliveryRequestSubmitResult.failure(
        'Village information is required when using current location. Please select a village.',
      );
    }
    
    // For saved addresses, village is optional - we can proceed without it

    try {
      // Use the authenticated order creation endpoint
      final response = await ApiService.createOrder(
        type: requestType,
        deliveryType: _selectedDeliveryType!,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        vehicleType: _selectedVehicle,
        orderCategory: selectedCategory.name,
        senderName: senderNameController.text.trim(),
        // Send separate address components
        senderCity: cityName,
        senderVillage: villageName,
        senderStreetDetails: streetDetails,
        senderPhoneNumber: parsedPhoneNumber,
        deliveryNotes: notesController.text.trim(),
        estimatedPrice: _estimatedPrice,
      );

      if (_isDisposed) {
        return DeliveryRequestSubmitResult.failure();
      }

      _setSubmitting(false);

      if (response['order'] != null) {
        final createdOrder = Map<String, dynamic>.from(response['order'] as Map<String, dynamic>);
        orderProvider.setActiveOrder(createdOrder);
        await orderProvider.fetchOrders();
        
        final successMessage = getLocalizedMessage?.call('orderCreatedSuccessfully') ?? 
            'Order created successfully!';
        return DeliveryRequestSubmitResult.success(successMessage);
      }

      final failureMessage = getLocalizedMessage?.call('failedToCreateOrder') ?? 
          'Failed to create order';
      return DeliveryRequestSubmitResult.failure(failureMessage);
    } catch (e) {
      if (_isDisposed) {
        return DeliveryRequestSubmitResult.failure();
      }
      
      _setSubmitting(false);
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      return DeliveryRequestSubmitResult.failure(errorMessage);
    }
  }

  // Verify OTP with Firebase and create order
  Future<DeliveryRequestSubmitResult> verifyOTPAndCreateOrder({
    required LocationViewModel locationProvider,
    required RegionViewModel regionProvider,
    required OrderViewModel orderProvider,
    required AuthViewModel authProvider,
    String Function(String key)? getLocalizedMessage,
  }) async {
    String localized(String key, String fallback) => 
        getLocalizedMessage?.call(key) ?? fallback;

    // Validate OTP
    final otp = otpController.text.trim();
    if (otp.length != 6) {
      return DeliveryRequestSubmitResult.failure(
        'Please enter the 6-digit OTP code',
      );
    }

    // Check if Firebase verification ID exists
    if (_firebaseVerificationId == null) {
      return DeliveryRequestSubmitResult.failure(
        'Please request OTP first',
      );
    }

    final trimmedPhone = phoneNumberController.text.trim();
    
    if (trimmedPhone.isEmpty || trimmedPhone.length < 9 || trimmedPhone.length > 10) {
      return DeliveryRequestSubmitResult.failure(
        localized('pleaseEnterValidPhoneNumber', 'Please enter a valid phone number (9-10 digits).'),
      );
    }

    if (_estimatedPrice == null) {
      return DeliveryRequestSubmitResult.failure(
        localized('waitForEstimatedCost', 'Please wait for the estimated cost before submitting.'),
      );
    }

    if (_selectedOrderCategoryId == null) {
      return DeliveryRequestSubmitResult.failure(
        localized('pleaseSelectOrderCategory', 'Please select the order category.'),
      );
    }

    if (_selectedDeliveryType == null || _selectedDeliveryType!.isEmpty) {
      return DeliveryRequestSubmitResult.failure(
        localized('pleaseSelectDeliveryType', 'Please select a delivery type.'),
      );
    }

    final selectedCategory =
        orderProvider.categoryById(_selectedOrderCategoryId!);

    if (selectedCategory == null) {
      await orderProvider.loadOrderCategories(forceRefresh: true);
      return DeliveryRequestSubmitResult.failure(
        localized('orderCategoryNoLongerAvailable', 'The selected order category is no longer available. Please choose another.'),
      );
    }

    // Get position - either from current location or saved address
    Position? position;
    if (_useCurrentLocation) {
      position = locationProvider.currentPosition;
      if (position == null) {
        return DeliveryRequestSubmitResult.failure(
          localized('waitingForLocation', 'Waiting for your current location. Please enable location services and try again.'),
        );
      }
    } else if (_selectedSavedAddressId != null) {
      final savedAddress = await SavedAddressService.getAddressById(_selectedSavedAddressId!);
      if (savedAddress == null) {
        return DeliveryRequestSubmitResult.failure(
          'Selected saved address not found. Please select another address.',
        );
      }
      // Create a Position object from saved address coordinates
      position = Position(
        latitude: savedAddress.latitude,
        longitude: savedAddress.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } else {
      return DeliveryRequestSubmitResult.failure(
        localized('waitingForLocation', 'Please select a pickup location.'),
      );
    }

    // Get address string - use saved address if available, otherwise compose from form
    String addressString;
    if (!_useCurrentLocation && _selectedSavedAddressId != null) {
      final savedAddress = await SavedAddressService.getAddressById(_selectedSavedAddressId!);
      addressString = savedAddress?.address ?? composeAddress(regionProvider);
    } else {
      addressString = locationProvider.currentAddress ?? composeAddress(regionProvider);
    }

    final pickupLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': addressString,
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) 'cityId': _selectedCityId,
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) 
        'cityName': regionProvider.cityById(_selectedCityId!)?.name,
      if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty) 'villageId': _selectedVillageId,
      if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty)
        'villageName': regionProvider
            .villageById(_selectedCityId ?? '', _selectedVillageId!)
            ?.name,
    };

    final dropoffLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': addressString,
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) 'cityId': _selectedCityId,
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) 
        'cityName': regionProvider.cityById(_selectedCityId!)?.name,
      if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty) 'villageId': _selectedVillageId,
      if (_selectedVillageId != null && _selectedVillageId!.isNotEmpty)
        'villageName': regionProvider
            .villageById(_selectedCityId ?? '', _selectedVillageId!)
            ?.name,
    };

    // Get separate address components from form
    final city = _selectedCityId != null && _selectedCityId!.isNotEmpty
        ? regionProvider.cityById(_selectedCityId!)
        : null;
    final cityName = city?.name ?? '';
    
    final village = _selectedCityId != null && 
            _selectedCityId!.isNotEmpty && 
            _selectedVillageId != null && 
            _selectedVillageId!.isNotEmpty
        ? regionProvider.villageById(_selectedCityId!, _selectedVillageId!)
        : null;
    final villageName = village?.name ?? '';
    
    final streetDetails = senderAddressController.text.trim();

    // Validate that we have city name (required)
    if (cityName.isEmpty) {
      _isVerifyingOTP = false;
      return DeliveryRequestSubmitResult.failure(
        'City information is required. Please select a city or use current location.',
      );
    }
    
    // Village is optional in backend, but required when using current location
    // When using saved address, village can be empty (for city center addresses)
    if (_useCurrentLocation && villageName.isEmpty) {
      _isVerifyingOTP = false;
      return DeliveryRequestSubmitResult.failure(
        'Village information is required when using current location. Please select a village.',
      );
    }
    
    // For saved addresses, village is optional - we can proceed without it

    // Verify OTP with Firebase first
    _isVerifyingOTP = true;
    _notifyListenersSafely();

    try {
      print('🔄 Verifying Firebase OTP...');
      
      // Format phone number with country code
      String fullPhoneNumber = trimmedPhone;
      if (!fullPhoneNumber.startsWith('+')) {
        fullPhoneNumber = '$_selectedCountryCode$fullPhoneNumber';
      }

      // Verify OTP with Firebase
      final userCredential = await _firebaseAuth.verifyOTP(
        verificationId: _firebaseVerificationId!,
        smsCode: otp,
      );

      // Get Firebase user and ID token
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        _isVerifyingOTP = false;
        return DeliveryRequestSubmitResult.failure(
          'Failed to get Firebase user after verification',
        );
      }

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
        _isVerifyingOTP = false;
        return DeliveryRequestSubmitResult.failure(
          'Failed to get authentication token from Firebase',
        );
      }

      print('✅ Firebase OTP verified. Saving user to MongoDB...');

      // Normalize phone number before sending to backend
      // This ensures consistent format (+9720XXXXXXXX) regardless of input format
      String? normalizedPhone = PhoneUtils.normalizePhoneNumber(fullPhoneNumber);
      if (normalizedPhone == null) {
        _isVerifyingOTP = false;
        return DeliveryRequestSubmitResult.failure(
          'Invalid phone number format',
        );
      }

      // Call phone-login endpoint to save user in MongoDB and get JWT token
      try {
        final phoneLoginResponse = await ApiService.phoneLogin(
          phone: normalizedPhone,
          firebaseUid: firebaseUser.uid,
          verificationId: _firebaseVerificationId!,
          smsCode: otp,
          idToken: idToken,
        );

        print('✅ User saved in MongoDB. JWT token received.');

        // Update auth state with user data from phone-login response
        if (phoneLoginResponse['user'] != null) {
          await authProvider.setAuthenticated(
            token: phoneLoginResponse['token'] as String,
            user: Map<String, dynamic>.from(phoneLoginResponse['user'] as Map<String, dynamic>),
          );
        }
      } catch (e) {
        print('❌ Error calling phone-login: $e');
        _isVerifyingOTP = false;
        return DeliveryRequestSubmitResult.failure(
          'Failed to save user. Please try again.',
        );
      }

      print('✅ Creating order...');

      // Create order with Firebase token
      final response = await ApiService.createOrderWithFirebaseToken(
        idToken: idToken,
        type: requestType,
        deliveryType: _selectedDeliveryType!,
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        vehicleType: _selectedVehicle,
        orderCategory: selectedCategory.name,
        senderName: senderNameController.text.trim(),
        senderCity: cityName,
        senderVillage: villageName,
        senderStreetDetails: streetDetails,
        deliveryNotes: notesController.text.trim(),
      );

      if (_isDisposed) {
        return DeliveryRequestSubmitResult.failure();
      }

      _isVerifyingOTP = false;

      if (response['order'] != null) {
        final createdOrder = Map<String, dynamic>.from(response['order'] as Map<String, dynamic>);
        
        // Store JWT token if provided
        if (response['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', response['token'] as String);
          
          // Get user data from response or fetch from server
          Map<String, dynamic>? userData;
          if (response['user'] != null) {
            userData = Map<String, dynamic>.from(response['user'] as Map<String, dynamic>);
          } else {
            // Fetch user data from server to ensure we have latest info
            try {
              final userResponse = await ApiService.getCurrentUser();
              if (userResponse['user'] != null) {
                userData = Map<String, dynamic>.from(userResponse['user'] as Map<String, dynamic>);
              }
            } catch (e) {
              debugPrint('Error fetching user data: $e');
            }
          }
          
          // Update auth state
          await authProvider.setAuthenticated(
            token: response['token'] as String,
            user: userData,
          );
        }
        
        // Update order in view model
        orderProvider.setActiveOrder(createdOrder);
        await orderProvider.fetchOrders();
        
        final successMessage = getLocalizedMessage?.call('orderCreatedSuccessfully') ?? 
            'Order created successfully!';
        return DeliveryRequestSubmitResult.success(successMessage);
      }

      final failureMessage = getLocalizedMessage?.call('failedToCreateOrder') ?? 
          'Failed to create order';
      return DeliveryRequestSubmitResult.failure(failureMessage);
    } catch (e) {
      if (_isDisposed) {
        return DeliveryRequestSubmitResult.failure();
      }
      
      _isVerifyingOTP = false;
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      return DeliveryRequestSubmitResult.failure(errorMessage);
    }
  }

  String composeAddress(RegionViewModel regionProvider) {
    // Use ONLY current form selections and input - no parsing or merging with old addresses
    // Format: City-Village/Area-ExtraDetails (using hyphens)
    final parts = <String>[];
    
    // 1. Get city from current dropdown selection
    if (_selectedCityId != null) {
      final city = regionProvider.cityById(_selectedCityId!);
      if (city != null && city.name.isNotEmpty) {
        parts.add(city.name);
      }
    }
    
    // 2. Get village/area from current dropdown selection
    if (_selectedCityId != null && _selectedVillageId != null) {
      final village = regionProvider.villageById(_selectedCityId!, _selectedVillageId!);
      if (village != null && village.name.isNotEmpty) {
        parts.add(village.name);
      }
    }
    
    // 3. Get extra details from current form input (use as-is, no parsing)
    final manualAddress = senderAddressController.text.trim();
    if (manualAddress.isNotEmpty) {
      // Use the text input directly as extra details
      // The auto-fill should have already extracted only extra details
      parts.add(manualAddress);
    }
    
    // Join with hyphens: City-Village-ExtraDetails
    return parts.join('-');
  }

  void clearMessage() {
    if (messageNotifier.value == null) return;
    messageNotifier.value = null;
  }

  void _emitMessage(
    String message, {
    DeliveryRequestFormMessageType type = DeliveryRequestFormMessageType.info,
  }) {
    messageNotifier.value = DeliveryRequestFormMessage(message, type: type);
  }

  void _updateEstimatedPrice(double? value) {
    if (_estimatedPrice == value) return;
    _estimatedPrice = value;
    _notifyListenersSafely();
  }

  void _setEstimating(bool value) {
    if (_isEstimating == value) return;
    _isEstimating = value;
    _notifyListenersSafely();
  }

  void _setSubmitting(bool value) {
    if (_isSubmitting == value) return;
    _isSubmitting = value;
    _notifyListenersSafely();
  }

  void _notifyListenersSafely() {
    if (_isDisposed) return;
    notifyListeners();
  }

  /// Set up socket listeners for order-related events
  void _setupSocketListeners() async {
    // Ensure socket service is initialized
    await SocketService.initialize();
    
    // Listen for no-drivers-available event
    SocketService.off('no-drivers-available');
    SocketService.on('no-drivers-available', (data) {
      if (_isDisposed) return;
      
      // Use localized Arabic message if available, otherwise use backend message or default
      String message;
      if (_getLocalizedMessage != null) {
        message = _getLocalizedMessage!('noDriversAvailable') ?? 
            'لم يتم العثور على سائقين في منطقة الخدمة. الرجاء المحاولة مرة أخرى لاحقاً.';
      } else if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else {
        // Default Arabic message
        message = 'لم يتم العثور على سائقين في منطقة الخدمة. الرجاء المحاولة مرة أخرى لاحقاً.';
      }
      
      // Emit error message to display to user
      _emitMessage(
        message,
        type: DeliveryRequestFormMessageType.error,
      );
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounceTimer?.cancel();
    senderNameController.dispose();
    senderAddressController.dispose();
    phoneNumberController.dispose();
    notesController.dispose();
    otpController.dispose();
    messageNotifier.dispose();
    super.dispose();
  }
}
