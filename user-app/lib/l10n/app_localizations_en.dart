// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Delivery User App';

  @override
  String get welcomeBack => 'Welcome Back';

  @override
  String get signInToContinue => 'Sign in to continue';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get dontHaveAccount => 'Don\'t have an account? Sign Up';

  @override
  String get pleaseEnterEmail => 'Please enter your email';

  @override
  String get pleaseEnterValidEmail => 'Please enter a valid email';

  @override
  String get pleaseEnterPassword => 'Please enter your password';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get fullName => 'Full Name';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter your phone number';

  @override
  String get passwordMustBe6Chars => 'Password must be at least 6 characters';

  @override
  String get registrationFailed => 'Registration failed. Please try again.';

  @override
  String get verifyEmail => 'Verify Email';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get verifyYourPhone => 'Verify Your Phone';

  @override
  String otpSentMessage(String email) {
    return 'We sent a verification code to\n$email';
  }

  @override
  String get verify => 'Verify';

  @override
  String get pleaseEnterValidOtp => 'Please enter a valid 6-digit OTP';

  @override
  String get invalidOtp => 'Invalid OTP. Please try again.';

  @override
  String get discover => 'Discover';

  @override
  String get profile => 'Profile';

  @override
  String get trackOrder => 'Track Order';

  @override
  String get orderHistory => 'Order History';

  @override
  String get trackOrders => 'Track Orders';

  @override
  String get sendRequest => 'Send Request';

  @override
  String get receiveRequest => 'Receive Request';

  @override
  String get sendDelivery => 'Send Delivery';

  @override
  String get noUserData => 'No user data';

  @override
  String get unknown => 'Unknown';

  @override
  String get mapStyle => 'Map Style';

  @override
  String mapStyleValue(String style) {
    return 'Map style: $style';
  }

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get noOrdersYet => 'No orders yet';

  @override
  String get order => 'Order';

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get status => 'Status';

  @override
  String get price => 'Price';

  @override
  String get refresh => 'Refresh';

  @override
  String get noActiveOrders => 'No active orders';

  @override
  String get loading => 'Loading...';

  @override
  String get unknownDate => 'Unknown date';

  @override
  String get created => 'Created';

  @override
  String get deliveryDetails => 'Delivery Details';

  @override
  String get chooseHowToSend => 'Choose how you would like to send your package.';

  @override
  String get pickupLocation => 'Pickup Location';

  @override
  String get tellUsWhereToCollect => 'Tell us where to collect your package.';

  @override
  String get senderDetails => 'Sender Details';

  @override
  String get whoShouldDriverContact => 'Who should the driver contact on arrival?';

  @override
  String get deliveryNotes => 'Delivery Notes';

  @override
  String get shareHelpfulTips => 'Share any helpful tips for the driver.';

  @override
  String get estimatedCost => 'Estimated Cost';

  @override
  String get weUpdateAsYouComplete => 'We update this as you complete the form.';

  @override
  String get bike => 'Bike';

  @override
  String get car => 'Car';

  @override
  String get cargo => 'Cargo';

  @override
  String get soon => 'Soon';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get locatingYou => 'Locating you...';

  @override
  String get weUseCurrentLocation => 'We use your current location to pre-fill pickup details.';

  @override
  String get fetchingLocation => 'Fetching location...';

  @override
  String get retryLocation => 'Retry location';

  @override
  String get pickupFromYourLocation => 'Pickup from your location';

  @override
  String get updating => 'Updating...';

  @override
  String get refreshLocation => 'Refresh location';

  @override
  String get selectOrderType => 'Select the order type';

  @override
  String get orderType => 'Order Type';

  @override
  String get pleaseWaitForCategories => 'Please wait for categories to load';

  @override
  String get noOrderCategoriesAvailable => 'No order categories available at the moment';

  @override
  String get pleaseSelectOrderType => 'Please select the order type';

  @override
  String get retry => 'Retry';

  @override
  String get noCategoriesTryLater => 'No order categories available. Please try again later.';

  @override
  String get city => 'City';

  @override
  String get noActiveCitiesAvailable => 'No active cities available at the moment';

  @override
  String get pleaseSelectCity => 'Please select a city';

  @override
  String get loadingVillages => 'Loading villages...';

  @override
  String get village => 'Village';

  @override
  String get selectCityFirst => 'Select a city first';

  @override
  String get noActiveVillagesForCity => 'No active villages available for this city';

  @override
  String get pleaseSelectVillage => 'Please select a village';

  @override
  String get senderName => 'Sender Name';

  @override
  String get pleaseEnterSenderName => 'Please enter the sender name';

  @override
  String get streetAddressDetails => 'Street Address / Details';

  @override
  String get streetBuildingFloorApartment => 'Street, building, floor, apartment...';

  @override
  String get pleaseEnterSenderAddress => 'Please enter the sender address';

  @override
  String get provideDirections => 'Provide directions, building access codes, or other details.';

  @override
  String get pleaseEnterDeliveryNotes => 'Please enter delivery notes';

  @override
  String get liveCostPreview => 'Live cost preview';

  @override
  String get selectVehicleAndEnterAddress => 'Select a vehicle and enter your pickup address to see the estimate.';

  @override
  String get estimateNote => 'The displayed cost is an estimate and may vary based on actual distance.';

  @override
  String get deliveryStartsFrom => 'Delivery starts from';

  @override
  String get submitting => 'Submitting...';

  @override
  String get submitRequest => 'Submit Request';

  @override
  String get unableToCalculateEstimate => 'Unable to calculate estimated delivery cost.';

  @override
  String get pleaseSelectDeliveryVehicle => 'Please select a delivery vehicle.';

  @override
  String get pleaseSelectYourCity => 'Please select your city.';

  @override
  String get pleaseSelectYourVillage => 'Please select your village.';

  @override
  String get pleaseEnterValidPhoneNumber => 'Please enter a valid 10-digit phone number.';

  @override
  String get waitForEstimatedCost => 'Please wait for the estimated cost before submitting.';

  @override
  String get pleaseSelectOrderCategory => 'Please select the order category.';

  @override
  String get orderCategoryNoLongerAvailable => 'The selected order category is no longer available. Please choose another.';

  @override
  String get waitingForLocation => 'Waiting for your current location. Please enable location services and try again.';

  @override
  String get orderCreatedSuccessfully => 'Order created successfully!';

  @override
  String get failedToCreateOrder => 'Failed to create order';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get type => 'Type';

  @override
  String get category => 'Category';

  @override
  String get distance => 'Distance';

  @override
  String kilometers(String distance) {
    return '$distance km';
  }

  @override
  String nis(String price) {
    return '$price NIS';
  }

  @override
  String get deliveryType => 'Delivery Type';

  @override
  String get internalDelivery => 'Internal Delivery';

  @override
  String get externalDelivery => 'External Delivery';

  @override
  String get selectDeliveryType => 'Select delivery type';

  @override
  String get pleaseSelectDeliveryType => 'Please select a delivery type';

  @override
  String get internalDeliveryDescription => 'Delivery within 2 km radius (configurable by admin)';

  @override
  String get externalDeliveryDescription => 'Delivery within 10 km radius (configurable by admin)';

  @override
  String get orderProgress => 'Order Progress';

  @override
  String get showOrderProgress => 'Show Order Progress';

  @override
  String get hideOrderProgress => 'Hide Order Progress';

  @override
  String get tapToOpenMap => 'Tap to open map';

  @override
  String get orderPlaced => 'Order Placed';

  @override
  String get orderPlacedDescription => 'Your order has been placed and is waiting for a driver';

  @override
  String get orderAccepted => 'Order Accepted';

  @override
  String get orderAcceptedDescription => 'A driver has accepted your order';

  @override
  String get onTheWay => 'On the Way';

  @override
  String get onTheWayDescription => 'Driver is on the way to your location';

  @override
  String get delivered => 'Delivered';

  @override
  String get deliveredDescription => 'Your order has been successfully delivered';

  @override
  String get current => 'Current';
}
