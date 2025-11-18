import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../view_models/location_view_model.dart';
import '../../../../view_models/order_view_model.dart';
import '../../../../view_models/region_view_model.dart';
import '../../../../view_models/auth_view_model.dart';
import '../../../../repositories/api_service.dart';
import '../../../../services/socket_service.dart';
import '../../../../services/firebase_auth_service.dart';
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
  
  bool get isSendingOTP => _isSendingOTP;
  bool get isVerifyingOTP => _isVerifyingOTP;
  bool get otpSent => _otpSent;
  String? get otpError => _otpError;

  void initialize({
    required LocationViewModel locationProvider,
    required RegionViewModel regionProvider,
    required OrderViewModel orderProvider,
    AuthViewModel? authProvider,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;
    
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
        final countryCode = user['countryCode']?.toString() ?? '+970';
        
        // Extract phone number without country code
        String phoneNumber = phone;
        if (phone.startsWith(countryCode)) {
          phoneNumber = phone.substring(countryCode.length);
        }
        
        phoneNumberController.text = phoneNumber;
        
        if (_selectedCountryCode != countryCode) {
          _selectedCountryCode = countryCode;
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

    final position = locationProvider.currentPosition;

    if (position == null) {
      return DeliveryRequestSubmitResult.failure(
        localized('waitingForLocation', 'Waiting for your current location. Please enable location services and try again.'),
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

    final position = locationProvider.currentPosition;
    if (position == null) {
      return DeliveryRequestSubmitResult.failure(
        localized('waitingForLocation', 'Waiting for your current location. Please enable location services and try again.'),
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

    final pickupLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': locationProvider.currentAddress ?? composeAddress(regionProvider),
      'cityId': _selectedCityId,
      'cityName': regionProvider.cityById(_selectedCityId ?? '')?.name,
      'villageId': _selectedVillageId,
      'villageName': regionProvider
          .villageById(_selectedCityId ?? '', _selectedVillageId ?? '')
          ?.name,
    };

    final dropoffLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': composeAddress(regionProvider),
      'cityId': _selectedCityId,
      'cityName': regionProvider.cityById(_selectedCityId ?? '')?.name,
      'villageId': _selectedVillageId,
      'villageName': regionProvider
          .villageById(_selectedCityId ?? '', _selectedVillageId ?? '')
          ?.name,
    };

    // Get separate address components from form
    final cityName = regionProvider.cityById(_selectedCityId ?? '')?.name ?? '';
    final villageName = regionProvider
        .villageById(_selectedCityId ?? '', _selectedVillageId ?? '')
        ?.name ?? '';
    final streetDetails = senderAddressController.text.trim();

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

    final position = locationProvider.currentPosition;

    if (position == null) {
      return DeliveryRequestSubmitResult.failure(
        localized('waitingForLocation', 'Waiting for your current location. Please enable location services and try again.'),
      );
    }

    final pickupLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address':
          locationProvider.currentAddress ?? composeAddress(regionProvider),
      'cityId': _selectedCityId,
      'cityName': regionProvider.cityById(_selectedCityId ?? '')?.name,
      'villageId': _selectedVillageId,
      'villageName': regionProvider
          .villageById(_selectedCityId ?? '', _selectedVillageId ?? '')
          ?.name,
    };

    final dropoffLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': composeAddress(regionProvider),
      'cityId': _selectedCityId,
      'cityName': regionProvider.cityById(_selectedCityId ?? '')?.name,
      'villageId': _selectedVillageId,
      'villageName': regionProvider
          .villageById(_selectedCityId ?? '', _selectedVillageId ?? '')
          ?.name,
    };

    // Get separate address components from form
    final cityName = regionProvider.cityById(_selectedCityId ?? '')?.name ?? '';
    final villageName = regionProvider
        .villageById(_selectedCityId ?? '', _selectedVillageId ?? '')
        ?.name ?? '';
    final streetDetails = senderAddressController.text.trim();

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

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        _isVerifyingOTP = false;
        return DeliveryRequestSubmitResult.failure(
          'Failed to get authentication token from Firebase',
        );
      }

      print('✅ Firebase OTP verified. Creating order...');

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
