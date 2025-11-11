import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../providers/location_provider.dart';
import '../../../../providers/order_provider.dart';
import '../../../../providers/region_provider.dart';

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

  final ValueNotifier<DeliveryRequestFormMessage?> messageNotifier =
      ValueNotifier<DeliveryRequestFormMessage?>(null);

  Timer? _debounceTimer;
  String _selectedVehicle = 'bike';
  String? _selectedOrderCategoryId;
  double? _estimatedPrice;
  bool _isEstimating = false;
  bool _isSubmitting = false;
  String? _selectedCityId;
  String? _selectedVillageId;
  bool _isInitialized = false;
  bool _isDisposed = false;

  String get selectedVehicle => _selectedVehicle;
  String? get selectedOrderCategoryId => _selectedOrderCategoryId;
  double? get estimatedPrice => _estimatedPrice;
  bool get isEstimating => _isEstimating;
  bool get isSubmitting => _isSubmitting;
  String? get selectedCityId => _selectedCityId;
  String? get selectedVillageId => _selectedVillageId;

  void initialize({
    required LocationProvider locationProvider,
    required RegionProvider regionProvider,
    required OrderProvider orderProvider,
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    if (locationProvider.currentPosition == null &&
        !locationProvider.isLoading) {
      locationProvider.getCurrentLocation();
    }

    regionProvider.loadCities();
    orderProvider.loadOrderCategories();
  }

  void refreshLocation(LocationProvider locationProvider) {
    if (locationProvider.isLoading) return;
    locationProvider.getCurrentLocation();
  }

  void syncOrderCategorySelection(OrderProvider orderProvider) {
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
    required RegionProvider regionProvider,
    required LocationProvider locationProvider,
    required OrderProvider orderProvider,
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
    required RegionProvider regionProvider,
    required LocationProvider locationProvider,
    required OrderProvider orderProvider,
  }) {
    _selectedOrderCategoryId = categoryId;
    _notifyListenersSafely();
    scheduleEstimate(
      regionProvider: regionProvider,
      locationProvider: locationProvider,
      orderProvider: orderProvider,
    );
  }

  void onCityChanged(
    String? cityId, {
    required RegionProvider regionProvider,
    required LocationProvider locationProvider,
    required OrderProvider orderProvider,
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
    required RegionProvider regionProvider,
    required LocationProvider locationProvider,
    required OrderProvider orderProvider,
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
    required RegionProvider regionProvider,
    required LocationProvider locationProvider,
    required OrderProvider orderProvider,
  }) {
    scheduleEstimate(
      regionProvider: regionProvider,
      locationProvider: locationProvider,
      orderProvider: orderProvider,
    );
  }

  void scheduleEstimate({
    required RegionProvider regionProvider,
    required LocationProvider locationProvider,
    required OrderProvider orderProvider,
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
        fetchEstimate(
          regionProvider: regionProvider,
          locationProvider: locationProvider,
          orderProvider: orderProvider,
        );
      },
    );
  }

  Future<void> fetchEstimate({
    required RegionProvider regionProvider,
    required LocationProvider locationProvider,
    required OrderProvider orderProvider,
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
      _emitMessage(
        'Unable to calculate estimated delivery cost.',
        type: DeliveryRequestFormMessageType.error,
      );
    }
  }

  Future<DeliveryRequestSubmitResult> submit({
    required LocationProvider locationProvider,
    required RegionProvider regionProvider,
    required OrderProvider orderProvider,
  }) async {
    if (_selectedVehicle.isEmpty) {
      return DeliveryRequestSubmitResult.failure(
        'Please select a delivery vehicle.',
      );
    }

    if (_selectedCityId == null || _selectedCityId!.isEmpty) {
      return DeliveryRequestSubmitResult.failure(
        'Please select your city.',
      );
    }

    if (_selectedVillageId == null || _selectedVillageId!.isEmpty) {
      return DeliveryRequestSubmitResult.failure(
        'Please select your village.',
      );
    }

    if (formKey.currentState?.validate() != true) {
      return DeliveryRequestSubmitResult.failure();
    }

    final trimmedPhone = phoneNumberController.text.trim();
    final parsedPhoneNumber = int.tryParse(trimmedPhone);

    if (parsedPhoneNumber == null || trimmedPhone.length != 10) {
      return DeliveryRequestSubmitResult.failure(
        'Please enter a valid 10-digit phone number.',
      );
    }

    if (_estimatedPrice == null) {
      return DeliveryRequestSubmitResult.failure(
        'Please wait for the estimated cost before submitting.',
      );
    }

    if (_selectedOrderCategoryId == null) {
      return DeliveryRequestSubmitResult.failure(
        'Please select the order category.',
      );
    }

    final selectedCategory =
        orderProvider.categoryById(_selectedOrderCategoryId!);

    if (selectedCategory == null) {
      await orderProvider.loadOrderCategories(forceRefresh: true);
      return DeliveryRequestSubmitResult.failure(
        'The selected order category is no longer available. Please choose another.',
      );
    }

    final position = locationProvider.currentPosition;

    if (position == null) {
      return DeliveryRequestSubmitResult.failure(
        'Waiting for your current location. Please enable location services and try again.',
      );
    }

    _setSubmitting(true);

    final pickupLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
      'address': locationProvider.currentAddress ??
          composeAddress(regionProvider),
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

    final created = await orderProvider.createOrder(
      type: requestType,
      pickupLocation: pickupLocation,
      dropoffLocation: dropoffLocation,
      vehicleType: _selectedVehicle,
      orderCategory: selectedCategory.name,
      senderName: senderNameController.text.trim(),
      senderAddress: composeAddress(regionProvider),
      senderPhoneNumber: parsedPhoneNumber,
      deliveryNotes: notesController.text.trim(),
      estimatedPrice: _estimatedPrice,
    );

    if (_isDisposed) {
      return DeliveryRequestSubmitResult.failure();
    }

    _setSubmitting(false);

    if (created) {
      return DeliveryRequestSubmitResult.success(
        'Order created successfully!',
      );
    }

    return DeliveryRequestSubmitResult.failure(
      'Failed to create order',
    );
  }

  String composeAddress(RegionProvider regionProvider) {
    final parts = <String>[];

    if (_selectedCityId != null) {
      final city = regionProvider.cityById(_selectedCityId!);
      if (city != null && city.name.isNotEmpty) {
        parts.add(city.name);
      }
    }

    if (_selectedCityId != null && _selectedVillageId != null) {
      final village =
          regionProvider.villageById(_selectedCityId!, _selectedVillageId!);
      if (village != null && village.name.isNotEmpty) {
        parts.add(village.name);
      }
    }

    final manualAddress = senderAddressController.text.trim();
    if (manualAddress.isNotEmpty) {
      parts.add(manualAddress);
    }

    return parts.join(', ');
  }

  void clearMessage() {
    if (messageNotifier.value == null) return;
    messageNotifier.value = null;
  }

  void _emitMessage(
    String message, {
    DeliveryRequestFormMessageType type =
        DeliveryRequestFormMessageType.info,
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
    messageNotifier.dispose();
    super.dispose();
  }
}

