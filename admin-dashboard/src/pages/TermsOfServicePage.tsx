import { useState, useEffect } from 'react';
import { useLanguage } from '@/store/language/LanguageContext';
import axios from 'axios';

interface TermsOfService {
  content: string;
  contentAr?: string;
  lastUpdated?: string;
}

// Get API URL from environment or construct from current origin
const getApiBaseUrl = () => {
  // Check if VITE_API_URL is set (highest priority)
  if (import.meta.env.VITE_API_URL) {
    return import.meta.env.VITE_API_URL;
  }
  
  // In production, try to infer from current origin
  if (typeof window !== 'undefined') {
    const origin = window.location.origin;
    const hostname = window.location.hostname;
    
    // If we're on wassle.ps domain, try common backend patterns
    if (hostname.includes('wassle.ps')) {
      // Try multiple common backend URL patterns
      const possibleUrls = [
        'https://api.wassle.ps/api',
        'https://backend.wassle.ps/api',
        'https://wassle.ps/api',
        `${origin}/api`, // Same origin
      ];
      
      // Return the first one (we'll handle errors if it doesn't work)
      // In production, you should set VITE_API_URL explicitly
      return possibleUrls[0];
    }
    
    // For localhost development
    if (hostname === 'localhost' || hostname === '127.0.0.1') {
      return 'http://localhost:5001/api'; // Backend runs on 5001 according to logs
    }
  }
  
  // Fallback to localhost for development
  return 'http://localhost:5001/api';
};

const API_BASE_URL = getApiBaseUrl();

