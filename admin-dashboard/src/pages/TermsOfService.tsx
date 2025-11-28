import { useState, useEffect } from 'react';
import { getTermsOfService, updateTermsOfService, type TermsOfService as TermsOfServiceType } from '@/services/termsOfServiceService';
import { getSettings, updateSettings } from '@/services/settingsService';

const TermsOfService = () => {
  const [termsOfService, setTermsOfService] = useState<TermsOfServiceType | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [content, setContent] = useState<string>('');
  const [contentAr, setContentAr] = useState<string>('');
  const [termsOfServiceUrl, setTermsOfServiceUrl] = useState<string>('https://www.wassle.ps/terms-of-service');

  useEffect(() => {
    loadTermsOfService();
  }, []);

  const loadTermsOfService = async () => {
    try {
      setLoading(true);
      setError(null);
      
      // Load terms of service content
      const data = await getTermsOfService();
      setTermsOfService(data);
      setContent(data.content || '');
      setContentAr(data.contentAr || '');
      
      // Load terms of service URL from settings
      try {
        const settings = await getSettings();
        if (settings.termsOfServiceUrl) {
          setTermsOfServiceUrl(settings.termsOfServiceUrl);
        }
      } catch (settingsErr) {
        console.warn('Failed to load terms of service URL from settings:', settingsErr);
        // Continue with default URL
      }
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load terms of service');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    // Validate content
    if (!content.trim()) {
      setError('Terms of service content cannot be empty');
      return;
    }

    try {
      setSaving(true);
      setError(null);
      setSuccess(null);

      const contentToSave = content.trim();
      const contentArToSave = contentAr.trim() || undefined;
      
      console.log('Saving terms of service:');
      console.log('English content length:', contentToSave.length);
      console.log('Arabic content length:', contentArToSave?.length || 0);
      console.log('English content preview:', contentToSave.substring(0, 100));
      
      // Update terms of service content
      const updated = await updateTermsOfService({
        content: contentToSave,
        contentAr: contentArToSave,
      });

      console.log('Save successful, received updated terms:');
      console.log('Updated English content length:', updated.content?.length);
      console.log('Updated Arabic content length:', updated.contentAr?.length || 0);
      console.log('Updated English content preview:', updated.content?.substring(0, 100));

      // Update terms of service URL in settings
      try {
        await updateSettings({
          termsOfServiceUrl: termsOfServiceUrl.trim(),
        });
      } catch (urlErr: any) {
        console.warn('Failed to update terms of service URL:', urlErr);
        // Don't fail the whole operation if URL update fails
        setError('Terms of service content updated, but failed to update URL: ' + (urlErr.response?.data?.message || urlErr.message));
        return;
      }

      setTermsOfService(updated);
      setContent(updated.content || contentToSave);
      setContentAr(updated.contentAr || contentArToSave || '');
      setSuccess('Terms of service content and URL updated successfully!');
      
      // Clear success message after 5 seconds
      setTimeout(() => {
        setSuccess(null);
      }, 5000);
    } catch (err: any) {
      console.error('Error saving terms of service:', err);
      console.error('Error response:', err.response?.data);
      setError(err.response?.data?.message || 'Failed to update terms of service');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-4 page-transition">
        <h1 className="text-3xl font-bold text-slate-900">Terms of Service Management</h1>
        <div className="card">
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
              <p className="mt-4 text-slate-600">Loading terms of service...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 page-transition">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Terms of Service Management</h1>
        <p className="mt-2 text-slate-600">
          Update the terms of service content that appears on the landing page.
        </p>
      </div>

      {error && (
        <div className="card bg-red-50 border-red-200 text-red-700 px-4 py-3">
          {error}
        </div>
      )}

      {success && (
        <div className="card bg-green-50 border-green-200 text-green-700 px-4 py-3">
          {success}
        </div>
      )}

      <div className="card">
        <div className="space-y-6">
          {/* Terms of Service URL */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Terms of Service URL <span className="text-red-500">*</span>
            </label>
            <p className="text-xs text-slate-500 mb-2">
              The URL where your Terms of Service is hosted. This will be used in the User and Driver apps and displayed on the Landing Page.
            </p>
            <input
              type="url"
              value={termsOfServiceUrl}
              onChange={(e) => setTermsOfServiceUrl(e.target.value)}
              className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="https://www.wassle.ps/terms-of-service"
            />
            {termsOfServiceUrl && (
              <p className="text-xs text-slate-500 mt-1">
                Current URL: <a href={termsOfServiceUrl} target="_blank" rel="noopener noreferrer" className="text-blue-600 hover:underline">{termsOfServiceUrl}</a>
              </p>
            )}
          </div>

          <div className="border-t border-slate-200 pt-6">
            <h3 className="text-lg font-semibold text-slate-900 mb-4">Terms of Service Content</h3>
          </div>

          {/* English Content */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Terms of Service Content (English) <span className="text-red-500">*</span>
            </label>
            <p className="text-xs text-slate-500 mb-2">
              You can use HTML tags for formatting. The content will be displayed as-is on the terms of service page.
            </p>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={20}
              className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono text-sm"
              placeholder="Enter terms of service content in English (HTML supported)..."
            />
            <p className="text-xs text-slate-500 mt-1">
              {content.length} characters
            </p>
          </div>

          {/* Arabic Content */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Terms of Service Content (Arabic) <span className="text-slate-400">(Optional)</span>
            </label>
            <p className="text-xs text-slate-500 mb-2">
              Arabic version of the terms of service. If not provided, the English version will be used.
            </p>
            <textarea
              value={contentAr}
              onChange={(e) => setContentAr(e.target.value)}
              rows={20}
              className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono text-sm"
              placeholder="Enter terms of service content in Arabic (HTML supported)..."
              dir="rtl"
            />
            <p className="text-xs text-slate-500 mt-1">
              {contentAr.length} characters
            </p>
          </div>

          {/* Preview Section */}
          {content && (
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-2">
                Preview (English)
              </label>
              <div className="border border-slate-300 rounded-lg p-4 bg-slate-50 max-h-96 overflow-y-auto">
                <div dangerouslySetInnerHTML={{ __html: content }} />
              </div>
            </div>
          )}

          {/* Last Updated Info */}
          {termsOfService?.lastUpdated && (
            <div className="text-sm text-slate-500">
              Last updated: {new Date(termsOfService.lastUpdated).toLocaleString()}
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex justify-end gap-4 pt-4 border-t border-slate-200">
            <button
              onClick={loadTermsOfService}
              className="px-4 py-2 border border-slate-300 rounded-lg text-slate-700 hover:bg-slate-50 transition-colors"
              disabled={saving}
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={saving || !content.trim() || !termsOfServiceUrl.trim()}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {saving ? 'Saving...' : 'Save Changes'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default TermsOfService;


