import { useState, useEffect, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { 
  Smartphone, 
  Package, 
  Clock, 
  MapPin, 
  Shield, 
  Globe,
  ChevronDown,
  ChevronUp,
  Mail,
  Facebook,
  Twitter,
  Instagram,
  Linkedin,
  Youtube,
  Star,
  Sparkles,
  Zap
} from 'lucide-react';
import { useLanguage } from '@/store/language/LanguageContext';

const Landing = () => {
  const [tapCount, setTapCount] = useState(0);
  const [openFaq, setOpenFaq] = useState<number | null>(null);
  const [activeSection, setActiveSection] = useState('home');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [visibleSections, setVisibleSections] = useState<Set<string>>(new Set());
  const tapTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const navigate = useNavigate();
  const { language, setLanguage, t } = useLanguage();
  const sectionRefs = useRef<{ [key: string]: HTMLElement | null }>({});

  // Smooth scroll handler
  const handleNavClick = (e: React.MouseEvent<HTMLAnchorElement>, sectionId: string) => {
    e.preventDefault();
    setActiveSection(sectionId);
    setMobileMenuOpen(false); // Close mobile menu on click
    const element = document.getElementById(sectionId);
    if (element) {
      element.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
  };

  // Testimonials data
  const testimonials = [
    {
      id: 1,
      text: 'Wassle has completely transformed how I get my deliveries. Fast, reliable, and the real-time tracking is amazing!',
      author: 'Sarah Ahmed',
      role: 'Customer',
      rating: 5,
    },
    {
      id: 2,
      text: 'The best delivery service I\'ve ever used. The app is intuitive and the drivers are always professional.',
      author: 'Mohammed Ali',
      role: 'Customer',
      rating: 5,
    },
    {
      id: 3,
      text: 'I love how easy it is to order and track. Wassle has made my life so much easier!',
      author: 'Fatima Hassan',
      role: 'Customer',
      rating: 5,
    },
  ];

  // FAQ data
  const faqs = [
    {
      id: 1,
      question: t('faq.question1'),
      answer: t('faq.answer1'),
    },
    {
      id: 2,
      question: t('faq.question2'),
      answer: t('faq.answer2'),
    },
    {
      id: 3,
      question: t('faq.question3'),
      answer: t('faq.answer3'),
    },
    {
      id: 4,
      question: t('faq.question4'),
      answer: t('faq.answer4'),
    },
    {
      id: 5,
      question: t('faq.question5'),
      answer: t('faq.answer5'),
    },
  ];

  // Cleanup timeouts on unmount
  useEffect(() => {
    return () => {
      if (tapTimeoutRef.current) {
        clearTimeout(tapTimeoutRef.current);
      }
    };
  }, []);

  // Intersection Observer for scroll-triggered animations
  useEffect(() => {
    const observerOptions = {
      root: null,
      rootMargin: '-100px 0px',
      threshold: 0.1,
    };

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          const sectionId = entry.target.getAttribute('data-section-id');
          if (sectionId) {
            setVisibleSections((prev) => new Set(prev).add(sectionId));
          }
        }
      });
    }, observerOptions);

    // Observe all sections
    Object.values(sectionRefs.current).forEach((ref) => {
      if (ref) observer.observe(ref);
    });

    return () => {
      Object.values(sectionRefs.current).forEach((ref) => {
        if (ref) observer.unobserve(ref);
      });
    };
  }, []);

  // Scroll listener to update active section
  useEffect(() => {
    const handleScroll = () => {
      const sections = ['home', 'features', 'screenshots', 'support', 'blog', 'contact'];
      const scrollPosition = window.scrollY + 100;

      for (const section of sections) {
        const element = document.getElementById(section);
        if (element) {
          const offsetTop = element.offsetTop;
          const offsetHeight = element.offsetHeight;
          if (scrollPosition >= offsetTop && scrollPosition < offsetTop + offsetHeight) {
            setActiveSection(section);
            break;
          }
        }
      }
    };

    window.addEventListener('scroll', handleScroll);
    return () => window.removeEventListener('scroll', handleScroll);
  }, []);

  // Handle navigation when 7 taps are reached
  useEffect(() => {
    if (tapCount === 7) {
      sessionStorage.setItem('unlockLogin', 'true');
      navigate('/login');
      setTapCount(0);
    }
  }, [tapCount, navigate]);

  // Handle logo tap gesture - 7 continuous taps
  const handleLogoClick = () => {
    if (tapTimeoutRef.current) {
      clearTimeout(tapTimeoutRef.current);
      tapTimeoutRef.current = null;
    }

    setTapCount((prevCount) => {
      const newCount = prevCount + 1;
      tapTimeoutRef.current = setTimeout(() => {
        setTapCount(0);
      }, 1000);
      return newCount;
    });
  };

  const toggleFaq = (id: number) => {
    setOpenFaq(openFaq === id ? null : id);
  };

  // Get current domain dynamically for production URLs
  // This ensures URLs work correctly on any deployment domain (e.g., wassle.ps, vercel.app, etc.)
  const getBaseUrl = () => {
    // Use environment variable if set (useful for custom domains)
    // Set VITE_BASE_URL=https://www.wassle.ps in Vercel environment variables if needed
    const envBaseUrl = import.meta.env.VITE_BASE_URL;
    if (envBaseUrl) {
      return envBaseUrl.endsWith('/') ? envBaseUrl.slice(0, -1) : envBaseUrl;
    }
    // Fallback to current window origin (automatically uses deployment domain)
    // This will be https://www.wassle.ps in production, or localhost:3000 in development
    if (typeof window !== 'undefined') {
      return window.location.origin;
    }
    // Default fallback (shouldn't happen in browser environment)
    return 'https://www.wassle.ps';
  };

  const baseUrl = getBaseUrl();

  // App download links
  const iosAppUrl = 'https://apps.apple.com/app/your-app-id';
  const androidAppUrl = 'https://play.google.com/store/apps/details?id=your.app.id';
  const officialWebsiteUrl = baseUrl;
  const privacyPolicyUrl = `${baseUrl}/privacy-policy`;
  const termsUrl = `${baseUrl}/terms`;

  // Navigation items
  const navItems = [
    { id: 'home', label: t('nav.home') },
    { id: 'features', label: t('nav.features') },
    { id: 'screenshots', label: t('nav.screenshots') },
    { id: 'support', label: t('nav.support') },
    // { id: 'pricing', label: t('nav.pricing') }, // Hidden
    { id: 'blog', label: t('nav.blog') },
    { id: 'contact', label: t('nav.contact') },
  ];

  return (
    <div className="min-h-screen bg-white">
      {/* Header with Navigation */}
      <header className="bg-gradient-to-r from-purple-700 via-purple-800 to-purple-900 sticky top-0 z-50 shadow-lg backdrop-blur-sm bg-opacity-95">
        <div className="max-w-7xl mx-auto px-2 sm:px-3 lg:px-4">
          <div className="flex justify-between items-center py-4">
            <button
              onClick={handleLogoClick}
              className="flex items-center space-x-2 rtl:space-x-reverse cursor-pointer group transition-all duration-300 hover:scale-105"
              aria-label="Wassle Logo"
            >
              <div className="relative">
                <Package className="w-8 h-8 text-white transition-transform duration-300 group-hover:rotate-12" />
                <Sparkles className="w-4 h-4 text-yellow-300 absolute -top-1 -right-1 animate-pulse" />
              </div>
              <h1 className="text-2xl font-bold text-white bg-gradient-to-r from-white to-purple-200 bg-clip-text text-transparent">
                {t('app.name')}
              </h1>
            </button>
            
            {/* Navigation Menu */}
            <nav className="hidden md:flex items-center space-x-6 rtl:space-x-reverse">
              {navItems.map((item) => (
                <a
                  key={item.id}
                  href={`#${item.id}`}
                  onClick={(e) => handleNavClick(e, item.id)}
                  className={`text-white font-medium hover:text-purple-200 transition-all duration-300 relative group ${
                    activeSection === item.id ? 'text-white' : 'text-white/90'
                  }`}
                >
                  {item.label}
                  {activeSection === item.id && (
                    <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-white animate-fade-in-up"></span>
                  )}
                  <span className="absolute bottom-0 left-0 right-0 h-0.5 bg-purple-200 scale-x-0 group-hover:scale-x-100 transition-transform duration-300"></span>
                </a>
              ))}
            </nav>

            {/* Mobile Menu Button */}
            <button
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              className="md:hidden text-white p-2"
              aria-label="Toggle Menu"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                {mobileMenuOpen ? (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 6h16M4 12h16M4 18h16" />
                )}
              </svg>
            </button>

            {/* Language Toggle */}
            <button
              onClick={() => setLanguage(language === 'en' ? 'ar' : 'en')}
              className="px-4 py-2 rounded-lg bg-white/10 hover:bg-white/20 transition-all duration-300 text-sm font-medium text-white border border-white/20 hover:scale-105 hover:shadow-lg"
              aria-label="Toggle Language"
            >
              {language === 'en' ? 'العربية' : 'English'}
            </button>
          </div>
          
          {/* Mobile Menu */}
          {mobileMenuOpen && (
            <nav className="md:hidden py-4 border-t border-white/20">
              <div className="flex flex-col space-y-4">
                {navItems.map((item) => (
                  <a
                    key={item.id}
                    href={`#${item.id}`}
                    onClick={(e) => handleNavClick(e, item.id)}
                    className={`text-white font-medium hover:text-purple-200 transition-colors ${
                      activeSection === item.id ? 'text-white font-semibold' : 'text-white/90'
                    }`}
                  >
                    {item.label}
                  </a>
                ))}
              </div>
            </nav>
          )}
        </div>
      </header>

      {/* Hero Section with Background Image and Overlay */}
      <section 
        id="home"
        ref={(el) => { sectionRefs.current['home'] = el; }}
        data-section-id="home"
        className="relative min-h-[85vh] md:min-h-[80vh] lg:min-h-[75vh] flex items-center justify-center overflow-hidden hero-section-bg pb-0"
        style={{
          backgroundImage: `url('https://res-console.cloudinary.com/wassle/thumbnails/v1/image/upload/v1764136040/YmFubmFyX2JkdDV6dw==/drilldown')`,
        }}
      >
        {/* Gradient Overlay with Animation */}
        <div className="absolute inset-0 bg-gradient-to-br from-purple-900/70 via-purple-800/60 to-blue-900/70"></div>
        <div className="absolute inset-0 bg-black/30"></div>
        
        {/* Floating decorative elements */}
        <div className="absolute top-20 left-10 w-20 h-20 bg-purple-400/20 rounded-full blur-xl float-element"></div>
        <div className="absolute bottom-20 right-10 w-32 h-32 bg-blue-400/20 rounded-full blur-xl float-element" style={{ animationDelay: '2s' }}></div>
        <div className="absolute top-1/2 right-1/4 w-16 h-16 bg-pink-400/20 rounded-full blur-lg float-element" style={{ animationDelay: '4s' }}></div>
        
        {/* Hero Content */}
        <div className="relative z-10 max-w-7xl mx-auto px-3 sm:px-4 lg:px-6 py-12 md:py-20 pb-20 md:pb-24 lg:pb-32 w-full">
          <div className={`flex flex-col ${language === 'ar' ? 'lg:flex-row-reverse' : 'lg:flex-row'} items-center gap-12 lg:gap-40 xl:gap-48 2xl:gap-56`}>
            {/* Text Section */}
            <div className={`flex-1 ${language === 'ar' ? 'lg:text-right lg:pl-20 xl:pl-24 2xl:pl-28' : 'lg:text-left lg:pr-20 xl:pr-24 2xl:pr-28'} text-center lg:text-left w-full lg:w-auto ${
              visibleSections.has('home') ? 'animate-fade-in-up animate-visible' : 'opacity-0'
            }`}>
              <div className="inline-flex items-center gap-2 px-4 py-2 bg-white/10 backdrop-blur-sm rounded-full mb-6 border border-white/20">
                <Zap className="w-4 h-4 text-yellow-300" />
                <span className="text-sm text-white font-medium">{language === 'en' ? 'Fast & Reliable Delivery' : 'توصيل سريع وموثوق'}</span>
              </div>
              <h1 className="text-4xl md:text-5xl lg:text-6xl xl:text-7xl font-extrabold text-white mb-6 leading-tight drop-shadow-2xl bg-gradient-to-r from-white via-purple-100 to-blue-100 bg-clip-text text-transparent">
                {t('hero.title')}
              </h1>
              <p className="text-lg md:text-xl lg:text-2xl text-white/95 mb-8 leading-relaxed max-w-2xl mx-auto lg:mx-0 drop-shadow-lg">
                {t('hero.subtitle')}
              </p>
              <div className={`flex flex-col sm:flex-row gap-4 justify-center ${language === 'ar' ? 'lg:justify-start lg:flex-row-reverse' : 'lg:justify-start'}`}>
                <a
                  href={androidAppUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group inline-flex items-center gap-3 px-6 py-4 bg-white text-gray-900 font-semibold rounded-xl hover:bg-gray-50 transition-all duration-300 shadow-2xl hover:shadow-purple-500/50 hover:scale-110 hover:-translate-y-1"
                >
                  <Smartphone className="w-6 h-6 flex-shrink-0 transition-transform group-hover:rotate-12" />
                  <div className={`${language === 'ar' ? 'text-right' : 'text-left'}`}>
                    <div className="text-xs text-gray-600">
                      {language === 'en' ? 'Available on' : 'متوفر على'}
                    </div>
                    <div className="text-lg font-bold">Google Play</div>
                  </div>
                </a>
                <a
                  href={iosAppUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="group inline-flex items-center gap-3 px-6 py-4 bg-white text-gray-900 font-semibold rounded-xl hover:bg-gray-50 transition-all duration-300 shadow-2xl hover:shadow-blue-500/50 hover:scale-110 hover:-translate-y-1"
                >
                  <Smartphone className="w-6 h-6 flex-shrink-0 transition-transform group-hover:rotate-12" />
                  <div className={`${language === 'ar' ? 'text-right' : 'text-left'}`}>
                    <div className="text-xs text-gray-600">
                      {language === 'en' ? 'Download on' : 'حمّل من'}
                    </div>
                    <div className="text-lg font-bold">App Store</div>
                  </div>
                </a>
              </div>
            </div>

            {/* Image Section with Animation */}
            <div className={`flex-1 flex items-center justify-center w-full lg:w-auto ${language === 'ar' ? 'lg:pr-20 xl:pr-24 2xl:pr-28' : 'lg:pl-20 xl:pl-24 2xl:pl-28'} ${
              visibleSections.has('home') ? 'animate-fade-in-right animate-visible animate-delay-200' : 'opacity-0'
            }`}>
              <div className="relative w-full max-w-md lg:max-w-lg xl:max-w-xl">
                {/* Glowing background effect */}
                <div className="absolute inset-0 bg-gradient-to-r from-purple-500/30 to-blue-500/30 rounded-3xl blur-3xl -z-10"></div>
                
                {/* App Mockup Image with Floating Animation */}
                <img
                  src="https://www.athenastudio.co/themes/naxos/images/banner/single-welcome.png"
                  alt="Wassle App Preview"
                  className="w-full h-auto rounded-2xl shadow-2xl animated-image hover-glow transition-all duration-500"
                  style={{
                    filter: 'drop-shadow(0 25px 50px rgba(139, 92, 246, 0.4))',
                    maxHeight: '70vh',
                    objectFit: 'contain',
                  }}
                />
                
                {/* Decorative sparkles */}
                <Sparkles className="absolute -top-4 -right-4 w-8 h-8 text-yellow-300 animate-pulse" />
                <Sparkles className="absolute -bottom-4 -left-4 w-6 h-6 text-purple-300 animate-pulse" style={{ animationDelay: '1s' }} />
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section 
        id="features" 
        ref={(el) => { sectionRefs.current['features'] = el; }}
        data-section-id="features"
        className="py-20 bg-gradient-to-b from-white via-purple-50/30 to-white scroll-mt-20 relative overflow-hidden"
      >
        {/* Background decoration */}
        <div className="absolute top-0 left-0 w-72 h-72 bg-purple-200/20 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2"></div>
        <div className="absolute bottom-0 right-0 w-96 h-96 bg-blue-200/20 rounded-full blur-3xl translate-x-1/2 translate-y-1/2"></div>
        
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div 
            className={`mb-16 ${
              visibleSections.has('features') ? 'animate-fade-in-up animate-visible' : 'opacity-0'
            }`}
            dir={language === 'ar' ? 'rtl' : 'ltr'}
          >
            {/* Badge */}
            <div className={`flex items-center justify-center mb-4 ${
              language === 'ar' ? 'flex-row-reverse' : ''
            }`}>
              <div className={`inline-flex items-center gap-2 px-4 py-2 bg-purple-100 rounded-full ${
                language === 'ar' ? 'flex-row-reverse' : ''
              }`}>
                <Sparkles className="w-4 h-4 text-purple-600 flex-shrink-0" />
                <span className="text-sm font-semibold text-purple-600">{language === 'en' ? 'Features' : 'المميزات'}</span>
              </div>
            </div>
            
            {/* Title */}
            <h2 
              className="text-center text-3xl sm:text-4xl md:text-5xl font-bold mb-4 px-2 mx-auto w-full"
              style={{
                backgroundImage: language === 'ar' 
                  ? 'linear-gradient(to left, #9333ea, #2563eb)' 
                  : 'linear-gradient(to right, #9333ea, #2563eb)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text',
                color: 'transparent',
                wordBreak: language === 'ar' ? 'keep-all' : 'break-word',
                lineHeight: '1.3',
                hyphens: 'none',
                maxWidth: '100%',
                display: 'block',
                overflowWrap: 'break-word',
                wordWrap: 'break-word',
              }}
            >
              {t('features.title')}
            </h2>
            
            {/* Subtitle */}
            <p className="text-lg sm:text-xl text-slate-600 max-w-2xl mx-auto leading-relaxed px-2 text-center break-words">
              {t('hero.subtitle')}
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
            {[
              { icon: Clock, title: t('features.fast.title'), desc: t('features.fast.description'), color: 'blue' },
              { icon: MapPin, title: t('features.tracking.title'), desc: t('features.tracking.description'), color: 'green' },
              { icon: Shield, title: t('features.secure.title'), desc: t('features.secure.description'), color: 'purple' },
              { icon: Package, title: t('features.selection.title'), desc: t('features.selection.description'), color: 'orange' },
              { icon: Smartphone, title: t('features.easy.title'), desc: t('features.easy.description'), color: 'red' },
              { icon: Clock, title: t('features.available.title'), desc: t('features.available.description'), color: 'teal' },
            ].map((feature, index) => {
              const Icon = feature.icon;
              const colorClasses = {
                blue: 'bg-gradient-to-br from-blue-100 to-blue-200 text-blue-600',
                green: 'bg-gradient-to-br from-green-100 to-green-200 text-green-600',
                purple: 'bg-gradient-to-br from-purple-100 to-purple-200 text-purple-600',
                orange: 'bg-gradient-to-br from-orange-100 to-orange-200 text-orange-600',
                red: 'bg-gradient-to-br from-red-100 to-red-200 text-red-600',
                teal: 'bg-gradient-to-br from-teal-100 to-teal-200 text-teal-600',
              };
              const isVisible = visibleSections.has('features');
              return (
                <div 
                  key={index} 
                  className={`bg-white p-8 rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 border border-slate-100 hover:border-purple-200 hover:-translate-y-2 group ${
                    isVisible ? 'animate-scale-in animate-visible' : 'opacity-0'
                  }`}
                  style={{ 
                    animationDelay: `${index * 0.1}s`,
                  }}
                >
                  <div className={`w-16 h-16 ${colorClasses[feature.color as keyof typeof colorClasses]} rounded-2xl flex items-center justify-center mb-6 transition-transform duration-300 group-hover:scale-110 group-hover:rotate-6 shadow-md`}>
                    <Icon className="w-8 h-8" />
                  </div>
                  <h3 className="text-xl font-bold text-slate-900 mb-3 group-hover:text-purple-600 transition-colors">{feature.title}</h3>
                  <p className="text-slate-600 leading-relaxed">{feature.desc}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Screenshots Section */}
      <section 
        id="screenshots" 
        ref={(el) => { sectionRefs.current['screenshots'] = el; }}
        data-section-id="screenshots"
        className="py-20 bg-gradient-to-br from-slate-50 via-purple-50/50 to-blue-50 scroll-mt-20 relative overflow-hidden"
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className={`text-center mb-16 ${
            visibleSections.has('screenshots') ? 'animate-fade-in-up animate-visible' : 'opacity-0'
          }`}>
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 rounded-full mb-4">
              <Smartphone className="w-4 h-4 text-blue-600" />
              <span className="text-sm font-semibold text-blue-600">{language === 'en' ? 'Screenshots' : 'لقطات الشاشة'}</span>
            </div>
            <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-4 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              {language === 'en' ? 'App Screenshots' : 'لقطات الشاشة'}
            </h2>
            <p className="text-xl text-slate-600 max-w-2xl mx-auto">
              {language === 'en' 
                ? 'See how Wassle works with these app screenshots' 
                : 'شاهد كيف يعمل وصلي من خلال لقطات الشاشة هذه'}
            </p>
          </div>
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
            {[1, 2, 3, 4, 5, 6, 7, 8].map((num) => {
              const isVisible = visibleSections.has('screenshots');
              return (
                <div 
                  key={num} 
                  className={`bg-white rounded-2xl shadow-lg overflow-hidden hover:shadow-2xl transition-all duration-300 hover:-translate-y-2 group ${
                    isVisible ? `animate-scale-in animate-visible` : 'opacity-0'
                  }`}
                  style={{ animationDelay: `${(num - 1) * 0.1}s` }}
                >
                  <div className="w-full aspect-[9/16] bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500 flex items-center justify-center relative overflow-hidden group-hover:scale-105 transition-transform duration-300">
                    <div className="absolute inset-0 bg-black/10 group-hover:bg-black/0 transition-colors"></div>
                    <div className="text-white text-center p-4 relative z-10">
                      <Smartphone className="w-16 h-16 mx-auto mb-2 opacity-80 group-hover:opacity-100 group-hover:scale-110 transition-all duration-300" />
                      <p className="text-sm font-semibold">
                        {language === 'en' ? `Screenshot ${num}` : `لقطة ${num}`}
                      </p>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Testimonials Section */}
      <section className="py-20 bg-gradient-to-b from-white to-purple-50/30 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-96 h-96 bg-purple-200/10 rounded-full blur-3xl"></div>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className="text-center mb-16 animate-fade-in-up">
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-yellow-100 rounded-full mb-4">
              <Star className="w-4 h-4 text-yellow-600 fill-yellow-600" />
              <span className="text-sm font-semibold text-yellow-600">{language === 'en' ? 'Testimonials' : 'الشهادات'}</span>
            </div>
            <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-4 bg-gradient-to-r from-yellow-600 to-orange-600 bg-clip-text text-transparent">
              {t('testimonials.title')}
            </h2>
            <p className="text-xl text-slate-600 max-w-2xl mx-auto">
              {t('testimonials.subtitle')}
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {testimonials.map((testimonial, index) => (
              <div 
                key={testimonial.id} 
                className="bg-white p-8 rounded-2xl shadow-lg hover:shadow-2xl transition-all duration-300 hover:-translate-y-2 border border-slate-100 hover:border-purple-200 group"
                style={{ animationDelay: `${index * 0.15}s` }}
              >
                <div className="flex gap-1 mb-4">
                  {[...Array(testimonial.rating)].map((_, i) => (
                    <Star key={i} className="w-5 h-5 fill-yellow-400 text-yellow-400 group-hover:scale-110 transition-transform" style={{ transitionDelay: `${i * 0.05}s` }} />
                  ))}
                </div>
                <p className="text-slate-700 mb-6 leading-relaxed italic text-lg">
                  "{testimonial.text}"
                </p>
                <div className="pt-4 border-t border-slate-100">
                  <div className="font-bold text-slate-900 text-lg">{testimonial.author}</div>
                  <div className="text-sm text-slate-600">{testimonial.role}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>



      {/* Support Section */}
      <section 
        id="support" 
        ref={(el) => { sectionRefs.current['support'] = el; }}
        data-section-id="support"
        className="py-20 bg-gradient-to-br from-slate-50 via-blue-50/50 to-purple-50/30 scroll-mt-20 relative overflow-hidden"
      >
        <div className="absolute top-0 right-0 w-72 h-72 bg-blue-200/20 rounded-full blur-3xl"></div>
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className={`text-center mb-16 ${
            visibleSections.has('support') ? 'animate-fade-in-up animate-visible' : 'opacity-0'
          }`}>
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 rounded-full mb-4">
              <ChevronDown className="w-4 h-4 text-blue-600" />
              <span className="text-sm font-semibold text-blue-600">{language === 'en' ? 'FAQ' : 'الأسئلة الشائعة'}</span>
            </div>
            <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-4 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              {t('faq.title')}
            </h2>
            <p className="text-xl text-slate-600">
              {t('faq.subtitle')}
            </p>
          </div>
          <div className="space-y-4">
            {faqs.map((faq, index) => {
              const isVisible = visibleSections.has('support');
              return (
                <div 
                  key={faq.id} 
                  className={`bg-white rounded-2xl shadow-lg overflow-hidden border border-slate-100 hover:border-purple-200 transition-all duration-300 hover:shadow-xl ${
                    isVisible ? 'animate-slide-in-bottom animate-visible' : 'opacity-0'
                  }`}
                  style={{ animationDelay: `${index * 0.1}s` }}
                >
                  <button
                    onClick={() => toggleFaq(faq.id)}
                    className="w-full px-6 py-5 flex justify-between items-center text-left hover:bg-gradient-to-r hover:from-purple-50 hover:to-blue-50 transition-all duration-300 group"
                  >
                    <span className="font-semibold text-slate-900 pr-4 group-hover:text-purple-600 transition-colors">{faq.question}</span>
                    <div className={`flex-shrink-0 transition-transform duration-300 ${openFaq === faq.id ? 'rotate-180' : ''}`}>
                      {openFaq === faq.id ? (
                        <ChevronUp className="w-5 h-5 text-purple-600" />
                      ) : (
                        <ChevronDown className="w-5 h-5 text-slate-600 group-hover:text-purple-600 transition-colors" />
                      )}
                    </div>
                  </button>
                  {openFaq === faq.id && (
                    <div className="px-6 pb-5 animate-fade-in-up">
                      <p className="text-slate-600 leading-relaxed">{faq.answer}</p>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
          <div className="mt-12 text-center">
            <p className="text-slate-600 mb-4">{t('faq.stillHaveQuestion')}</p>
            <a
              href="#contact"
              onClick={(e) => handleNavClick(e, 'contact')}
              className="text-blue-600 font-semibold hover:text-blue-700 underline"
            >
              {t('faq.askQuestion')}
            </a>
          </div>
        </div>
      </section>

      {/* Pricing Section - Hidden */}
      {/* <section 
        id="pricing" 
        ref={(el) => { sectionRefs.current['pricing'] = el; }}
        data-section-id="pricing"
        className="py-20 bg-gradient-to-b from-white via-purple-50/30 to-white scroll-mt-20 relative overflow-hidden"
      >
        <div className="absolute top-0 left-1/2 w-96 h-96 bg-purple-200/20 rounded-full blur-3xl -translate-x-1/2"></div>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className={`text-center mb-16 ${
            visibleSections.has('pricing') ? 'animate-fade-in-up animate-visible' : 'opacity-0'
          }`}>
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-purple-100 rounded-full mb-4">
              <Package className="w-4 h-4 text-purple-600" />
              <span className="text-sm font-semibold text-purple-600">{language === 'en' ? 'Pricing' : 'الأسعار'}</span>
            </div>
            <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-4 bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
              {language === 'en' ? 'Pricing Plans' : 'خطط الأسعار'}
            </h2>
            <p className="text-xl text-slate-600 max-w-2xl mx-auto">
              {language === 'en' 
                ? 'Choose the perfect plan for your delivery needs' 
                : 'اختر الخطة المثالية لاحتياجات التوصيل الخاصة بك'}
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 max-w-5xl mx-auto">
            {[
              {
                name: language === 'en' ? 'Basic' : 'أساسي',
                price: language === 'en' ? 'Free' : 'مجاني',
                features: [
                  language === 'en' ? 'Up to 10 deliveries/month' : 'حتى 10 توصيلات/شهر',
                  language === 'en' ? 'Basic tracking' : 'تتبع أساسي',
                  language === 'en' ? 'Email support' : 'دعم عبر البريد الإلكتروني',
                ],
                popular: false,
              },
              {
                name: language === 'en' ? 'Professional' : 'احترافي',
                price: language === 'en' ? '$29/month' : '29$/شهر',
                features: [
                  language === 'en' ? 'Unlimited deliveries' : 'توصيلات غير محدودة',
                  language === 'en' ? 'Real-time tracking' : 'تتبع في الوقت الفعلي',
                  language === 'en' ? 'Priority support' : 'دعم ذو أولوية',
                  language === 'en' ? 'Advanced analytics' : 'تحليلات متقدمة',
                ],
                popular: true,
              },
              {
                name: language === 'en' ? 'Enterprise' : 'مؤسسي',
                price: language === 'en' ? 'Custom' : 'مخصص',
                features: [
                  language === 'en' ? 'Everything in Professional' : 'كل شيء في الاحترافي',
                  language === 'en' ? 'Dedicated account manager' : 'مدير حساب مخصص',
                  language === 'en' ? 'Custom integrations' : 'تكاملات مخصصة',
                  language === 'en' ? '24/7 phone support' : 'دعم هاتفي على مدار الساعة',
                ],
                popular: false,
              },
            ].map((plan, index) => {
              const isVisible = visibleSections.has('pricing');
              return (
                <div
                  key={index}
                  className={`bg-white rounded-3xl shadow-xl p-8 relative transition-all duration-300 hover:shadow-2xl hover:-translate-y-2 ${
                    plan.popular 
                      ? 'border-2 border-blue-600 scale-105 md:scale-110 bg-gradient-to-br from-blue-50 to-purple-50' 
                      : 'border border-slate-200 hover:border-purple-200'
                  } ${
                    isVisible ? `animate-scale-in animate-visible` : 'opacity-0'
                  }`}
                  style={{ animationDelay: `${index * 0.15}s` }}
                >
                  {plan.popular && (
                    <div className="absolute -top-4 left-1/2 -translate-x-1/2 bg-gradient-to-r from-blue-600 to-purple-600 text-white px-6 py-2 rounded-full text-sm font-semibold shadow-lg animate-pulse">
                      {language === 'en' ? 'Popular' : 'الأكثر شعبية'}
                    </div>
                  )}
                  <h3 className="text-2xl font-bold text-slate-900 mb-2">{plan.name}</h3>
                  <div className="text-4xl font-bold bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent mb-6">{plan.price}</div>
                  <ul className="space-y-3 mb-8">
                    {plan.features.map((feature, idx) => (
                      <li key={idx} className="flex items-start group/item">
                        <Check className="w-5 h-5 text-green-500 mr-2 flex-shrink-0 mt-0.5 group-hover/item:scale-110 transition-transform" />
                        <span className="text-slate-600">{feature}</span>
                      </li>
                    ))}
                  </ul>
                  <button
                    className={`w-full py-3 px-6 rounded-xl font-semibold transition-all duration-300 hover:scale-105 ${
                      plan.popular
                        ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white hover:from-blue-700 hover:to-purple-700 shadow-lg hover:shadow-xl'
                        : 'bg-slate-100 text-slate-900 hover:bg-slate-200 hover:shadow-md'
                    }`}
                  >
                    {language === 'en' ? 'Get Started' : 'ابدأ الآن'}
                  </button>
                </div>
              );
            })}
          </div>
        </div>
      </section> */}

      {/* Blog Section */}
      <section 
        id="blog" 
        ref={(el) => { sectionRefs.current['blog'] = el; }}
        data-section-id="blog"
        className="py-20 bg-gradient-to-br from-slate-50 via-blue-50/50 to-purple-50/30 scroll-mt-20 relative overflow-hidden"
      >
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-blue-200/10 rounded-full blur-3xl"></div>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className={`text-center mb-16 ${
            visibleSections.has('blog') ? 'animate-fade-in-up animate-visible' : 'opacity-0'
          }`}>
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-blue-100 rounded-full mb-4">
              <Package className="w-4 h-4 text-blue-600" />
              <span className="text-sm font-semibold text-blue-600">{language === 'en' ? 'Blog' : 'المدونة'}</span>
            </div>
            <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-4 bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
              {language === 'en' ? 'Latest Blog Posts' : 'أحدث المقالات'}
            </h2>
            <p className="text-xl text-slate-600 max-w-2xl mx-auto">
              {language === 'en' 
                ? 'Stay updated with the latest news and tips' 
                : 'ابق على اطلاع بآخر الأخبار والنصائح'}
            </p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {[1, 2, 3].map((num, index) => {
              const isVisible = visibleSections.has('blog');
              return (
                <article 
                  key={num} 
                  className={`bg-white rounded-2xl shadow-lg overflow-hidden hover:shadow-2xl transition-all duration-300 hover:-translate-y-2 border border-slate-100 hover:border-purple-200 group ${
                    isVisible ? `animate-scale-in animate-visible` : 'opacity-0'
                  }`}
                  style={{ animationDelay: `${index * 0.15}s` }}
                >
                  <div className="w-full h-48 bg-gradient-to-br from-blue-500 via-purple-500 to-pink-500 flex items-center justify-center relative overflow-hidden group-hover:scale-105 transition-transform duration-300">
                    <div className="absolute inset-0 bg-black/10 group-hover:bg-black/0 transition-colors"></div>
                    <Package className="w-20 h-20 text-white opacity-80 group-hover:opacity-100 group-hover:scale-110 transition-all duration-300 relative z-10" />
                  </div>
                  <div className="p-6">
                    <div className="text-sm text-slate-500 mb-2">
                      {language === 'en' ? 'January 15, 2024' : '15 يناير 2024'}
                    </div>
                    <h3 className="text-xl font-bold text-slate-900 mb-3 group-hover:text-purple-600 transition-colors">
                      {language === 'en' 
                        ? `How to Optimize Your Delivery Experience ${num}`
                        : `كيفية تحسين تجربة التوصيل الخاصة بك ${num}`}
                    </h3>
                    <p className="text-slate-600 mb-4">
                      {language === 'en' 
                        ? 'Learn the best practices for getting the most out of Wassle delivery services.'
                        : 'تعلم أفضل الممارسات للاستفادة القصوى من خدمات التوصيل في وصلي.'}
                    </p>
                    <a
                      href="#"
                      className="inline-flex items-center gap-2 text-blue-600 font-semibold hover:text-purple-600 transition-colors group/link"
                    >
                      {language === 'en' ? 'Read More' : 'اقرأ المزيد'}
                      <span className="group-hover/link:translate-x-1 transition-transform">→</span>
                    </a>
                  </div>
                </article>
              );
            })}
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section 
        id="contact" 
        ref={(el) => { sectionRefs.current['contact'] = el; }}
        data-section-id="contact"
        className="py-20 bg-gradient-to-b from-white to-purple-50/30 scroll-mt-20 relative overflow-hidden"
      >
        <div className="absolute top-0 right-0 w-72 h-72 bg-purple-200/20 rounded-full blur-3xl"></div>
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-blue-200/20 rounded-full blur-3xl"></div>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 relative z-10">
          <div className={`text-center mb-16 ${
            visibleSections.has('contact') ? 'animate-fade-in-up animate-visible' : 'opacity-0'
          }`}>
            <div className="inline-flex items-center gap-2 px-4 py-2 bg-purple-100 rounded-full mb-4">
              <Mail className="w-4 h-4 text-purple-600" />
              <span className="text-sm font-semibold text-purple-600">{language === 'en' ? 'Contact' : 'اتصل بنا'}</span>
            </div>
            <h2 className="text-4xl md:text-5xl font-bold text-slate-900 mb-4 bg-gradient-to-r from-purple-600 to-blue-600 bg-clip-text text-transparent">
              {language === 'en' ? 'Get In Touch' : 'تواصل معنا'}
            </h2>
            <p className="text-xl text-slate-600 max-w-2xl mx-auto">
              {language === 'en' 
                ? 'Have questions? We\'d love to hear from you. Send us a message and we\'ll respond as soon as possible.'
                : 'لديك أسئلة؟ نحب أن نسمع منك. أرسل لنا رسالة وسنرد في أقرب وقت ممكن.'}
            </p>
          </div>
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12">
            <div>
              <h3 className="text-2xl font-bold text-slate-900 mb-6">
                {language === 'en' ? 'Contact Information' : 'معلومات الاتصال'}
              </h3>
              <div className="space-y-6">
                <div className="flex items-start">
                  <Globe className="w-6 h-6 text-blue-600 mr-4 flex-shrink-0 mt-1" />
                  <div>
                    <h4 className="font-semibold text-slate-900 mb-1">
                      {language === 'en' ? 'Address' : 'العنوان'}
                    </h4>
                    <p className="text-slate-600">
                      {language === 'en' 
                        ? '123 Delivery Street, City, Country'
                        : '123 شارع التوصيل، المدينة، البلد'}
                    </p>
                  </div>
                </div>
                <div className="flex items-start">
                  <Mail className="w-6 h-6 text-blue-600 mr-4 flex-shrink-0 mt-1" />
                  <div>
                    <h4 className="font-semibold text-slate-900 mb-1">
                      {language === 'en' ? 'Email' : 'البريد الإلكتروني'}
                    </h4>
                    <p className="text-slate-600">support@wassle.com</p>
                  </div>
                </div>
                <div className="flex items-start">
                  <Smartphone className="w-6 h-6 text-blue-600 mr-4 flex-shrink-0 mt-1" />
                  <div>
                    <h4 className="font-semibold text-slate-900 mb-1">
                      {language === 'en' ? 'Phone' : 'الهاتف'}
                    </h4>
                    <p className="text-slate-600">+1 (234) 567-8900</p>
                  </div>
                </div>
              </div>
            </div>
            <div>
              <form className="space-y-6">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">
                      {language === 'en' ? 'Name' : 'الاسم'}
                    </label>
                    <input
                      type="text"
                      className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder={language === 'en' ? 'Your Name' : 'اسمك'}
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-700 mb-2">
                      {language === 'en' ? 'Email' : 'البريد الإلكتروني'}
                    </label>
                    <input
                      type="email"
                      className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                      placeholder={language === 'en' ? 'your@email.com' : 'بريدك@الإلكتروني.com'}
                    />
                  </div>
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    {language === 'en' ? 'Subject' : 'الموضوع'}
                  </label>
                  <input
                    type="text"
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder={language === 'en' ? 'Subject' : 'الموضوع'}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 mb-2">
                    {language === 'en' ? 'Message' : 'الرسالة'}
                  </label>
                  <textarea
                    rows={6}
                    className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder={language === 'en' ? 'Your message...' : 'رسالتك...'}
                  ></textarea>
                </div>
                <button
                  type="submit"
                  className="w-full bg-gradient-to-r from-blue-600 to-purple-600 text-white py-3 px-6 rounded-xl font-semibold hover:from-blue-700 hover:to-purple-700 transition-all duration-300 shadow-lg hover:shadow-xl hover:scale-105"
                >
                  {language === 'en' ? 'Send Message' : 'إرسال الرسالة'}
                </button>
              </form>
            </div>
          </div>
        </div>
      </section>

   

      {/* Footer */}
      <footer className="bg-slate-900 text-white py-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-12">
            {/* Company Info */}
            <div>
              <div className="flex items-center space-x-2 rtl:space-x-reverse mb-4">
                <Package className="w-8 h-8 text-blue-400" />
                <h3 className="text-2xl font-bold">{t('app.name')}</h3>
              </div>
              <p className="text-slate-400 mb-6">
                {t('hero.subtitle')}
              </p>
              <div className="flex space-x-4 rtl:space-x-reverse">
                <a href="#" className="text-slate-400 hover:text-white transition-colors">
                  <Facebook className="w-5 h-5" />
                </a>
                <a href="#" className="text-slate-400 hover:text-white transition-colors">
                  <Twitter className="w-5 h-5" />
                </a>
                <a href="#" className="text-slate-400 hover:text-white transition-colors">
                  <Instagram className="w-5 h-5" />
                </a>
                <a href="#" className="text-slate-400 hover:text-white transition-colors">
                  <Linkedin className="w-5 h-5" />
                </a>
                <a href="#" className="text-slate-400 hover:text-white transition-colors">
                  <Youtube className="w-5 h-5" />
                </a>
              </div>
            </div>

            {/* Useful Links */}
            <div>
              <h4 className="text-lg font-semibold mb-4">{t('footer.usefulLinks')}</h4>
              <ul className="space-y-2">
                <li>
                  <a href="#" className="text-slate-400 hover:text-white transition-colors">
                    {t('footer.support')}
                  </a>
                </li>
                <li>
                  <a href={privacyPolicyUrl} className="text-slate-400 hover:text-white transition-colors">
                    {t('footer.privacy')}
                  </a>
                </li>
                <li>
                  <a href={termsUrl} className="text-slate-400 hover:text-white transition-colors">
                    {t('footer.terms')}
                  </a>
                </li>
                <li>
                  <a href="#" className="text-slate-400 hover:text-white transition-colors">
                    {t('footer.about')}
                  </a>
                </li>
                <li>
                  <a href="#" className="text-slate-400 hover:text-white transition-colors">
                    {t('footer.contact')}
                  </a>
                </li>
              </ul>
            </div>

            {/* Download */}
            <div>
              <h4 className="text-lg font-semibold mb-4">{t('download.title')}</h4>
              <div className="flex flex-col items-start space-y-3">
                <a
                  href={androidAppUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full flex items-center gap-2 px-4 py-2 bg-slate-800 rounded-lg hover:bg-slate-700 transition-colors"
                >
                  <Smartphone className="w-5 h-5 flex-shrink-0" />
                  <div className={`${language === 'ar' ? 'text-right' : 'text-left'}`}>
                    <div className="text-xs text-slate-400">
                      {language === 'en' ? 'Available on' : 'متوفر على'}
                    </div>
                    <div className="text-sm font-semibold">Google Play</div>
                  </div>
                </a>
                <a
                  href={iosAppUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="w-full flex items-center gap-2 px-4 py-2 bg-slate-800 rounded-lg hover:bg-slate-700 transition-colors"
                >
                  <Smartphone className="w-5 h-5 flex-shrink-0" />
                  <div className={`${language === 'ar' ? 'text-right' : 'text-left'}`}>
                    <div className="text-xs text-slate-400">
                      {language === 'en' ? 'Download on' : 'حمّل من'}
                    </div>
                    <div className="text-sm font-semibold">App Store</div>
                  </div>
                </a>
              </div>
            </div>

            {/* Contact Info */}
            <div>
              <h4 className="text-lg font-semibold mb-4">{t('footer.contact')}</h4>
              <ul className="space-y-3 text-slate-400">
                <li className="flex items-start gap-2">
                  <Globe className="w-5 h-5 mt-0.5 flex-shrink-0" />
                  <span>{officialWebsiteUrl}</span>
                </li>
                <li className="flex items-start gap-2">
                  <Mail className="w-5 h-5 mt-0.5 flex-shrink-0" />
                  <span>support@wassle.com</span>
                </li>
              </ul>
            </div>
          </div>

          <div className="border-t border-slate-800 pt-8 text-center">
            <p className="text-slate-400">
              {t('footer.copyright')}
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default Landing;
