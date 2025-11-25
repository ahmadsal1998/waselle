// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Delivery Driver App';

  @override
  String get driverLogin => 'Driver Login';

  @override
  String get signInToStart => 'Sign in to start accepting deliveries';

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
  String get driverRegistration => 'Driver Registration';

  @override
  String get fullName => 'Full Name';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get selectVehicleType => 'Select your vehicle type';

  @override
  String get pleaseSelectVehicleType => 'Please select your vehicle type';

  @override
  String get car => 'Car';

  @override
  String get bike => 'Bike';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get pleaseEnterPhoneNumber => 'Please enter your phone number';

  @override
  String get passwordMustBe6Chars => 'Password must be at least 6 characters';

  @override
  String get registrationFailed => 'Registration failed. Please try again.';

  @override
  String get driverDashboard => 'Driver Dashboard';

  @override
  String get available => 'Available';

  @override
  String get active => 'Active';

  @override
  String get history => 'History';

  @override
  String get profile => 'Profile';

  @override
  String get noAvailableOrders => 'No available orders';

  @override
  String get noOrdersAvailable => 'No orders available';

  @override
  String get refresh => 'Refresh';

  @override
  String get order => 'Order';

  @override
  String orderNumber(String id) {
    return 'Order #$id';
  }

  @override
  String get type => 'Type';

  @override
  String get vehicle => 'Vehicle';

  @override
  String get price => 'Price';

  @override
  String get distance => 'Distance';

  @override
  String get accept => 'Accept';

  @override
  String get orderAcceptedSuccessfully => 'Order accepted successfully!';

  @override
  String get failedToAcceptOrder => 'Failed to accept order';

  @override
  String get noActiveOrder => 'No active order';

  @override
  String get activeOrder => 'Active Order';

  @override
  String get status => 'Status';

  @override
  String get category => 'Category';

  @override
  String get estimated => 'Estimated';

  @override
  String get created => 'Created';

  @override
  String get sender => 'Sender';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get notes => 'Notes';

  @override
  String get openLiveMap => 'Open Live Map';

  @override
  String get settings => 'Settings';

  @override
  String get mapStyle => 'Map Style';

  @override
  String mapStyleValue(String style) {
    return 'Map style: $style';
  }

  @override
  String get logout => 'Logout';

  @override
  String get noUserData => 'No user data';

  @override
  String get unknown => 'Unknown';

  @override
  String get nA => 'N/A';

  @override
  String get failedToUpdateAvailability => 'Failed to update availability. Please try again.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'Arabic';

  @override
  String get selectLanguage => 'Select Language';

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
  String get orderDetails => 'Order Details';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get centerOnDriver => 'Center on Driver';

  @override
  String statusValue(String status) {
    return 'Status: $status';
  }

  @override
  String priceValue(String price) {
    return 'Price: $price';
  }

  @override
  String distanceToCustomer(String distance) {
    return 'Distance to customer: $distance km';
  }

  @override
  String get startDelivery => 'Start Delivery';

  @override
  String get markAsDelivered => 'Mark as Delivered';

  @override
  String orderStatusUpdated(String status) {
    return 'Order status updated to $status';
  }

  @override
  String get noOrderHistory => 'No order history';

  @override
  String get orderHistoryMessage => 'Completed orders will appear here once you start delivering.';

  @override
  String statusValueColon(String status) {
    return 'Status: $status';
  }

  @override
  String priceValueColon(String price) {
    return 'Price: $price';
  }

  @override
  String typeValueColon(String type) {
    return 'Type: $type';
  }

  @override
  String kilometers(String distance) {
    return '$distance km';
  }

  @override
  String nis(String price) {
    return '$price NIS';
  }

  @override
  String get selectImageSource => 'Select Image Source';

  @override
  String get profilePictureUpdated => 'Profile picture updated successfully';

  @override
  String get failedToUpdateProfilePicture => 'Failed to update profile picture';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String get orderTypeSend => 'send';

  @override
  String get orderTypeReceive => 'receive';

  @override
  String get pickup => 'Pickup';

  @override
  String get dropoff => 'Drop-off';

  @override
  String get startNavigation => 'Start Navigation';

  @override
  String get callCustomer => 'Call Customer';

  @override
  String get viewDetails => 'View Details';

  @override
  String get driverEarnings => 'Driver Earnings';

  @override
  String get statusNew => 'New';

  @override
  String get inProgress => 'In Progress';

  @override
  String get completed => 'Completed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusAccepted => 'Accepted';

  @override
  String get statusOnTheWay => 'On The Way';

  @override
  String get statusDelivered => 'Delivered';

  @override
  String get orderContents => 'Order Contents';

  @override
  String get close => 'Close';

  @override
  String get orderHistory => 'Order History';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get totalDeliveryFees => 'Total Delivery Fees';

  @override
  String get today => 'Today';

  @override
  String get selectDate => 'Select Date';

  @override
  String get clear => 'Clear';

  @override
  String get receiver => 'Receiver';

  @override
  String get deliveryFee => 'Delivery Fee';

  @override
  String get dateTime => 'Date & Time';

  @override
  String get remainingBalance => 'Remaining Balance';

  @override
  String get balanceWarningMessage => 'This balance will be deducted before account suspension';

  @override
  String get filter => 'Filter';

  @override
  String get deliveryType => 'Delivery Type';

  @override
  String get internalDelivery => 'Internal Delivery';

  @override
  String get externalDelivery => 'External Delivery';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get viewMore => 'View More';

  @override
  String get viewLess => 'View Less';
}
