import 'package:latlong2/latlong.dart';

/// Mock data provider for Review Mode.
/// Contains all test data needed for Apple App Store review:
/// - Test user account
/// - Predefined addresses
/// - Sample orders
/// - Test driver information
/// - Predefined routes
class ReviewModeMockData {
  // Test User Account
  static Map<String, dynamic> get testUser => {
        '_id': 'review_mode_test_user_12345',
        'name': 'App Review Tester',
        'email': 'reviewer@apple.com',
        'phoneNumber': '+972501234567',
        'role': 'customer',
        'preferredLanguage': 'en',
        'createdAt': DateTime.now().toIso8601String(),
        'isReviewModeUser': true,
      };

  // Predefined Addresses
  static List<Map<String, dynamic>> get testAddresses => [
        {
          'id': 'addr_1',
          'name': 'Central Market',
          'fullAddress': 'Ramallah City Center, Ramallah, Palestine',
          'city': 'Ramallah',
          'village': 'City Center',
          'streetDetails': 'Near the Central Market',
          'location': {
            'lat': 31.9074,
            'lng': 35.2063,
          },
          'isDefault': true,
        },
        {
          'id': 'addr_2',
          'name': 'Al-Bireh Park',
          'fullAddress': 'Al-Bireh Park, Al-Bireh, Palestine',
          'city': 'Al-Bireh',
          'village': 'Downtown',
          'streetDetails': 'Next to the main park entrance',
          'location': {
            'lat': 31.9130,
            'lng': 35.2162,
          },
          'isDefault': false,
        },
        {
          'id': 'addr_3',
          'name': 'Birzeit University',
          'fullAddress': 'Birzeit University, Birzeit, Palestine',
          'city': 'Birzeit',
          'village': 'University Area',
          'streetDetails': 'Main campus entrance',
          'location': {
            'lat': 31.9617,
            'lng': 35.1894,
          },
          'isDefault': false,
        },
      ];

  // Test Driver Information
  static Map<String, dynamic> get testDriver => {
        '_id': 'review_mode_test_driver_67890',
        'name': 'Review Test Driver',
        'email': 'driver@test.com',
        'phoneNumber': '+972509876543',
        'role': 'driver',
        'isAvailable': true,
        'vehicleType': 'motorcycle',
        'location': {
          'lat': 31.9100,
          'lng': 35.2100,
        },
        'isReviewModeDriver': true,
      };

