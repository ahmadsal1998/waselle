// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Wassle';

  @override
  String get welcomeBack => 'مرحباً بعودتك';

  @override
  String get signInToContinue => 'سجل الدخول للمتابعة';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟ سجل الآن';

  @override
  String get pleaseEnterEmail => 'الرجاء إدخال البريد الإلكتروني';

  @override
  String get pleaseEnterValidEmail => 'الرجاء إدخال بريد إلكتروني صحيح';

  @override
  String get pleaseEnterPassword => 'الرجاء إدخال كلمة المرور';

  @override
  String get loginFailed => 'فشل تسجيل الدخول. الرجاء المحاولة مرة أخرى.';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get pleaseEnterName => 'الرجاء إدخال الاسم';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get pleaseEnterPhoneNumber => 'الرجاء إدخال رقم الهاتف';

  @override
  String get passwordMustBe6Chars => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get registrationFailed => 'فشل التسجيل. الرجاء المحاولة مرة أخرى.';

  @override
  String get verifyEmail => 'التحقق من البريد الإلكتروني';

  @override
  String get verifyYourEmail => 'التحقق من بريدك الإلكتروني';

  @override
  String get verifyYourPhone => 'التحقق من هاتفك';

  @override
  String otpSentMessage(String email) {
    return 'أرسلنا رمز التحقق إلى\n$email';
  }

  @override
  String get verify => 'تحقق';

  @override
  String get pleaseEnterValidOtp => 'الرجاء إدخال رمز التحقق المكون من 6 أرقام';

  @override
  String get invalidOtp => 'رمز التحقق غير صحيح. الرجاء المحاولة مرة أخرى.';

  @override
  String get discover => 'الرئيسية';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get trackOrder => 'تتبع الطلب';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get trackOrders => 'تتبع الطلبات';

  @override
  String get sendRequest => 'إرسال طلب';

  @override
  String get receiveRequest => ' إحضار طلب';

  @override
  String get sendDelivery => 'إرسال طلب';

  @override
  String get noUserData => 'لا توجد بيانات المستخدم';

  @override
  String get unknown => 'غير معروف';

  @override
  String get mapStyle => 'نمط الخريطة';

  @override
  String get selectMapStyle => 'اختر نمط الخريطة';

  @override
  String mapStyleValue(String style) {
    return 'نمط الخريطة: $style';
  }

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get noOrdersYet => 'لا توجد طلبات بعد';

  @override
  String get order => 'طلب';

  @override
  String orderNumber(String id) {
    return 'طلب رقم $id';
  }

  @override
  String get status => 'الحالة';

  @override
  String get price => 'السعر';

  @override
  String get refresh => 'تحديث';

  @override
  String get noActiveOrders => 'لا توجد طلبات نشطة';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get unknownDate => 'تاريخ غير معروف';

  @override
  String get created => 'تم الإنشاء';

  @override
  String get deliveryDetails => 'تفاصيل التوصيل';

  @override
  String get chooseHowToSend => 'اختر كيف تريد إرسال الطرد الخاص بك.';

  @override
  String get pickupLocation => 'موقع الاستلام';

  @override
  String get tellUsWhereToCollect => 'أخبرنا أين نجمع الطرد الخاص بك.';

  @override
  String get senderDetails => 'تفاصيل المرسل';

  @override
  String get whoShouldDriverContact => 'من يجب أن يتواصل السائق معه عند الوصول؟';

  @override
  String get deliveryNotes => 'تفاصيل الطلب';

  @override
  String get shareHelpfulTips => 'شارك أي نصائح مفيدة للسائق.';

  @override
  String get estimatedCost => 'التكلفة المقدرة';

  @override
  String get weUpdateAsYouComplete => 'نقوم بتحديث هذا أثناء إكمال النموذج.';

  @override
  String get bike => 'دراجة';

  @override
  String get car => 'سيارة';

  @override
  String get cargo => 'شاحنة';

  @override
  String get soon => 'قريباً';

  @override
  String get comingSoon => 'قريباً';

  @override
  String get locatingYou => 'جاري تحديد موقعك...';

  @override
  String get weUseCurrentLocation => 'نستخدم موقعك الحالي لملء تفاصيل الاستلام مسبقاً.';

  @override
  String get fetchingLocation => 'جاري جلب الموقع...';

  @override
  String get retryLocation => 'إعادة محاولة الموقع';

  @override
  String get pickupFromYourLocation => 'الاستلام من موقعك';

  @override
  String get updating => 'جاري التحديث...';

  @override
  String get refreshLocation => 'تحديث الموقع';

  @override
  String get selectOrderType => 'اختر نوع الطلب';

  @override
  String get orderType => 'نوع الطلب';

  @override
  String get pleaseWaitForCategories => 'الرجاء الانتظار حتى يتم تحميل الفئات';

  @override
  String get noOrderCategoriesAvailable => 'لا توجد فئات طلبات متاحة في الوقت الحالي';

  @override
  String get pleaseSelectOrderType => 'الرجاء اختيار نوع الطلب';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noCategoriesTryLater => 'لا توجد فئات طلبات متاحة. الرجاء المحاولة مرة أخرى لاحقاً.';

  @override
  String get city => 'المدينة';

  @override
  String get noActiveCitiesAvailable => 'لا توجد مدن نشطة متاحة في الوقت الحالي';

  @override
  String get pleaseSelectCity => 'الرجاء اختيار مدينة';

  @override
  String get loadingVillages => 'جاري تحميل القرى...';

  @override
  String get village => 'القرية';

  @override
  String get selectCityFirst => 'اختر مدينة أولاً';

  @override
  String get noActiveVillagesForCity => 'لا توجد قرى نشطة متاحة لهذه المدينة';

  @override
  String get pleaseSelectVillage => 'الرجاء اختيار قرية';

  @override
  String get senderName => 'اسم المرسل';

  @override
  String get pleaseEnterSenderName => 'الرجاء إدخال اسم المرسل';

  @override
  String get streetAddressDetails => 'عنوان الشارع / التفاصيل';

  @override
  String get streetBuildingFloorApartment => 'الشارع، المبنى، الطابق، الشقة...';

  @override
  String get pleaseEnterSenderAddress => 'الرجاء إدخال عنوان المرسل';

  @override
  String get provideDirections => 'قدم الاتجاهات، رموز الوصول للمبنى، أو تفاصيل أخرى.';

  @override
  String get sendRequestNotesHint => 'مثال: عندي طلب بمخزن الشلبي شارع حيفا وبدي أرسله على المحل بجنين شارع أبو بكر عمارة النفاع.';

  @override
  String get receiveRequestNotesHint => 'مثال: عندي طلب موجود بمخزن الشلبي شارع حيفا وبدّي تجيبه/تحضّره للمحل بجنين شارع أبو بكر.';

  @override
  String get pleaseEnterDeliveryNotes => 'الرجاء إدخال تفاصيل الطلب';

  @override
  String get liveCostPreview => 'معاينة التكلفة المباشرة';

  @override
  String get selectVehicleAndEnterAddress => 'اختر مركبة وأدخل عنوان الاستلام لرؤية التقدير.';

  @override
  String get estimateNote => 'التكلفة المعروضة تقديرية وقد تختلف حسب المسافة الفعلية.';

  @override
  String get deliveryStartsFrom => 'يبدأ التوصيل بــ';

  @override
  String get submitting => 'جاري الإرسال...';

  @override
  String get submitRequest => 'إرسال الطلب';

  @override
  String get unableToCalculateEstimate => 'تعذر حساب التكلفة المقدرة للتوصيل.';

  @override
  String get pleaseSelectDeliveryVehicle => 'الرجاء اختيار مركبة التوصيل.';

  @override
  String get pleaseSelectYourCity => 'الرجاء اختيار مدينتك.';

  @override
  String get pleaseSelectYourVillage => 'الرجاء اختيار قريتك.';

  @override
  String get pleaseEnterValidPhoneNumber => 'الرجاء إدخال رقم هاتف صحيح مكون من 10 أرقام.';

  @override
  String get waitForEstimatedCost => 'الرجاء الانتظار للحصول على التكلفة المقدرة قبل الإرسال.';

  @override
  String get pleaseSelectOrderCategory => 'الرجاء اختيار فئة الطلب.';

  @override
  String get orderCategoryNoLongerAvailable => 'فئة الطلب المختارة لم تعد متاحة. الرجاء اختيار أخرى.';

  @override
  String get waitingForLocation => 'في انتظار موقعك الحالي. الرجاء تفعيل خدمات الموقع والمحاولة مرة أخرى.';

  @override
  String get orderCreatedSuccessfully => 'تم إنشاء الطلب بنجاح!';

  @override
  String get noDriversAvailable => 'لم يتم العثور على سائقين في منطقة الخدمة. الرجاء المحاولة مرة أخرى لاحقاً.';

  @override
  String get requestSentSuccessfully => 'تم إرسال الطلب بنجاح';

  @override
  String get requestSentSuccessMessage => 'تم استلام طلب التوصيل الخاص بك وهو قيد المعالجة. سيتم إشعارك عند قبول سائق لطلبك.';

  @override
  String get backToHome => 'العودة إلى الرئيسية';

  @override
  String get failedToCreateOrder => 'فشل إنشاء الطلب';

  @override
  String get vehicle => 'المركبة';

  @override
  String get type => 'النوع';

  @override
  String get category => 'الفئة';

  @override
  String get distance => 'المسافة';

  @override
  String kilometers(String distance) {
    return '$distance كم';
  }

  @override
  String nis(String price) {
    return '$price شيكل';
  }

  @override
  String get deliveryType => 'نوع التوصيل';

  @override
  String get internalDelivery => 'توصيل داخلي';

  @override
  String get externalDelivery => 'توصيل خارجي';

  @override
  String get selectDeliveryType => 'اختر نوع التوصيل';

  @override
  String get pleaseSelectDeliveryType => 'الرجاء اختيار نوع التوصيل';

  @override
  String get internalDeliveryDescription => 'التوصيل ضمن دائرة نصف قطرها 2 كم (قابل للتعديل من قبل المدير)';

  @override
  String get externalDeliveryDescription => 'التوصيل ضمن دائرة نصف قطرها 10 كم (قابل للتعديل من قبل المدير)';

  @override
  String get orderProgress => 'تقدم الطلب';

  @override
  String get showOrderProgress => 'إظهار تقدم الطلب';

  @override
  String get hideOrderProgress => 'إخفاء تقدم الطلب';

  @override
  String get tapToOpenMap => 'اضغط لفتح الخريطة';

  @override
  String get orderPlaced => 'تم وضع الطلب';

  @override
  String get orderPlacedDescription => 'تم وضع طلبك وهو في انتظار سائق';

  @override
  String get orderAccepted => 'تم قبول الطلب';

  @override
  String get orderAcceptedDescription => 'قبل سائق طلبك';

  @override
  String get onTheWay => 'في الطريق';

  @override
  String get onTheWayDescription => 'السائق في طريقه إلى موقعك';

  @override
  String get delivered => 'تم التسليم';

  @override
  String get deliveredDescription => 'تم تسليم طلبك بنجاح';

  @override
  String get pending => 'قيد الانتظار';

  @override
  String get cancelled => 'ملغي';

  @override
  String get current => 'الحالي';

  @override
  String get dropoffLocation => 'موقع التسليم';

  @override
  String get estimatedTime => 'الوقت المقدر';

  @override
  String minutes(String minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get phone => 'الهاتف';

  @override
  String get notes => 'ملاحظات';

  @override
  String get refreshNearbyDrivers => 'تحديث السائقين القريبين';

  @override
  String get currentLocation => 'الموقع الحالي';

  @override
  String get locate => 'تحديد الموقع';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get viewMore => 'عرض المزيد';

  @override
  String get viewLess => 'عرض أقل';

  @override
  String get mapView => 'عرض الخريطة';

  @override
  String get driverInformation => 'معلومات السائق';

  @override
  String get savedAddresses => 'العناوين المحفوظة';

  @override
  String get addAddress => 'إضافة عنوان';

  @override
  String get editAddress => 'تعديل العنوان';

  @override
  String get addressLabel => 'التسمية (مثل: المنزل، العمل)';

  @override
  String get pleaseEnterLabel => 'الرجاء إدخال تسمية';

  @override
  String get useCurrentLocation => 'استخدام الموقع الحالي';

  @override
  String get gettingLocation => 'جاري الحصول على الموقع...';

  @override
  String get villageArea => 'القرية/المنطقة';

  @override
  String get saveAddress => 'حفظ العنوان';

  @override
  String get updateAddress => 'تحديث العنوان';

  @override
  String get pleaseEnableLocationServices => 'الرجاء تفعيل خدمات الموقع';

  @override
  String get pleaseEnableLocationToSave => 'الرجاء تفعيل خدمات الموقع لحفظ العنوان';

  @override
  String get failedToSaveAddress => 'فشل حفظ العنوان';

  @override
  String get deleteAddress => 'حذف العنوان';

  @override
  String confirmDeleteAddress(String label) {
    return 'هل أنت متأكد من حذف \"$label\"?';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get addressDeletedSuccessfully => 'تم حذف العنوان بنجاح';

  @override
  String get failedToDeleteAddress => 'فشل حذف العنوان';

  @override
  String get noSavedAddresses => 'لا توجد عناوين محفوظة';

  @override
  String get addAddressesToQuicklySelect => 'أضف عناوين للاختيار السريع عند تقديم الطلبات';

  @override
  String get edit => 'تعديل';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get privacyPolicyUrl => 'https://www.wassle.ps/privacy-policy';

  @override
  String get unableToOpenPrivacyPolicy => 'تعذر فتح سياسة الخصوصية. يرجى التحقق من اتصال الإنترنت.';

  @override
  String get privacyPolicyDescription => 'اضغط على الزر أدناه لعرض سياسة الخصوصية الخاصة بنا في المتصفح.';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get termsOfServiceTitle => 'شروط الخدمة';

  @override
  String get termsOfServiceUrl => 'https://www.wassle.ps/terms-of-service';

  @override
  String get unableToOpenTermsOfService => 'تعذر فتح شروط الخدمة. يرجى التحقق من اتصال الإنترنت.';

  @override
  String get termsOfServiceDescription => 'اضغط على الزر أدناه لعرض شروط الخدمة الخاصة بنا في المتصفح.';

  @override
  String get manageSavedAddresses => 'إدارة عناوينك المحفوظة';

  @override
  String get readPrivacyPolicy => 'اقرأ سياسة الخصوصية الخاصة بنا';

  @override
  String get readTermsOfService => 'اقرأ شروط الخدمة الخاصة بنا';

  @override
  String get legal => 'قانوني';

  @override
  String get notAvailable => 'غير متاح';

  @override
  String get initializing => 'جاري التهيئة';

  @override
  String get initializingSubtitle => 'جاري البحث عن السائقين القريبين منك';

  @override
  String get locationDisabled => 'الموقع معطل';

  @override
  String get locationDisabledSubtitle => 'تعذر الوصول إلى موقعك. يرجى تفعيل خدمات الموقع';

  @override
  String get tryAgain => 'إعادة المحاولة';

  @override
  String get locationNotFound => 'الموقع غير موجود';

  @override
  String get locationNotFoundSubtitle => 'اضغط على الزر أدناه لتحديث موقعك واستكشاف السائقين القريبين';

  @override
  String get getLocation => 'الحصول على الموقع';

  @override
  String get unknownLocation => 'موقع غير معروف';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get confirmDeleteAccount => 'هل أنت متأكد من حذف حسابك؟';

  @override
  String get deleteAccountWarning => 'لا يمكن التراجع عن هذا الإجراء. سيتم حذف جميع بيانات حسابك بشكل دائم.';

  @override
  String get deleteAccountOtpTitle => 'التحقق من هاتفك';

  @override
  String deleteAccountOtpMessage(String phoneNumber) {
    return 'أرسلنا رمز التحقق إلى\n$phoneNumber\n\nالرجاء إدخال الرمز لتأكيد حذف الحساب.';
  }

  @override
  String get otpSentSuccessfully => 'تم إرسال رمز التحقق بنجاح';

  @override
  String get resendOtp => 'إعادة إرسال رمز التحقق';

  @override
  String resendOtpIn(int seconds) {
    return 'إعادة إرسال رمز التحقق خلال $seconds ثانية';
  }

  @override
  String get accountDeletedSuccessfully => 'تم حذف الحساب بنجاح';

  @override
  String get failedToDeleteAccount => 'فشل حذف الحساب';

  @override
  String get failedToSendOtp => 'فشل إرسال رمز التحقق. الرجاء المحاولة مرة أخرى.';

  @override
  String get confirm => 'تأكيد';

  @override
  String get priceProposalReceived => 'تم استلام عرض السعر';

  @override
  String get driverProposedPrice => 'السائق اقترح سعر التوصيل';

  @override
  String get estimatedPrice => 'السعر المقدر';

  @override
  String get finalPrice => 'السعر النهائي';

  @override
  String get acceptPrice => 'قبول السعر';

  @override
  String get rejectPrice => 'رفض';

  @override
  String get priceAcceptedSuccess => 'تم قبول السعر! سيبدأ السائق التوصيل.';

  @override
  String get priceRejectedSuccess => 'تم رفض السعر. السائق سيقترح سعراً جديداً.';

  @override
  String get failedToRespondToPrice => 'فشل الرد على السعر. الرجاء المحاولة مرة أخرى.';

  @override
  String get waitingForPrice => 'في انتظار السائق لتحديد سعر التوصيل';

  @override
  String get priceProposed => 'تم اقتراح السعر، في انتظار التأكيد';

  @override
  String get priceAccepted => 'تم تأكيد السعر';

  @override
  String get deliveryPriceOffers => 'عروض أسعار التوصيل';

  @override
  String get noPriceOffers => 'لا توجد عروض أسعار متاحة';

  @override
  String get proposedPrice => 'السعر المقترح';

  @override
  String get acceptOffer => 'قبول';

  @override
  String get rejectOffer => 'رفض';

  @override
  String get offerAccepted => 'تم قبول العرض بنجاح';

  @override
  String get offerRejected => 'تم رفض العرض';

  @override
  String get failedToLoadOffers => 'فشل تحميل عروض الأسعار';

  @override
  String get viewPriceOffers => 'عرض والرد على عروض الأسعار';

  @override
  String get newPriceOfferReceived => 'تم استلام عرض سعر جديد!';

  @override
  String get viewOrderHistory => 'عرض طلباتك السابقة';

  @override
  String get verifyPhoneNumber => 'التحقق من رقم الهاتف';

  @override
  String get enterVerificationCodeWhatsApp => 'أدخل رمز التحقق المكون من 6 أرقام المرسل إلى واتساب الخاص بك:';

  @override
  String get verifyAndSubmitOrder => 'التحقق وإرسال الطلب';

  @override
  String get resendCode => 'إعادة إرسال الرمز';

  @override
  String get pleaseEnter6DigitCode => 'الرجاء إدخال رمز مكون من 6 أرقام';

  @override
  String get locationNotAvailable => 'الموقع غير متاح';
}
