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
  /// **'Wassle'**
  String get appTitle;

  /// Login screen welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get welcomeBack;

  /// Login screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue'**
  String get signInToContinue;

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

  /// Discover tab title
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discover;

  /// Profile tab title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Track order tab title
  ///
  /// In en, this message translates to:
  /// **'Track Order'**
  String get trackOrder;

  /// Order history tab title
  ///
  /// In en, this message translates to:
  /// **'Order History'**
  String get orderHistory;

  /// Track orders screen title
  ///
  /// In en, this message translates to:
  /// **'Track Orders'**
  String get trackOrders;

  /// Send request screen title
  ///
  /// In en, this message translates to:
  /// **'Send Request'**
  String get sendRequest;

  /// Receive request screen title
  ///
  /// In en, this message translates to:
  /// **'Receive Request'**
  String get receiveRequest;

  /// Send delivery button text
  ///
  /// In en, this message translates to:
  /// **'Send Delivery'**
  String get sendDelivery;

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

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

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

  /// Empty state message for order history
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get noOrdersYet;

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

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Price label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Empty state message for active orders
  ///
  /// In en, this message translates to:
  /// **'No active orders'**
  String get noActiveOrders;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Unknown date text
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknownDate;

  /// Created date label
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// Delivery details section title
  ///
  /// In en, this message translates to:
  /// **'Delivery Details'**
  String get deliveryDetails;

  /// Delivery details subtitle
  ///
  /// In en, this message translates to:
  /// **'Choose how you would like to send your package.'**
  String get chooseHowToSend;

  /// Pickup location section title
  ///
  /// In en, this message translates to:
  /// **'Pickup Location'**
  String get pickupLocation;

  /// Pickup location subtitle
  ///
  /// In en, this message translates to:
  /// **'Tell us where to collect your package.'**
  String get tellUsWhereToCollect;

  /// Sender details section title
  ///
  /// In en, this message translates to:
  /// **'Sender Details'**
  String get senderDetails;

  /// Sender details subtitle
  ///
  /// In en, this message translates to:
  /// **'Who should the driver contact on arrival?'**
  String get whoShouldDriverContact;

  /// Delivery notes section title
  ///
  /// In en, this message translates to:
  /// **'Delivery Notes'**
  String get deliveryNotes;

  /// Delivery notes subtitle
  ///
  /// In en, this message translates to:
  /// **'Share any helpful tips for the driver.'**
  String get shareHelpfulTips;

  /// Estimated cost section title
  ///
  /// In en, this message translates to:
  /// **'Estimated Cost'**
  String get estimatedCost;

  /// Estimated cost subtitle
  ///
  /// In en, this message translates to:
  /// **'We update this as you complete the form.'**
  String get weUpdateAsYouComplete;

  /// Bike vehicle type
  ///
  /// In en, this message translates to:
  /// **'Bike'**
  String get bike;

  /// Car vehicle type
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get car;

  /// Cargo vehicle type
  ///
  /// In en, this message translates to:
  /// **'Cargo'**
  String get cargo;

  /// Coming soon badge
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get soon;

  /// Coming soon tooltip
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Location loading message
  ///
  /// In en, this message translates to:
  /// **'Locating you...'**
  String get locatingYou;

  /// Location explanation
  ///
  /// In en, this message translates to:
  /// **'We use your current location to pre-fill pickup details.'**
  String get weUseCurrentLocation;

  /// Fetching location message
  ///
  /// In en, this message translates to:
  /// **'Fetching location...'**
  String get fetchingLocation;

  /// Retry location button
  ///
  /// In en, this message translates to:
  /// **'Retry location'**
  String get retryLocation;

  /// Pickup location header
  ///
  /// In en, this message translates to:
  /// **'Pickup from your location'**
  String get pickupFromYourLocation;

  /// Updating message
  ///
  /// In en, this message translates to:
  /// **'Updating...'**
  String get updating;

  /// Refresh location button
  ///
  /// In en, this message translates to:
  /// **'Refresh location'**
  String get refreshLocation;

  /// Order type dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select the order type'**
  String get selectOrderType;

  /// Order type label
  ///
  /// In en, this message translates to:
  /// **'Order Type'**
  String get orderType;

  /// Categories loading validation error
  ///
  /// In en, this message translates to:
  /// **'Please wait for categories to load'**
  String get pleaseWaitForCategories;

  /// No categories available validation error
  ///
  /// In en, this message translates to:
  /// **'No order categories available at the moment'**
  String get noOrderCategoriesAvailable;

  /// Order type validation error
  ///
  /// In en, this message translates to:
  /// **'Please select the order type'**
  String get pleaseSelectOrderType;

  /// Retry button
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No categories available message
  ///
  /// In en, this message translates to:
  /// **'No order categories available. Please try again later.'**
  String get noCategoriesTryLater;

  /// City field label
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No cities available validation error
  ///
  /// In en, this message translates to:
  /// **'No active cities available at the moment'**
  String get noActiveCitiesAvailable;

  /// City validation error
  ///
  /// In en, this message translates to:
  /// **'Please select a city'**
  String get pleaseSelectCity;

  /// Loading villages label
  ///
  /// In en, this message translates to:
  /// **'Loading villages...'**
  String get loadingVillages;

  /// Village field label
  ///
  /// In en, this message translates to:
  /// **'Village'**
  String get village;

  /// Village validation error - no city selected
  ///
  /// In en, this message translates to:
  /// **'Select a city first'**
  String get selectCityFirst;

  /// No villages available validation error
  ///
  /// In en, this message translates to:
  /// **'No active villages available for this city'**
  String get noActiveVillagesForCity;

  /// Village validation error
  ///
  /// In en, this message translates to:
  /// **'Please select a village'**
  String get pleaseSelectVillage;

  /// Sender name field label
  ///
  /// In en, this message translates to:
  /// **'Sender Name'**
  String get senderName;

  /// Sender name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter the sender name'**
  String get pleaseEnterSenderName;

  /// Street address field label
  ///
  /// In en, this message translates to:
  /// **'Street Address / Details'**
  String get streetAddressDetails;

  /// Street address hint
  ///
  /// In en, this message translates to:
  /// **'Street, building, floor, apartment...'**
  String get streetBuildingFloorApartment;

  /// Sender address validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter the sender address'**
  String get pleaseEnterSenderAddress;

  /// Delivery notes hint
  ///
  /// In en, this message translates to:
  /// **'Provide directions, building access codes, or other details.'**
  String get provideDirections;

  /// Send request notes hint
  ///
  /// In en, this message translates to:
  /// **'Enter send request details'**
  String get sendRequestNotesHint;

  /// Receive request notes hint
  ///
  /// In en, this message translates to:
  /// **'Enter receive request details'**
  String get receiveRequestNotesHint;

  /// Delivery notes validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter delivery notes'**
  String get pleaseEnterDeliveryNotes;

  /// Live cost preview title
  ///
  /// In en, this message translates to:
  /// **'Live cost preview'**
  String get liveCostPreview;

  /// Estimate placeholder message
  ///
  /// In en, this message translates to:
  /// **'Select a vehicle and enter your pickup address to see the estimate.'**
  String get selectVehicleAndEnterAddress;

  /// Estimate disclaimer
  ///
  /// In en, this message translates to:
  /// **'The displayed cost is an estimate and may vary based on actual distance.'**
  String get estimateNote;

  /// Delivery price prefix text
  ///
  /// In en, this message translates to:
  /// **'Delivery starts from'**
  String get deliveryStartsFrom;

  /// Submitting button text
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// Submit request button text
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// Estimate calculation error
  ///
  /// In en, this message translates to:
  /// **'Unable to calculate estimated delivery cost.'**
  String get unableToCalculateEstimate;

  /// Vehicle selection error
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery vehicle.'**
  String get pleaseSelectDeliveryVehicle;

  /// City selection error
  ///
  /// In en, this message translates to:
  /// **'Please select your city.'**
  String get pleaseSelectYourCity;

  /// Village selection error
  ///
  /// In en, this message translates to:
  /// **'Please select your village.'**
  String get pleaseSelectYourVillage;

  /// Phone number validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-digit phone number.'**
  String get pleaseEnterValidPhoneNumber;

  /// Wait for estimate error
  ///
  /// In en, this message translates to:
  /// **'Please wait for the estimated cost before submitting.'**
  String get waitForEstimatedCost;

  /// Order category selection error
  ///
  /// In en, this message translates to:
  /// **'Please select the order category.'**
  String get pleaseSelectOrderCategory;

  /// Order category unavailable error
  ///
  /// In en, this message translates to:
  /// **'The selected order category is no longer available. Please choose another.'**
  String get orderCategoryNoLongerAvailable;

  /// Location waiting error
  ///
  /// In en, this message translates to:
  /// **'Waiting for your current location. Please enable location services and try again.'**
  String get waitingForLocation;

  /// Order creation success message
  ///
  /// In en, this message translates to:
  /// **'Order created successfully!'**
  String get orderCreatedSuccessfully;

  /// No drivers available notification message
  ///
  /// In en, this message translates to:
  /// **'No drivers found within the service area. Please try again later.'**
  String get noDriversAvailable;

  /// Order success screen title
  ///
  /// In en, this message translates to:
  /// **'Request Sent Successfully'**
  String get requestSentSuccessfully;

  /// Order success screen message
  ///
  /// In en, this message translates to:
  /// **'Your delivery request has been received and is being processed. You will be notified when a driver accepts your request.'**
  String get requestSentSuccessMessage;

  /// Back to home button text
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get backToHome;

  /// Order creation failure message
  ///
  /// In en, this message translates to:
  /// **'Failed to create order'**
  String get failedToCreateOrder;

  /// Vehicle label
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// Type label
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// Category label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Distance label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

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

  /// Delivery type field label
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

  /// Delivery type selection hint
  ///
  /// In en, this message translates to:
  /// **'Select delivery type'**
  String get selectDeliveryType;

  /// Delivery type validation error
  ///
  /// In en, this message translates to:
  /// **'Please select a delivery type'**
  String get pleaseSelectDeliveryType;

  /// Internal delivery description
  ///
  /// In en, this message translates to:
  /// **'Delivery within 2 km radius (configurable by admin)'**
  String get internalDeliveryDescription;

  /// External delivery description
  ///
  /// In en, this message translates to:
  /// **'Delivery within 10 km radius (configurable by admin)'**
  String get externalDeliveryDescription;

  /// Order progress section title
  ///
  /// In en, this message translates to:
  /// **'Order Progress'**
  String get orderProgress;

  /// Show order progress button text
  ///
  /// In en, this message translates to:
  /// **'Show Order Progress'**
  String get showOrderProgress;

  /// Hide order progress button text
  ///
  /// In en, this message translates to:
  /// **'Hide Order Progress'**
  String get hideOrderProgress;

  /// Tap to open map hint text
  ///
  /// In en, this message translates to:
  /// **'Tap to open map'**
  String get tapToOpenMap;

  /// Order placed stage title
  ///
  /// In en, this message translates to:
  /// **'Order Placed'**
  String get orderPlaced;

  /// Order placed stage description
  ///
  /// In en, this message translates to:
  /// **'Your order has been placed and is waiting for a driver'**
  String get orderPlacedDescription;

  /// Order accepted stage title
  ///
  /// In en, this message translates to:
  /// **'Order Accepted'**
  String get orderAccepted;

  /// Order accepted stage description
  ///
  /// In en, this message translates to:
  /// **'A driver has accepted your order'**
  String get orderAcceptedDescription;

  /// On the way stage title
  ///
  /// In en, this message translates to:
  /// **'On the Way'**
  String get onTheWay;

  /// On the way stage description
  ///
  /// In en, this message translates to:
  /// **'Driver is on the way to your location'**
  String get onTheWayDescription;

  /// Delivered stage title
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// Delivered stage description
  ///
  /// In en, this message translates to:
  /// **'Your order has been successfully delivered'**
  String get deliveredDescription;

  /// Pending order status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Cancelled order status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Current stage badge text
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// Dropoff location label
  ///
  /// In en, this message translates to:
  /// **'Dropoff Location'**
  String get dropoffLocation;

  /// Estimated time label
  ///
  /// In en, this message translates to:
  /// **'Estimated Time'**
  String get estimatedTime;

  /// Time in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutes(String minutes);

  /// Phone label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Notes label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Refresh nearby drivers button text
  ///
  /// In en, this message translates to:
  /// **'Refresh Nearby Drivers'**
  String get refreshNearbyDrivers;

  /// Current location label
  ///
  /// In en, this message translates to:
  /// **'Current Location'**
  String get currentLocation;

  /// Locate button text
  ///
  /// In en, this message translates to:
  /// **'Locate'**
  String get locate;

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

  /// Map view section title
  ///
  /// In en, this message translates to:
  /// **'Map View'**
  String get mapView;

  /// Driver information section title
  ///
  /// In en, this message translates to:
  /// **'Driver Information'**
  String get driverInformation;

  /// Saved addresses screen title
  ///
  /// In en, this message translates to:
  /// **'Saved Addresses'**
  String get savedAddresses;

  /// Add address button text
  ///
  /// In en, this message translates to:
  /// **'Add Address'**
  String get addAddress;

  /// Edit address screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Address'**
  String get editAddress;

  /// Address label field placeholder
  ///
  /// In en, this message translates to:
  /// **'Label (e.g., Home, Work)'**
  String get addressLabel;

  /// Address label validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a label'**
  String get pleaseEnterLabel;

  /// Use current location toggle label
  ///
  /// In en, this message translates to:
  /// **'Use Current Location'**
  String get useCurrentLocation;

  /// Getting location status message
  ///
  /// In en, this message translates to:
  /// **'Getting location...'**
  String get gettingLocation;

  /// Village/Area field label
  ///
  /// In en, this message translates to:
  /// **'Village/Area'**
  String get villageArea;

  /// Save address button text
  ///
  /// In en, this message translates to:
  /// **'Save Address'**
  String get saveAddress;

  /// Update address button text
  ///
  /// In en, this message translates to:
  /// **'Update Address'**
  String get updateAddress;

  /// Location services error message
  ///
  /// In en, this message translates to:
  /// **'Please enable location services'**
  String get pleaseEnableLocationServices;

  /// Location services error for saving address
  ///
  /// In en, this message translates to:
  /// **'Please enable location services to save address'**
  String get pleaseEnableLocationToSave;

  /// Save address error message
  ///
  /// In en, this message translates to:
  /// **'Failed to save address'**
  String get failedToSaveAddress;

  /// Delete address dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Address'**
  String get deleteAddress;

  /// Delete address confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{label}\"?'**
  String confirmDeleteAddress(String label);

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

  /// Address deleted success message
  ///
  /// In en, this message translates to:
  /// **'Address deleted successfully'**
  String get addressDeletedSuccessfully;

  /// Delete address error message
  ///
  /// In en, this message translates to:
  /// **'Failed to delete address'**
  String get failedToDeleteAddress;

  /// Empty state title for saved addresses
  ///
  /// In en, this message translates to:
  /// **'No Saved Addresses'**
  String get noSavedAddresses;

  /// Empty state description for saved addresses
  ///
  /// In en, this message translates to:
  /// **'Add addresses to quickly select them when placing orders'**
  String get addAddressesToQuicklySelect;

  /// Edit button tooltip
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

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
  /// **'https://www.yourcompany.com/privacy-policy'**
  String get privacyPolicyUrl;

  /// Error message when Privacy Policy URL cannot be opened
  ///
  /// In en, this message translates to:
  /// **'Unable to open Privacy Policy. Please check your internet connection.'**
  String get unableToOpenPrivacyPolicy;
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
