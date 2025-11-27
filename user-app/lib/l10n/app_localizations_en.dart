// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wassle';

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
  String get selectMapStyle => 'Select Map Style';

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
  String get sendRequestNotesHint => 'Enter send request details';

  @override
  String get receiveRequestNotesHint => 'Enter receive request details';

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
  String get noDriversAvailable => 'No drivers found within the service area. Please try again later.';

  @override
  String get requestSentSuccessfully => 'Request Sent Successfully';

  @override
  String get requestSentSuccessMessage => 'Your delivery request has been received and is being processed. You will be notified when a driver accepts your request.';

  @override
  String get backToHome => 'Back to Home';

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
  String get pending => 'Pending';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get current => 'Current';

  @override
  String get dropoffLocation => 'Dropoff Location';

  @override
  String get estimatedTime => 'Estimated Time';

  @override
  String minutes(String minutes) {
    return '$minutes min';
  }

  @override
  String get phone => 'Phone';

  @override
  String get notes => 'Notes';

  @override
  String get refreshNearbyDrivers => 'Refresh Nearby Drivers';

  @override
  String get currentLocation => 'Current Location';

  @override
  String get locate => 'Locate';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get viewMore => 'View More';

  @override
  String get viewLess => 'View Less';

  @override
  String get mapView => 'Map View';

  @override
  String get driverInformation => 'Driver Information';

  @override
  String get savedAddresses => 'Saved Addresses';

  @override
  String get addAddress => 'Add Address';

  @override
  String get editAddress => 'Edit Address';

  @override
  String get addressLabel => 'Label (e.g., Home, Work)';

  @override
  String get pleaseEnterLabel => 'Please enter a label';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get gettingLocation => 'Getting location...';

  @override
  String get villageArea => 'Village/Area';

  @override
  String get saveAddress => 'Save Address';

  @override
  String get updateAddress => 'Update Address';

  @override
  String get pleaseEnableLocationServices => 'Please enable location services';

  @override
  String get pleaseEnableLocationToSave => 'Please enable location services to save address';

  @override
  String get failedToSaveAddress => 'Failed to save address';

  @override
  String get deleteAddress => 'Delete Address';

  @override
  String confirmDeleteAddress(String label) {
    return 'Are you sure you want to delete \"$label\"?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get addressDeletedSuccessfully => 'Address deleted successfully';

  @override
  String get failedToDeleteAddress => 'Failed to delete address';

  @override
  String get noSavedAddresses => 'No Saved Addresses';

  @override
  String get addAddressesToQuicklySelect => 'Add addresses to quickly select them when placing orders';

  @override
  String get edit => 'Edit';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyTitle => 'Privacy Policy';

  @override
  String get privacyPolicyUrl => 'https://www.wassle.ps/privacy-policy';

  @override
  String get unableToOpenPrivacyPolicy => 'Unable to open Privacy Policy. Please check your internet connection.';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceTitle => 'Terms of Service';

  @override
  String get termsOfServiceUrl => 'https://www.wassle.ps/terms-of-service';

  @override
  String get unableToOpenTermsOfService => 'Unable to open Terms of Service. Please check your internet connection.';

  @override
  String get manageSavedAddresses => 'Manage your saved addresses';

  @override
  String get readPrivacyPolicy => 'Read our privacy policy';

  @override
  String get readTermsOfService => 'Read our terms of service';

  @override
  String get legal => 'Legal';

  @override
  String get notAvailable => 'Not available';

  @override
  String get initializing => 'Initializing';

  @override
  String get initializingSubtitle => 'Hang tight while we find couriers around you.';

  @override
  String get locationDisabled => 'Location Disabled';

  @override
  String get locationDisabledSubtitle => 'We could not access your location. Please enable location services.';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get locationNotFound => 'Location Not Found';

  @override
  String get locationNotFoundSubtitle => 'Tap the button below to refresh your location and explore drivers nearby.';

  @override
  String get getLocation => 'Get Location';

  @override
  String get unknownLocation => 'Unknown location';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get confirmDeleteAccount => 'Are you sure you want to delete your account?';

  @override
  String get deleteAccountWarning => 'This action cannot be undone. All your account data will be permanently deleted.';

  @override
  String get deleteAccountOtpTitle => 'Verify Your Phone';

  @override
  String deleteAccountOtpMessage(String phoneNumber) {
    return 'We sent a verification code to\n$phoneNumber\n\nPlease enter the code to confirm account deletion.';
  }

  @override
  String get otpSentSuccessfully => 'OTP sent successfully';

  @override
  String get resendOtp => 'Resend OTP';

  @override
  String resendOtpIn(int seconds) {
    return 'Resend OTP in ${seconds}s';
  }

  @override
  String get accountDeletedSuccessfully => 'Account deleted successfully';

  @override
  String get failedToDeleteAccount => 'Failed to delete account';

  @override
  String get failedToSendOtp => 'Failed to send OTP. Please try again.';

  @override
  String get confirm => 'Confirm';

  @override
  String get priceProposalReceived => 'Price Proposal Received';

  @override
  String get driverProposedPrice => 'The driver has proposed a delivery price';

  @override
  String get estimatedPrice => 'Estimated Price';

  @override
  String get finalPrice => 'Final Price';

  @override
  String get acceptPrice => 'Accept Price';

  @override
  String get rejectPrice => 'Reject';

  @override
  String get priceAcceptedSuccess => 'Price accepted! The driver will start the delivery.';

  @override
  String get priceRejectedSuccess => 'Price rejected. The driver will propose a new price.';

  @override
  String get failedToRespondToPrice => 'Failed to respond to price. Please try again.';

  @override
  String get waitingForPrice => 'Waiting for driver to set the delivery price';

  @override
  String get priceProposed => 'Price proposed, waiting for confirmation';

  @override
  String get priceAccepted => 'Price confirmed';

  @override
  String get deliveryPriceOffers => 'Delivery Price Offers';

  @override
  String get noPriceOffers => 'No price offers available';

  @override
  String get proposedPrice => 'Proposed Price';

  @override
  String get acceptOffer => 'Accept';

  @override
  String get rejectOffer => 'Reject';

  @override
  String get offerAccepted => 'Offer accepted successfully';

  @override
  String get offerRejected => 'Offer rejected';

  @override
  String get failedToLoadOffers => 'Failed to load price offers';

  @override
  String get viewPriceOffers => 'View and respond to price offers';
}
