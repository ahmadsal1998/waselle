import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Wassle Driver'**
  String get appTitle;

  /// Login screen title
  ///
  /// In en, this message translates to:
  /// **'Driver Login'**
  String get driverLogin;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to start accepting deliveries'**
  String get signInToStart;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Sign up link text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get dontHaveAccount;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Email format validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get pleaseEnterValidEmail;

  /// Password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get pleaseEnterPassword;

  /// Login error message
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// Registration screen title
  ///
  /// In en, this message translates to:
  /// **'Driver Registration'**
  String get driverRegistration;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// Vehicle type dropdown label
  ///
  /// In en, this message translates to:
  /// **'Select your vehicle type'**
  String get selectVehicleType;

  /// Vehicle type validation error
  ///
  /// In en, this message translates to:
  /// **'Please select your vehicle type'**
  String get pleaseSelectVehicleType;

  /// Car vehicle type
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// Bike vehicle type
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get bike;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Phone number validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhoneNumber;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordMustBe6Chars;

  /// Registration error message
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailed;

  /// Dashboard screen title
  ///
  /// In en, this message translates to:
  /// **'Driver Dashboard'**
  String get driverDashboard;

  /// Available status text
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Active orders tab
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Order history tab
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Profile tab
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Empty state message for available orders
  ///
  /// In en, this message translates to:
  /// **'No available orders'**
  String get noAvailableOrders;

  /// Message displayed when there are no active or pending orders
  ///
  /// In en, this message translates to:
  /// **'No orders available'**
  String get noOrdersAvailable;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Order label
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// Order number format
  ///
  /// In en, this message translates to:
  /// **'Order #{id}'**
  String orderNumber(String id);

  /// Order type label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Vehicle label
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Accept button text
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// Button label for proposing a new price for rejected orders
  ///
  /// In en, this message translates to:
  /// **'Propose New Price'**
  String get proposeNewPrice;

  /// Order acceptance success message
  ///
  /// In en, this message translates to:
  /// **'Order accepted successfully!'**
  String get orderAcceptedSuccessfully;

  /// Order acceptance error message
  ///
  /// In en, this message translates to:
  /// **'Failed to accept order'**
  String get failedToAcceptOrder;

  /// Empty state message for active orders
  ///
  /// In en, this message translates to:
  /// **'No active order'**
  String get noActiveOrder;

  /// Active order title
  ///
  /// In en, this message translates to:
  /// **'Active Order'**
  String get activeOrder;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Estimated price label
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// Created date label
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// Sender section title
  ///
  /// In en, this message translates to:
  /// **'Sender'**
  String get sender;

  /// Name label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Address label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Notes section title
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Open map button text
  ///
  /// In en, this message translates to:
  /// **'Open Live Map'**
  String get openLiveMap;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Map style section title
  ///
  /// In en, this message translates to:
  /// **'Map Style'**
  String get mapStyle;

  /// Map style display text
  ///
  /// In en, this message translates to:
  /// **'Map style: {style}'**
  String mapStyleValue(String style);

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No user data message
  ///
  /// In en, this message translates to:
  /// **'No user data'**
  String get noUserData;

  /// Unknown value
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Not available abbreviation
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get nA;

  /// Availability update error message
  ///
  /// In en, this message translates to:
  /// **'Failed to update availability. Please try again.'**
  String get failedToUpdateAvailability;

  /// Language label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language name
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language name
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// OTP verification screen title
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// OTP verification title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// Phone OTP verification title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phone'**
  String get verifyYourPhone;

  /// OTP sent message
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to\n{email}'**
  String otpSentMessage(String email);

  /// Verify button text
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// OTP validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit OTP'**
  String get pleaseEnterValidOtp;

  /// Invalid OTP error message
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP. Please try again.'**
  String get invalidOtp;

  /// Order details screen title
  ///
  /// In en, this message translates to:
  /// **'Order Details'**
  String get orderDetails;

  /// Order not found message
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// Center on driver button tooltip
  ///
  /// In en, this message translates to:
  /// **'Center on Driver'**
  String get centerOnDriver;

  /// Status display format
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusValue(String status);

  /// Price display format
  ///
  /// In en, this message translates to:
  /// **'Price: {price}'**
  String priceValue(String price);

  /// Distance to customer format
  ///
  /// In en, this message translates to:
  /// **'Distance to customer: {distance} km'**
  String distanceToCustomer(String distance);

  /// Start delivery button text
  ///
  /// In en, this message translates to:
  /// **'Start Delivery'**
  String get startDelivery;

  /// Mark as delivered button text
  ///
  /// In en, this message translates to:
  /// **'Mark as Delivered'**
  String get markAsDelivered;

  /// Order status update success message
  ///
  /// In en, this message translates to:
  /// **'Order status updated to {status}'**
  String orderStatusUpdated(String status);

  /// Empty state title for order history
  ///
  /// In en, this message translates to:
  /// **'No order history'**
  String get noOrderHistory;

  /// Empty state message for order history
  ///
  /// In en, this message translates to:
  /// **'Completed orders will appear here once you start delivering.'**
  String get orderHistoryMessage;

  /// Status display in list
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusValueColon(String status);

  /// Price display in list
  ///
  /// In en, this message translates to:
  /// **'Price: {price}'**
  String priceValueColon(String price);

  /// Type display in list
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String typeValueColon(String type);

  /// Distance in kilometers
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String kilometers(String distance);

  /// Price in NIS
  ///
  /// In en, this message translates to:
  /// **'{price} NIS'**
  String nis(String price);

  /// Dialog title for selecting image source
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get selectImageSource;

  /// Success message when profile picture is updated
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated successfully'**
  String get profilePictureUpdated;

  /// Error message when profile picture update fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile picture'**
  String get failedToUpdateProfilePicture;

  /// Camera option for image source
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// Gallery option for image source
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// Order type send translation
  ///
  /// In en, this message translates to:
  /// **'send'**
  String get orderTypeSend;

  /// Order type receive translation
  ///
  /// In en, this message translates to:
  /// **'receive'**
  String get orderTypeReceive;

  /// Pickup location label
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get pickup;

  /// Drop-off location label
  ///
  /// In en, this message translates to:
  /// **'Drop-off'**
  String get dropoff;

  /// Start navigation button text
  ///
  /// In en, this message translates to:
  /// **'Start Navigation'**
  String get startNavigation;

  /// Call customer button text
  ///
  /// In en, this message translates to:
  /// **'Call Customer'**
  String get callCustomer;

  /// View details button text
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// Driver earnings label
  ///
  /// In en, this message translates to:
  /// **'Driver Earnings'**
  String get driverEarnings;

  /// New order status
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// In progress status
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Pending order status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// Accepted order status
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get statusAccepted;

  /// On the way order status
  ///
  /// In en, this message translates to:
  /// **'On The Way'**
  String get statusOnTheWay;

  /// Delivered order status
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get statusDelivered;

  /// Order contents button label
  ///
  /// In en, this message translates to:
  /// **'Order Contents'**
  String get orderContents;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Order history screen title
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// Total orders label
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// Total delivery fees label
  ///
  /// In en, this message translates to:
  /// **'Total Delivery Fees'**
  String get totalDeliveryFees;

  /// Today filter label
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Select date filter label
  ///
  /// In en, this message translates to:
  /// **'Select Date'**
  String get selectDate;

  /// Clear filters button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Receiver section title
  ///
  /// In en, this message translates to:
  /// **'Receiver'**
  String get receiver;

  /// Delivery fee label
  ///
  /// In en, this message translates to:
  /// **'Delivery Fee'**
  String get deliveryFee;

  /// Date and time label
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateTime;

  /// Remaining balance label
  ///
  /// In en, this message translates to:
  /// **'Remaining Balance'**
  String get remainingBalance;

  /// Balance warning message
  ///
  /// In en, this message translates to:
  /// **'This balance will be deducted before account suspension'**
  String get balanceWarningMessage;

  /// Filter button label
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Delivery type label
  ///
  /// In en, this message translates to:
  /// **'Delivery Type'**
  String get deliveryType;

  /// Internal delivery option
  ///
  /// In en, this message translates to:
  /// **'Internal Delivery'**
  String get internalDelivery;

  /// External delivery option
  ///
  /// In en, this message translates to:
  /// **'External Delivery'**
  String get externalDelivery;

  /// From label for pickup location
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// To label for dropoff location
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// View more button text
  ///
  /// In en, this message translates to:
  /// **'View More'**
  String get viewMore;

  /// View less button text
  ///
  /// In en, this message translates to:
  /// **'View Less'**
  String get viewLess;

  /// Privacy Policy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Privacy Policy screen title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyTitle;

  /// Privacy Policy URL
  ///
  /// In en, this message translates to:
  /// **'https://www.wassle.ps/privacy-policy'**
  String get privacyPolicyUrl;

  /// Error message when Privacy Policy URL cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Unable to open Privacy Policy. Please check your internet connection.'**
  String get unableToOpenPrivacyPolicy;

  /// Terms of Service menu item
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Terms of Service screen title
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfServiceTitle;

  /// Terms of Service URL
  ///
  /// In en, this message translates to:
  /// **'https://www.wassle.ps/terms-of-service'**
  String get termsOfServiceUrl;

  /// Error message when Terms of Service URL cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Unable to open Terms of Service. Please check your internet connection.'**
  String get unableToOpenTermsOfService;

  /// Delete account button text
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// Delete account confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get confirmDeleteAccount;

  /// Delete account warning message
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your account data will be permanently deleted.'**
  String get deleteAccountWarning;

  /// Delete account OTP verification title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Phone'**
  String get deleteAccountOtpTitle;

  /// Delete account OTP message
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to\n{phoneNumber}\n\nPlease enter the code to confirm account deletion.'**
  String deleteAccountOtpMessage(String phoneNumber);

  /// OTP sent success message
  ///
  /// In en, this message translates to:
  /// **'OTP sent successfully'**
  String get otpSentSuccessfully;

  /// Resend OTP button text
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// Resend OTP countdown message
  ///
  /// In en, this message translates to:
  /// **'Resend OTP in {seconds}s'**
  String resendOtpIn(int seconds);

  /// Account deleted success message
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeletedSuccessfully;

  /// Delete account error message
  ///
  /// In en, this message translates to:
  /// **'Failed to delete account'**
  String get failedToDeleteAccount;

  /// Failed to send OTP error message
  ///
  /// In en, this message translates to:
  /// **'Failed to send OTP. Please try again.'**
  String get failedToSendOtp;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Title for price input dialog
  ///
  /// In en, this message translates to:
  /// **'Set Delivery Price'**
  String get setDeliveryPrice;

  /// Estimated price label
  ///
  /// In en, this message translates to:
  /// **'Estimated Price'**
  String get estimatedPrice;

  /// Instruction for entering final price
  ///
  /// In en, this message translates to:
  /// **'Enter the final delivery price:'**
  String get enterFinalPrice;

  /// Price validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get enterValidPrice;

  /// NIS currency symbol
  ///
  /// In en, this message translates to:
  /// **'₪'**
  String get nisSymbol;

  /// Info message about price being sent to customer
  ///
  /// In en, this message translates to:
  /// **'This price will be sent to the customer for approval'**
  String get priceWillBeSentToCustomer;

  /// Confirm price button text
  ///
  /// In en, this message translates to:
  /// **'Confirm Price'**
  String get confirmPrice;

  /// Message when order is accepted but price proposal failed
  ///
  /// In en, this message translates to:
  /// **'Order accepted. Price proposal pending.'**
  String get orderAcceptedPricePending;

  /// Success message when price is proposed
  ///
  /// In en, this message translates to:
  /// **'Price proposed successfully. Waiting for customer approval.'**
  String get priceProposedSuccessfully;

  /// Status message when waiting for price approval
  ///
  /// In en, this message translates to:
  /// **'Waiting for customer to approve the price'**
  String get waitingForPriceApproval;

  /// Status when customer accepted the price
  ///
  /// In en, this message translates to:
  /// **'Price Accepted'**
  String get priceAccepted;

  /// Status when customer rejected the price
  ///
  /// In en, this message translates to:
  /// **'Price Rejected'**
  String get priceRejected;

  /// Label for proposed price
  ///
  /// In en, this message translates to:
  /// **'Proposed Price'**
  String get proposedPrice;

  /// Label for final price
  ///
  /// In en, this message translates to:
  /// **'Final Price'**
  String get finalPrice;

  /// Price status when pending driver proposal
  ///
  /// In en, this message translates to:
  /// **'Waiting for price proposal'**
  String get priceStatusPending;

  /// Price status when proposed to customer
  ///
  /// In en, this message translates to:
  /// **'Price proposed, waiting for customer'**
  String get priceStatusProposed;

  /// Account suspended screen title
  ///
  /// In en, this message translates to:
  /// **'Account Suspended'**
  String get accountSuspended;

  /// Account suspended main message
  ///
  /// In en, this message translates to:
  /// **'Your account has been temporarily suspended.'**
  String get accountSuspendedMessage;

  /// Account suspended detailed explanation
  ///
  /// In en, this message translates to:
  /// **'Your balance has reached or exceeded the maximum allowed limit. Please contact the administrator to make a payment and reactivate your account.'**
  String get accountSuspendedDetails;

  /// Current balance label
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get currentBalance;

  /// Maximum allowed balance label
  ///
  /// In en, this message translates to:
  /// **'Maximum Allowed'**
  String get maximumAllowed;

  /// Payment required message with amount
  ///
  /// In en, this message translates to:
  /// **'You need to pay {amount} NIS to reactivate your account.'**
  String paymentRequiredMessage(String amount);

  /// Check account status button text
  ///
  /// In en, this message translates to:
  /// **'Check Account Status'**
  String get checkAccountStatus;

  /// Checking status message
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// Welcome message on terms acceptance screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Wassle Driver'**
  String get welcomeToApp;

  /// Description text on terms acceptance screen
  ///
  /// In en, this message translates to:
  /// **'Please read and accept our Terms of Service and Privacy Policy to continue using the app.'**
  String get termsAcceptanceDescription;

  /// Text for Terms of Service card
  ///
  /// In en, this message translates to:
  /// **'Read our Terms of Service'**
  String get readTermsOfService;

  /// Text for Privacy Policy card
  ///
  /// In en, this message translates to:
  /// **'Read our Privacy Policy'**
  String get readPrivacyPolicy;

  /// Accept button text on terms acceptance screen
  ///
  /// In en, this message translates to:
  /// **'Accept and Continue'**
  String get acceptAndContinue;

  /// Info text below accept button
  ///
  /// In en, this message translates to:
  /// **'By tapping Accept, you agree to our Terms of Service and Privacy Policy.'**
  String get termsAcceptanceInfo;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
