// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'تطبيق سائق التوصيل';

  @override
  String get driverLogin => 'تسجيل دخول السائق';

  @override
  String get signInToStart => 'سجل الدخول لبدء قبول الطلبات';

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
  String get driverRegistration => 'تسجيل السائق';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get pleaseEnterName => 'الرجاء إدخال الاسم';

  @override
  String get selectVehicleType => 'اختر نوع المركبة';

  @override
  String get pleaseSelectVehicleType => 'الرجاء اختيار نوع المركبة';

  @override
  String get car => 'سيارة';

  @override
  String get bike => 'دراجة';

  @override
  String get phoneNumber => 'رقم الهاتف';

  @override
  String get pleaseEnterPhoneNumber => 'الرجاء إدخال رقم الهاتف';

  @override
  String get passwordMustBe6Chars => 'يجب أن تكون كلمة المرور 6 أحرف على الأقل';

  @override
  String get registrationFailed => 'فشل التسجيل. الرجاء المحاولة مرة أخرى.';

  @override
  String get driverDashboard => 'لوحة تحكم السائق';

  @override
  String get available => 'متاح';

  @override
  String get active => 'نشط';

  @override
  String get history => 'السجل';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get noAvailableOrders => 'لا توجد طلبات متاحة';

  @override
  String get refresh => 'تحديث';

  @override
  String get order => 'طلب';

  @override
  String orderNumber(String id) {
    return 'طلب رقم $id';
  }

  @override
  String get type => 'النوع';

  @override
  String get vehicle => 'المركبة';

  @override
  String get price => 'السعر';

  @override
  String get distance => 'المسافة';

  @override
  String get accept => 'قبول';

  @override
  String get orderAcceptedSuccessfully => 'تم قبول الطلب بنجاح!';

  @override
  String get failedToAcceptOrder => 'فشل قبول الطلب';

  @override
  String get noActiveOrder => 'لا يوجد طلب نشط';

  @override
  String get activeOrder => 'طلب نشط';

  @override
  String get status => 'الحالة';

  @override
  String get category => 'الفئة';

  @override
  String get estimated => 'مقدر';

  @override
  String get created => 'تم الإنشاء';

  @override
  String get sender => 'المرسل';

  @override
  String get name => 'الاسم';

  @override
  String get phone => 'الهاتف';

  @override
  String get address => 'العنوان';

  @override
  String get notes => 'ملاحظات';

  @override
  String get openLiveMap => 'فتح الخريطة المباشرة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get mapStyle => 'نمط الخريطة';

  @override
  String mapStyleValue(String style) {
    return 'نمط الخريطة: $style';
  }

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get noUserData => 'لا توجد بيانات المستخدم';

  @override
  String get unknown => 'غير معروف';

  @override
  String get nA => 'غير متاح';

  @override
  String get failedToUpdateAvailability => 'فشل تحديث الحالة. الرجاء المحاولة مرة أخرى.';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'الإنجليزية';

  @override
  String get arabic => 'العربية';

  @override
  String get selectLanguage => 'اختر اللغة';

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
  String get orderDetails => 'تفاصيل الطلب';

  @override
  String get orderNotFound => 'الطلب غير موجود';

  @override
  String get centerOnDriver => 'التمركز على السائق';

  @override
  String statusValue(String status) {
    return 'الحالة: $status';
  }

  @override
  String priceValue(String price) {
    return 'السعر: $price';
  }

  @override
  String distanceToCustomer(String distance) {
    return 'المسافة إلى العميل: $distance كم';
  }

  @override
  String get startDelivery => 'بدء التوصيل';

  @override
  String get markAsDelivered => 'تمييز كمكتمل';

  @override
  String orderStatusUpdated(String status) {
    return 'تم تحديث حالة الطلب إلى $status';
  }

  @override
  String get noOrderHistory => 'لا يوجد سجل طلبات';

  @override
  String get orderHistoryMessage => 'ستظهر الطلبات المكتملة هنا بمجرد بدء التوصيل.';

  @override
  String statusValueColon(String status) {
    return 'الحالة: $status';
  }

  @override
  String priceValueColon(String price) {
    return 'السعر: $price';
  }

  @override
  String typeValueColon(String type) {
    return 'النوع: $type';
  }

  @override
  String kilometers(String distance) {
    return '$distance كم';
  }

  @override
  String nis(String price) {
    return '$price شيكل';
  }

  @override
  String get selectImageSource => 'اختر مصدر الصورة';

  @override
  String get profilePictureUpdated => 'تم تحديث صورة الملف الشخصي بنجاح';

  @override
  String get failedToUpdateProfilePicture => 'فشل في تحديث صورة الملف الشخصي';

  @override
  String get camera => 'الكاميرا';

  @override
  String get gallery => 'المعرض';
}
