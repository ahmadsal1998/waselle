// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق المستخدم للتوصيل';

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
  String get receiveRequest => 'إحضار طلب';

  @override
  String get sendDelivery => 'إرسال طلب';

  @override
  String get noUserData => 'لا توجد بيانات المستخدم';

  @override
  String get unknown => 'غير معروف';

  @override
  String get mapStyle => 'نمط الخريطة';

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
  String get deliveryNotes => 'ملاحظات التوصيل';

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
  String get pleaseEnterDeliveryNotes => 'الرجاء إدخال ملاحظات التوصيل';

  @override
  String get liveCostPreview => 'معاينة التكلفة المباشرة';

  @override
  String get selectVehicleAndEnterAddress => 'اختر مركبة وأدخل عنوان الاستلام لرؤية التقدير.';

  @override
  String get estimateNote => 'التكلفة المعروضة تقديرية وقد تختلف حسب المسافة الفعلية.';

  @override
  String get deliveryStartsFrom => 'يبدأ التوصيل من';

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
}
