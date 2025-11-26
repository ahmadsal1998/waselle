import { useState, useEffect } from 'react';
import { getPrivacyPolicy, updatePrivacyPolicy, type PrivacyPolicy as PrivacyPolicyType } from '@/services/privacyPolicyService';

const PrivacyPolicy = () => {
  const [privacyPolicy, setPrivacyPolicy] = useState<PrivacyPolicyType | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  const [content, setContent] = useState<string>('');
  const [contentAr, setContentAr] = useState<string>('');

  useEffect(() => {
    loadPrivacyPolicy();
  }, []);

  const loadPrivacyPolicy = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await getPrivacyPolicy();
      setPrivacyPolicy(data);
      setContent(data.content || '');
      setContentAr(data.contentAr || '');
    } catch (err: any) {
      setError(err.response?.data?.message || 'Failed to load privacy policy');
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    // Validate content
    if (!content.trim()) {
      setError('Privacy policy content cannot be empty');
      return;
    }

    try {
      setSaving(true);
      setError(null);
      setSuccess(null);

      const contentToSave = content.trim();
      const contentArToSave = contentAr.trim() || undefined;
      
      console.log('Saving privacy policy:');
      console.log('English content length:', contentToSave.length);
      console.log('Arabic content length:', contentArToSave?.length || 0);
      console.log('English content preview:', contentToSave.substring(0, 100));
      
      const updated = await updatePrivacyPolicy({
        content: contentToSave,
        contentAr: contentArToSave,
      });

      console.log('Save successful, received updated policy:');
      console.log('Updated English content length:', updated.content?.length);
      console.log('Updated Arabic content length:', updated.contentAr?.length || 0);
      console.log('Updated English content preview:', updated.content?.substring(0, 100));

      setPrivacyPolicy(updated);
      setContent(updated.content || contentToSave);
      setContentAr(updated.contentAr || contentArToSave || '');
      setSuccess('Privacy policy updated successfully!');
      
      // Clear success message after 5 seconds
      setTimeout(() => {
        setSuccess(null);
      }, 5000);
    } catch (err: any) {
      console.error('Error saving privacy policy:', err);
      console.error('Error response:', err.response?.data);
      setError(err.response?.data?.message || 'Failed to update privacy policy');
    } finally {
      setSaving(false);
    }
  };

  if (loading) {
    return (
      <div className="space-y-4 page-transition">
        <h1 className="text-3xl font-bold text-slate-900">Privacy Policy Management</h1>
        <div className="card">
          <div className="flex items-center justify-center py-12">
            <div className="text-center">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
              <p className="mt-4 text-slate-600">Loading privacy policy...</p>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6 page-transition">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Privacy Policy Management</h1>
        <p className="mt-2 text-slate-600">
          Update the privacy policy content that appears on the landing page.
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
          {/* English Content */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Privacy Policy Content (English) <span className="text-red-500">*</span>
            </label>
            <p className="text-xs text-slate-500 mb-2">
              You can use HTML tags for formatting. The content will be displayed as-is on the privacy policy page.
            </p>
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={20}
              className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono text-sm"
              placeholder="Enter privacy policy content in English (HTML supported)..."
            />
            <p className="text-xs text-slate-500 mt-1">
              {content.length} characters
            </p>
          </div>

          {/* Arabic Content */}
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-2">
              Privacy Policy Content (Arabic) <span className="text-slate-400">(Optional)</span>
            </label>
            <p className="text-xs text-slate-500 mb-2">
              Arabic version of the privacy policy. If not provided, the English version will be used.
            </p>
            <textarea
              value={contentAr}
              onChange={(e) => setContentAr(e.target.value)}
              rows={20}
              className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono text-sm"
              placeholder="Enter privacy policy content in Arabic (HTML supported)..."
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
          {privacyPolicy?.lastUpdated && (
            <div className="text-sm text-slate-500">
              Last updated: {new Date(privacyPolicy.lastUpdated).toLocaleString()}
            </div>
          )}

          {/* Action Buttons */}
          <div className="flex justify-end gap-4 pt-4 border-t border-slate-200">
            <button
              onClick={loadPrivacyPolicy}
              className="px-4 py-2 border border-slate-300 rounded-lg text-slate-700 hover:bg-slate-50 transition-colors"
              disabled={saving}
            >
              Cancel
            </button>
            <button
              onClick={handleSave}
              disabled={saving || !content.trim()}
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

export default PrivacyPolicy;

