import { useState, useEffect } from 'react';
import { useLanguage } from '@/store/language/LanguageContext';
import axios from 'axios';

interface PrivacyPolicy {
  content: string;
  contentAr?: string;
  lastUpdated?: string;
}

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000/api';

const PrivacyPolicyPage = () => {
  const { language } = useLanguage();
  const [privacyPolicy, setPrivacyPolicy] = useState<PrivacyPolicy | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    loadPrivacyPolicy();
  }, []);

  // Reload when language changes to show correct content
  useEffect(() => {
    if (privacyPolicy) {
      // Content is already loaded, just re-render with new language
      // The displayContent logic will handle language switching
    }
  }, [language]);

  const loadPrivacyPolicy = async () => {
    try {
      setLoading(true);
      setError(null);
      // Use axios directly without auth for public endpoint
      // Add timestamp to prevent caching
      const url = `${API_BASE_URL}/privacy-policy?_t=${Date.now()}`;
      
      if (import.meta.env.DEV) {
        console.log('Fetching privacy policy from:', url);
      }
      
      const { data } = await axios.get<{ privacyPolicy: PrivacyPolicy }>(url);
      
      if (import.meta.env.DEV) {
        console.log('Privacy policy data received:', data);
      }
      
      if (data && data.privacyPolicy) {
        setPrivacyPolicy(data.privacyPolicy);
        if (import.meta.env.DEV) {
          console.log('Privacy policy content length:', data.privacyPolicy.content?.length);
          console.log('Privacy policy Arabic content length:', data.privacyPolicy.contentAr?.length);
        }
      } else {
        console.error('Invalid response structure:', data);
        setError('Invalid response from server');
      }
    } catch (err: any) {
      console.error('Error loading privacy policy:', err);
      if (err.response) {
        console.error('Error response:', err.response.data);
        console.error('Error status:', err.response.status);
      }
      setError(err.response?.data?.message || err.message || 'Failed to load privacy policy. Please check if the backend server is running.');
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-white flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-purple-600 mx-auto"></div>
          <p className="mt-4 text-slate-600">Loading privacy policy...</p>
        </div>
      </div>
    );
  }

  if (error) {
    return (
      <div className="min-h-screen bg-white flex items-center justify-center">
        <div className="text-center max-w-md mx-auto px-4">
          <div className="bg-red-50 border border-red-200 rounded-lg p-6 mb-4">
            <h2 className="text-xl font-bold text-red-800 mb-2">Error Loading Privacy Policy</h2>
            <p className="text-red-600 mb-2">{error}</p>
            <p className="text-sm text-slate-600 mt-4">
              API URL: {API_BASE_URL}/privacy-policy
            </p>
          </div>
          <button
            onClick={loadPrivacyPolicy}
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
  const hasEnglishContent = privacyPolicy?.content && privacyPolicy.content.trim().length > 0;
  const hasArabicContent = privacyPolicy?.contentAr && privacyPolicy.contentAr.trim().length > 0;
  
  let displayContent = '<p>Privacy policy content not available.</p>';
  
  if (language === 'ar' && hasArabicContent) {
    displayContent = privacyPolicy.contentAr!;
  } else if (hasEnglishContent) {
    displayContent = privacyPolicy!.content;
  }
  
  // Debug logging (only in development)
  if (import.meta.env.DEV) {
    console.log('Current language:', language);
    console.log('Privacy policy state:', privacyPolicy);
    console.log('Has English content:', hasEnglishContent);
    console.log('Has Arabic content:', hasArabicContent);
    console.log('Display content length:', displayContent.length);
  }

  return (
    <div className="min-h-screen bg-white">
      {/* Header */}
      <header className="bg-gradient-to-r from-purple-700 via-purple-800 to-purple-900 shadow-lg">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
          <h1 className="text-3xl md:text-4xl font-bold text-white">
            {language === 'en' ? 'Privacy Policy' : 'سياسة الخصوصية'}
          </h1>
        </div>
      </header>

      {/* Content */}
      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {privacyPolicy ? (
          <div 
            className="prose prose-lg max-w-none prose-headings:text-slate-900 prose-p:text-slate-700 prose-a:text-blue-600 prose-strong:text-slate-900"
            dir={language === 'ar' ? 'rtl' : 'ltr'}
            dangerouslySetInnerHTML={{ __html: displayContent }}
          />
        ) : (
          <div className="text-center py-12">
            <p className="text-slate-600 mb-4">No privacy policy content available.</p>
            <button
              onClick={loadPrivacyPolicy}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              Reload Content
            </button>
          </div>
        )}

        {privacyPolicy?.lastUpdated && (
          <div className="mt-12 pt-8 border-t border-slate-200 text-sm text-slate-500">
            {language === 'en' ? 'Last updated: ' : 'آخر تحديث: '}
            {new Date(privacyPolicy.lastUpdated).toLocaleDateString(language === 'ar' ? 'ar-SA' : 'en-US', {
              year: 'numeric',
              month: 'long',
              day: 'numeric',
            })}
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

export default PrivacyPolicyPage;

