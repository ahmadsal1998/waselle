import React, { createContext, useContext, useState, useEffect } from 'react';

export type Language = 'en' | 'ar';

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (key: string) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

// Translation strings
const translations: Record<Language, Record<string, string>> = {
  en: {
    // Header
    'app.name': 'Wassle',
    'nav.home': 'Home',
    'nav.features': 'Features',
    'nav.screenshots': 'Screenshots',
    'nav.support': 'Support',
    'nav.pricing': 'Pricing',
    'nav.blog': 'Blog',
    'nav.contact': 'Contact',
    
    // Hero Section
    'hero.title': 'Welcome to Wassle',
    'hero.subtitle': 'Your trusted delivery partner. Experience fast, reliable, and convenient delivery services right at your fingertips. Order anything, anywhere, anytime.',
    
    // Banners
    'banner.fast.title': 'Fast & Reliable Delivery',
    'banner.fast.description': 'Get your orders delivered quickly and safely',
    'banner.track.title': 'Track in Real-Time',
    'banner.track.description': 'Follow your order from pickup to delivery',
    'banner.support.title': '24/7 Support',
    'banner.support.description': 'We\'re here to help whenever you need us',
    
    // Features
    'features.title': 'Why Choose Wassle?',
    'features.fast.title': 'Fast Delivery',
    'features.fast.description': 'Get your orders delivered in record time with our efficient delivery network.',
    'features.tracking.title': 'Real-Time Tracking',
    'features.tracking.description': 'Track your orders in real-time and know exactly when they\'ll arrive.',
    'features.secure.title': 'Secure & Safe',
    'features.secure.description': 'Your data and payments are protected with industry-leading security.',
    'features.selection.title': 'Wide Selection',
    'features.selection.description': 'Access a wide variety of products and services from multiple vendors.',
    'features.easy.title': 'Easy to Use',
    'features.easy.description': 'Intuitive interface designed for a seamless user experience.',
    'features.available.title': '24/7 Available',
    'features.available.description': 'Order anytime, day or night. We\'re always here to serve you.',
    
    // Download Section
    'download.title': 'Download Our App',
    'download.ios.title': 'iOS App',
    'download.ios.description': 'Download our app from the App Store and enjoy a seamless experience on your iPhone or iPad.',
    'download.ios.button': 'Download on App Store',
    'download.android.title': 'Android App',
    'download.android.description': 'Get our app from Google Play Store and experience fast delivery on your Android device.',
    'download.android.button': 'Download on Google Play',
    
    // Website Section
    'website.title': 'Visit Our Official Website',
    'website.description': 'Learn more about our services, company, and latest updates.',
    'website.button': 'Go to Official Website',
    
    // Testimonials
    'testimonials.title': 'What Our Customers Say',
    'testimonials.subtitle': 'Don\'t just take our word for it. See what our satisfied customers have to say about Wassle.',
    
    // FAQ
    'faq.title': 'Frequently Asked Questions',
    'faq.subtitle': 'Find answers to common questions about Wassle delivery services.',
    'faq.question1': 'How fast is delivery?',
    'faq.answer1': 'Our delivery times vary depending on your location and order type. Most orders are delivered within 30-60 minutes in urban areas.',
    'faq.question2': 'What areas do you serve?',
    'faq.answer2': 'We currently serve major cities and are expanding to more areas. Check the app to see if we deliver to your location.',
    'faq.question3': 'How do I track my order?',
    'faq.answer3': 'Once your order is confirmed, you can track it in real-time through the app. You\'ll receive updates at every stage of delivery.',
    'faq.question4': 'What payment methods do you accept?',
    'faq.answer4': 'We accept cash, credit/debit cards, and digital payment methods through the app for your convenience.',
    'faq.question5': 'Is there a minimum order amount?',
    'faq.answer5': 'Minimum order amounts vary by vendor. You\'ll see the minimum order requirement before placing your order.',
    'faq.stillHaveQuestion': 'Still have a question?',
    'faq.askQuestion': 'Ask your question here',
    
    // Newsletter
    'newsletter.title': 'Subscribe To Newsletter',
    'newsletter.subtitle': 'Stay updated with the latest news, offers, and updates from Wassle.',
    'newsletter.placeholder': 'Enter Your Email Address',
    'newsletter.button': 'Subscribe',
    'newsletter.privacy': 'We don\'t share your personal information with anyone. Check out our Privacy Policy for more information.',
    
    // Footer
    'footer.copyright': '© 2024 Wassle. All rights reserved.',
    'footer.privacy': 'Privacy Policy',
    'footer.terms': 'Terms of Service',
    'footer.usefulLinks': 'Useful Links',
    'footer.support': 'Support',
    'footer.about': 'About Us',
    'footer.contact': 'Contact',
    'footer.followUs': 'Follow Us',
  },
  ar: {
    // Header
    'app.name': 'وصلي',
    'nav.home': 'الرئيسية',
    'nav.features': 'المميزات',
    'nav.screenshots': 'لقطات الشاشة',
    'nav.support': 'الدعم',
    'nav.pricing': 'الأسعار',
    'nav.blog': 'المدونة',
    'nav.contact': 'اتصل بنا',
    
    // Hero Section
    'hero.title': 'مرحباً بك في وصلي',
    'hero.subtitle': 'شريك التوصيل الموثوق به. استمتع بخدمات توصيل سريعة وموثوقة ومريحة في متناول يدك. اطلب أي شيء، في أي مكان، في أي وقت.',
    
    // Banners
    'banner.fast.title': 'توصيل سريع وموثوق',
    'banner.fast.description': 'احصل على طلباتك بسرعة وأمان',
    'banner.track.title': 'تتبع في الوقت الفعلي',
    'banner.track.description': 'تابع طلبك من الاستلام إلى التوصيل',
    'banner.support.title': 'دعم على مدار الساعة',
    'banner.support.description': 'نحن هنا لمساعدتك متى احتجتنا',
    
    // Features
    'features.title': 'لماذا تختار وصلي؟',
    'features.fast.title': 'توصيل سريع',
    'features.fast.description': 'احصل على طلباتك في وقت قياسي مع شبكة التوصيل الفعالة لدينا.',
    'features.tracking.title': 'تتبع في الوقت الفعلي',
    'features.tracking.description': 'تابع طلباتك في الوقت الفعلي واعرف بالضبط متى ستصل.',
    'features.secure.title': 'آمن ومضمون',
    'features.secure.description': 'بياناتك ومدفوعاتك محمية بأمان رائد في الصناعة.',
    'features.selection.title': 'اختيار واسع',
    'features.selection.description': 'الوصول إلى مجموعة واسعة من المنتجات والخدمات من بائعين متعددين.',
    'features.easy.title': 'سهل الاستخدام',
    'features.easy.description': 'واجهة بديهية مصممة لتجربة مستخدم سلسة.',
    'features.available.title': 'متاح على مدار الساعة',
    'features.available.description': 'اطلب في أي وقت، ليلاً أو نهاراً. نحن دائماً هنا لخدمتك.',
    
    // Download Section
    'download.title': 'حمّل تطبيقنا',
    'download.ios.title': 'تطبيق iOS',
    'download.ios.description': 'حمّل تطبيقنا من متجر التطبيقات واستمتع بتجربة سلسة على iPhone أو iPad الخاص بك.',
    'download.ios.button': 'حمّل من App Store',
    'download.android.title': 'تطبيق Android',
    'download.android.description': 'احصل على تطبيقنا من متجر Google Play واستمتع بتوصيل سريع على جهاز Android الخاص بك.',
    'download.android.button': 'حمّل من Google Play',
    
    // Website Section
    'website.title': 'زر موقعنا الرسمي',
    'website.description': 'تعرف على المزيد حول خدماتنا وشركتنا وآخر التحديثات.',
    'website.button': 'انتقل إلى الموقع الرسمي',
    
    // Testimonials
    'testimonials.title': 'ماذا يقول عملاؤنا',
    'testimonials.subtitle': 'لا تأخذ كلمتنا فقط. شاهد ما يقوله عملاؤنا الراضون عن وصلي.',
    
    // FAQ
    'faq.title': 'الأسئلة الشائعة',
    'faq.subtitle': 'ابحث عن إجابات للأسئلة الشائعة حول خدمات التوصيل في وصلي.',
    'faq.question1': 'ما مدى سرعة التوصيل؟',
    'faq.answer1': 'تختلف أوقات التوصيل حسب موقعك ونوع الطلب. يتم توصيل معظم الطلبات خلال 30-60 دقيقة في المناطق الحضرية.',
    'faq.question2': 'ما هي المناطق التي تخدمونها؟',
    'faq.answer2': 'نخدم حالياً المدن الكبرى ونوسع نطاقنا إلى المزيد من المناطق. تحقق من التطبيق لمعرفة ما إذا كنا نقدم الخدمة في موقعك.',
    'faq.question3': 'كيف أتابع طلبي؟',
    'faq.answer3': 'بمجرد تأكيد طلبك، يمكنك تتبعه في الوقت الفعلي من خلال التطبيق. ستحصل على تحديثات في كل مرحلة من مراحل التوصيل.',
    'faq.question4': 'ما هي طرق الدفع التي تقبلونها؟',
    'faq.answer4': 'نقبل النقد وبطاقات الائتمان/الخصم وطرق الدفع الرقمية من خلال التطبيق لراحتك.',
    'faq.question5': 'هل يوجد حد أدنى لمبلغ الطلب؟',
    'faq.answer5': 'تختلف الحدود الدنيا للطلب حسب البائع. سترى متطلبات الحد الأدنى للطلب قبل تقديم طلبك.',
    'faq.stillHaveQuestion': 'لا يزال لديك سؤال؟',
    'faq.askQuestion': 'اطرح سؤالك هنا',
    
    // Newsletter
    'newsletter.title': 'اشترك في النشرة الإخبارية',
    'newsletter.subtitle': 'ابق على اطلاع بآخر الأخبار والعروض والتحديثات من وصلي.',
    'newsletter.placeholder': 'أدخل عنوان بريدك الإلكتروني',
    'newsletter.button': 'اشترك',
    'newsletter.privacy': 'لا نشارك معلوماتك الشخصية مع أي شخص. راجع سياسة الخصوصية لمزيد من المعلومات.',
    
    // Footer
    'footer.copyright': '© 2024 وصلي. جميع الحقوق محفوظة.',
    'footer.privacy': 'سياسة الخصوصية',
    'footer.terms': 'شروط الخدمة',
    'footer.usefulLinks': 'روابط مفيدة',
    'footer.support': 'الدعم',
    'footer.about': 'من نحن',
    'footer.contact': 'اتصل بنا',
    'footer.followUs': 'تابعنا',
  },
};

export const LanguageProvider: React.FC<{ children: React.ReactNode }> = ({
  children,
}) => {
  const [language, setLanguageState] = useState<Language>(() => {
    // Get saved language from localStorage or default to 'en'
    const savedLang = localStorage.getItem('lang') as Language;
    return savedLang === 'ar' || savedLang === 'en' ? savedLang : 'en';
  });

  // Update document direction when language changes
  useEffect(() => {
    const dir = language === 'ar' ? 'rtl' : 'ltr';
    document.documentElement.dir = dir;
    document.documentElement.lang = language;
    localStorage.setItem('lang', language);
  }, [language]);

  const setLanguage = (lang: Language) => {
    setLanguageState(lang);
  };

  const t = (key: string): string => {
    return translations[language][key] || key;
  };

  return (
    <LanguageContext.Provider value={{ language, setLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
};

export const useLanguage = () => {
  const context = useContext(LanguageContext);
  if (context === undefined) {
    throw new Error('useLanguage must be used within a LanguageProvider');
  }
  return context;
};