  // Sample Orders
  static List<Map<String, dynamic>> get sampleOrders => [
        {
          '_id': 'review_order_001',
          'type': 'send',
          'deliveryType': 'express',
          'status': 'accepted',
          'vehicleType': 'motorcycle',
          'orderCategory': 'documents',
          'senderName': 'App Review Tester',
          'senderCity': 'Ramallah',
          'senderVillage': 'City Center',
          'senderStreetDetails': 'Near the Central Market',
          'senderPhoneNumber': 501234567,
          'pickupLocation': {
            'address': 'Ramallah City Center, Ramallah, Palestine',
            'city': 'Ramallah',
            'village': 'City Center',
            'streetDetails': 'Near the Central Market',
            'lat': 31.9074,
            'lng': 35.2063,
          },
          'dropoffLocation': {
            'address': 'Al-Bireh Park, Al-Bireh, Palestine',
            'city': 'Al-Bireh',
            'village': 'Downtown',
            'streetDetails': 'Next to the main park entrance',
            'lat': 31.9130,
            'lng': 35.2162,
          },
          'driver': testDriver,
          'estimatedPrice': 25.0,
          'finalPrice': 25.0,
          'priceStatus': 'accepted',
          'createdAt': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(minutes: 30)).toIso8601String(),
          'isReviewModeOrder': true,
        },
        {
          '_id': 'review_order_002',
          'type': 'receive',
          'deliveryType': 'standard',
          'status': 'pending',
          'vehicleType': 'car',
          'orderCategory': 'food',
          'senderName': 'Test Sender',
          'senderCity': 'Birzeit',
          'senderVillage': 'University Area',
          'senderStreetDetails': 'Main campus entrance',
          'senderPhoneNumber': 501111111,
          'pickupLocation': {
            'address': 'Birzeit University, Birzeit, Palestine',
            'city': 'Birzeit',
            'village': 'University Area',
            'streetDetails': 'Main campus entrance',
            'lat': 31.9617,
            'lng': 35.1894,
          },
          'dropoffLocation': {
            'address': 'Ramallah City Center, Ramallah, Palestine',
            'city': 'Ramallah',
            'village': 'City Center',
            'streetDetails': 'Near the Central Market',
            'lat': 31.9074,
            'lng': 35.2063,
          },
          'estimatedPrice': 35.0,
          'finalPrice': null,
          'priceStatus': 'pending',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String(),
          'isReviewModeOrder': true,
        },
        {
          '_id': 'review_order_003',
          'type': 'send',
          'deliveryType': 'express',
          'status': 'on_the_way',
          'vehicleType': 'motorcycle',
          'orderCategory': 'parcel',
          'senderName': 'App Review Tester',
          'senderCity': 'Al-Bireh',
          'senderVillage': 'Downtown',
          'senderStreetDetails': 'Next to the main park entrance',
          'senderPhoneNumber': 501234567,
          'pickupLocation': {
            'address': 'Al-Bireh Park, Al-Bireh, Palestine',
            'city': 'Al-Bireh',
            'village': 'Downtown',
            'streetDetails': 'Next to the main park entrance',
            'lat': 31.9130,
            'lng': 35.2162,
          },
          'dropoffLocation': {
            'address': 'Birzeit University, Birzeit, Palestine',
            'city': 'Birzeit',
            'village': 'University Area',
            'streetDetails': 'Main campus entrance',
            'lat': 31.9617,
            'lng': 35.1894,
          },
          'driver': testDriver,
          'estimatedPrice': 30.0,
          'finalPrice': 30.0,
          'priceStatus': 'accepted',
          'createdAt': DateTime.now().subtract(const Duration(minutes: 45)).toIso8601String(),
          'updatedAt': DateTime.now().subtract(const Duration(minutes: 20)).toIso8601String(),
          'isReviewModeOrder': true,
        },
      ];

  // Predefined Route (for testing order tracking)
  static List<LatLng> get testRoute => [
        const LatLng(31.9074, 35.2063), // Start: Ramallah City Center
        const LatLng(31.9085, 35.2075),
        const LatLng(31.9095, 35.2085),
        const LatLng(31.9105, 35.2095),
        const LatLng(31.9115, 35.2105),
        const LatLng(31.9125, 35.2115),
        const LatLng(31.9130, 35.2162), // End: Al-Bireh Park
      ];

  // Test Driver Locations (for map display)
  static List<Map<String, dynamic>> get testDriverLocations => [
        {
          '_id': 'review_mode_test_driver_67890',
          'name': 'Review Test Driver',
          'isAvailable': true,
          'location': {
            'lat': 31.9100,
            'lng': 35.2100,
          },
        },
        {
          '_id': 'review_mode_test_driver_67891',
          'name': 'Review Test Driver 2',
          'isAvailable': true,
          'location': {
            'lat': 31.9150,
            'lng': 35.2150,
          },
        },
      ];

  // Default Location (Ramallah center)
  static LatLng get defaultLocation => const LatLng(31.9074, 35.2063);

  // Default Address String
  static String get defaultAddress => 'Ramallah City Center, Ramallah, Palestine';

  // Helper method to check if data is from Review Mode
  static bool isReviewModeData(Map<String, dynamic> data) {
    return data['isReviewModeUser'] == true ||
        data['isReviewModeOrder'] == true ||
        data['isReviewModeDriver'] == true;
  }
}