const TermsOfServicePage = () => {
  const { language } = useLanguage();
  const [termsOfService, setTermsOfService] = useState<TermsOfService | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadTermsOfService();
  }, []);

  // Reload when language changes to show correct content
  useEffect(() => {
    if (termsOfService) {
      // Content is already loaded, just re-render with new language
      // The displayContent logic will handle language switching
    }
  }, [language]);

  const loadTermsOfService = async () => {
    try {
      setLoading(true);
      setError(null);
      // Use axios directly without auth for public endpoint
      // Add timestamp to prevent caching
      const url = `${API_BASE_URL}/terms-of-service?_t=${Date.now()}`;
      
      console.log('Fetching terms of service from:', url);
      console.log('API Base URL:', API_BASE_URL);
      console.log('Environment VITE_API_URL:', import.meta.env.VITE_API_URL || 'NOT SET');
      
      const { data } = await axios.get<{ termsOfService: TermsOfService }>(url, {
        timeout: 10000, // 10 second timeout
        headers: {
          'Accept': 'application/json',
        },
      });
      
      console.log('Terms of service data received:', data);
      
      if (data && data.termsOfService) {
        const content = data.termsOfService;
        console.log('Terms of service content length:', content.content?.length || 0);
        console.log('Terms of service Arabic content length:', content.contentAr?.length || 0);
        
        // Check if content is actually empty or just default placeholder
        const hasValidContent = content.content && 
          content.content.trim().length > 0 && 
          !content.content.includes('Your terms of service content goes here');
        
        const hasValidArabicContent = content.contentAr && 
          content.contentAr.trim().length > 0 && 
          !content.contentAr.includes('محتوى شروط الخدمة الخاص بك هنا');
        
        if (!hasValidContent && !hasValidArabicContent) {
          console.warn('Terms of service content appears to be empty or placeholder');
          setError('Terms of service content has not been set up yet. Please contact the administrator.');
        } else {
          setTermsOfService(content);
        }
      } else {
        console.error('Invalid response structure:', data);
        setError('Invalid response from server. The server returned an unexpected format.');
      }
    } catch (err: any) {
      console.error('Error loading terms of service:', err);
      
      let errorMessage = 'Failed to load terms of service.';
      
      if (err.code === 'ECONNABORTED') {
        errorMessage = 'Request timed out. The server is taking too long to respond.';
      } else if (err.code === 'ERR_NETWORK' || err.message.includes('Network Error')) {
        errorMessage = 'Network error. Unable to connect to the server. Please check your internet connection.';
      } else if (err.response) {
        console.error('Error response:', err.response.data);
        console.error('Error status:', err.response.status);
        
        if (err.response.status === 404) {
          errorMessage = 'Terms of service endpoint not found. Please contact the administrator.';
        } else if (err.response.status === 500) {
          errorMessage = 'Server error. Please try again later or contact the administrator.';
        } else {
          errorMessage = err.response?.data?.message || `Server returned error ${err.response.status}`;
        }
      } else {
        errorMessage = err.message || 'An unexpected error occurred.';
      }
      
      setError(errorMessage);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-white flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-slate-600">Loading terms of service...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-white flex items-center justify-center">
        <div className="text-center max-w-md mx-auto px-4">
          <div className="bg-red-50 border border-red-200 rounded-lg p-6 mb-4">
            <h2 className="text-xl font-bold text-red-800 mb-2">Error Loading Terms of Service</h2>
            <p className="text-red-600 mb-2">{error}</p>
            <p className="text-sm text-slate-600 mt-4">
              API URL: {API_BASE_URL}/terms-of-service
            </p>
            <p className="text-xs text-slate-500 mt-2">
              VITE_API_URL env: {import.meta.env.VITE_API_URL || 'NOT SET'}
            </p>
            <p className="text-xs text-slate-500 mt-1">
              Current origin: {typeof window !== 'undefined' ? window.location.origin : 'N/A'}
            </p>
          </div>
          <button
            onClick={loadTermsOfService}
            className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
          >
            Retry Loading
          </button>
        </div>
      </div>
    );
  }

  // Determine which content to display based on language preference
  // Check if we have valid content
  const hasEnglishContent = termsOfService?.content && 
    termsOfService.content.trim().length > 0 && 
    !termsOfService.content.includes('Your terms of service content goes here');
  
  const hasArabicContent = termsOfService?.contentAr && 
    termsOfService.contentAr.trim().length > 0 && 
    !termsOfService.contentAr.includes('محتوى شروط الخدمة الخاص بك هنا');
  
  let displayContent: string | null = null;
  let showEmptyMessage = false;
  
  if (language === 'ar' && hasArabicContent) {
    displayContent = termsOfService!.contentAr!;
  } else if (hasEnglishContent) {
    displayContent = termsOfService!.content;
  } else if (language === 'ar' && hasEnglishContent) {
    // Fallback to English if Arabic not available
    displayContent = termsOfService!.content;
  } else if (hasArabicContent) {
    // Fallback to Arabic if English not available
    displayContent = termsOfService!.contentAr!;
  } else {
    showEmptyMessage = true;
  }
  
  // Debug logging
  console.log('Current language:', language);
  console.log('Terms of service state:', termsOfService);
  console.log('Has English content:', hasEnglishContent);
  console.log('Has Arabic content:', hasArabicContent);
  console.log('Display content:', displayContent ? `${displayContent.substring(0, 100)}...` : 'null');

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-gradient-to-r from-purple-700 via-purple-800 to-purple-900 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <h1 className="text-3xl md:text-4xl font-bold text-white">
            {language === 'en' ? 'Terms of Service' : 'شروط الخدمة'}
          </h1>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {showEmptyMessage ? (
          <div className="text-center py-12">
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6 mb-4">
              <h2 className="text-xl font-bold text-yellow-800 mb-2">
                {language === 'en' ? 'Content Not Available' : 'المحتوى غير متاح'}
              </h2>
              <p className="text-yellow-700 mb-4">
                {language === 'en' 
                  ? 'The terms of service content has not been set up yet. Please contact the administrator or check back later.' 
                  : 'لم يتم إعداد محتوى شروط الخدمة بعد. يرجى الاتصال بالمسؤول أو التحقق لاحقًا.'}
              </p>
            </div>
            <button
              onClick={loadTermsOfService}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              {language === 'en' ? 'Reload Content' : 'إعادة تحميل المحتوى'}
            </button>
          </div>
        ) : displayContent ? (
          <>
            <div 
              className="prose prose-lg max-w-none prose-headings:text-slate-900 prose-p:text-slate-700 prose-a:text-blue-600 prose-strong:text-slate-900"
              dir={language === 'ar' ? 'rtl' : 'ltr'}
              dangerouslySetInnerHTML={{ __html: displayContent }}
            />
            {termsOfService?.lastUpdated && (
              <div className="mt-12 pt-8 border-t border-slate-200 text-sm text-slate-500">
                {language === 'en' ? 'Last updated: ' : 'آخر تحديث: '}
                {new Date(termsOfService.lastUpdated).toLocaleDateString(language === 'ar' ? 'ar-SA' : 'en-US', {
                  year: 'numeric',
                  month: 'long',
                  day: 'numeric',
                })}
              </div>
            )}
          </>
        ) : (
          <div className="text-center py-12">
            <p className="text-slate-600 mb-4">
              {language === 'en' ? 'No terms of service content available.' : 'لا يوجد محتوى لشروط الخدمة.'}
            </p>
            <button
              onClick={loadTermsOfService}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              {language === 'en' ? 'Reload Content' : 'إعادة تحميل المحتوى'}
            </button>
          </div>
        )}
      </main>

      {/* Footer */}
      <footer className="bg-slate-900 text-white py-8 mt-16">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <a
            href="/"
            className="text-purple-300 hover:text-white transition-colors underline"
          >
            {language === 'en' ? '← Back to Home' : '← العودة إلى الصفحة الرئيسية'}
          </a>
        </div>
      </footer>
    </div>
  );
};

export default TermsOfServicePage;

