// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Wassle Driver';

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
  String get noOrdersAvailable => 'لا توجد طلبات متاحة';

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
  String get proposeNewPrice => 'اقتراح سعر جديد';

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

  @override
  String get orderTypeSend => 'إرسال الطلب';

  @override
  String get orderTypeReceive => 'إحضار الطلب';

  @override
  String get pickup => 'من ';

  @override
  String get dropoff => ' الى';

  @override
  String get startNavigation => 'بدء التنقل';

  @override
  String get callCustomer => 'اتصال بالعميل';

  @override
  String get viewDetails => 'عرض التفاصيل';

  @override
  String get driverEarnings => 'أرباح السائق';

  @override
  String get statusNew => 'جديد';

  @override
  String get inProgress => 'قيد التنفيذ';

  @override
  String get completed => 'مكتمل';

  @override
  String get cancelled => 'ملغي';

  @override
  String get statusPending => 'قيد الانتظار';

  @override
  String get statusAccepted => 'مقبول';

  @override
  String get statusOnTheWay => 'في الطريق';

  @override
  String get statusDelivered => 'تم التوصيل';

  @override
  String get orderContents => 'محتوى الطلب';

  @override
  String get close => 'إغلاق';

  @override
  String get orderHistory => 'سجل الطلبات';

  @override
  String get totalOrders => 'إجمالي الطلبات';

  @override
  String get totalDeliveryFees => 'إجمالي رسوم التوصيل';

  @override
  String get today => 'اليوم';

  @override
  String get selectDate => 'اختر التاريخ';

  @override
  String get clear => 'مسح';

  @override
  String get receiver => 'المستلم';

  @override
  String get deliveryFee => 'رسوم التوصيل';

  @override
  String get dateTime => 'التاريخ والوقت';

  @override
  String get remainingBalance => 'المبلغ المستحق';

  @override
  String get balanceWarningMessage => 'سيتم خصم هذا الرصيد قبل تعليق الحساب';

  @override
  String get filter => 'تصفية';

  @override
  String get deliveryType => 'نوع التوصيل';

  @override
  String get internalDelivery => 'توصيل داخلي';

  @override
  String get externalDelivery => 'توصيل خارجي';

  @override
  String get from => 'من';

  @override
  String get to => 'إلى';

  @override
  String get viewMore => 'عرض المزيد';

  @override
  String get viewLess => 'عرض أقل';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicyTitle => 'سياسة الخصوصية';

  @override
  String get privacyPolicyUrl => 'https://www.wassle.ps/privacy-policy';

  @override
  String get unableToOpenPrivacyPolicy => 'تعذر فتح سياسة الخصوصية. يرجى التحقق من اتصال الإنترنت.';

  @override
  String get termsOfService => 'شروط الخدمة';

  @override
  String get termsOfServiceTitle => 'شروط الخدمة';

  @override
  String get termsOfServiceUrl => 'https://www.wassle.ps/terms-of-service';

  @override
  String get unableToOpenTermsOfService => 'تعذر فتح شروط الخدمة. يرجى التحقق من اتصال الإنترنت.';

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
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get setDeliveryPrice => 'تحديد سعر التوصيل';

  @override
  String get estimatedPrice => 'السعر التقديري';

  @override
  String get enterFinalPrice => 'أدخل سعر التوصيل النهائي:';

  @override
  String get enterValidPrice => 'الرجاء إدخال سعر صحيح';

  @override
  String get nisSymbol => '₪';

  @override
  String get priceWillBeSentToCustomer => 'سيتم إرسال هذا السعر للعميل للموافقة عليه';

  @override
  String get confirmPrice => 'تأكيد السعر';

  @override
  String get orderAcceptedPricePending => 'تم قبول الطلب. في انتظار اقتراح السعر.';

  @override
  String get priceProposedSuccessfully => 'تم اقتراح السعر بنجاح. في انتظار موافقة العميل.';

  @override
  String get waitingForPriceApproval => 'في انتظار موافقة العميل على السعر';

  @override
  String get priceAccepted => 'تم قبول السعر';

  @override
  String get priceRejected => 'تم رفض السعر';

  @override
  String get proposedPrice => 'السعر المقترح';

  @override
  String get finalPrice => 'السعر النهائي';

  @override
  String get priceStatusPending => 'في انتظار اقتراح السعر';

  @override
  String get priceStatusProposed => 'تم اقتراح السعر، في انتظار العميل';

  @override
  String get accountSuspended => 'الحساب معطل';

  @override
  String get accountSuspendedMessage => 'تم تعليق حسابك مؤقتاً.';

  @override
  String get accountSuspendedDetails => 'وصل رصيدك إلى الحد الأقصى المسموح به أو تجاوزه. يرجى الاتصال بالمسؤول لإجراء الدفع وإعادة تفعيل حسابك.';

  @override
  String get currentBalance => 'الرصيد الحالي';

  @override
  String get maximumAllowed => 'الحد الأقصى المسموح';

  @override
  String paymentRequiredMessage(String amount) {
    return 'تحتاج إلى دفع $amount شيكل لإعادة تفعيل حسابك.';
  }

  @override
  String get checkAccountStatus => 'التحقق من حالة الحساب';

  @override
  String get checking => 'جارٍ التحقق...';
}
