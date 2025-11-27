import { HelpCircle, Mail, MessageCircle, Book, FileText, ExternalLink } from 'lucide-react';

const Support = () => {
  return (
    <div className="space-y-6 page-transition">
      <div>
        <h1 className="text-3xl font-bold text-slate-900">Support</h1>
        <p className="mt-2 text-slate-600">Get help and find resources for using the admin dashboard</p>
      </div>

      {/* Quick Help Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-12 h-12 rounded-lg bg-blue-100 flex items-center justify-center">
              <Book className="w-6 h-6 text-blue-600" />
            </div>
            <h2 className="text-xl font-semibold text-slate-900">Documentation</h2>
          </div>
          <p className="text-slate-600 mb-4">
            Browse our comprehensive documentation to learn how to use all features of the admin dashboard.
          </p>
          <button className="text-blue-600 hover:text-blue-700 font-medium flex items-center gap-2">
            View Docs
            <ExternalLink className="w-4 h-4" />
          </button>
        </div>

        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-12 h-12 rounded-lg bg-green-100 flex items-center justify-center">
              <MessageCircle className="w-6 h-6 text-green-600" />
            </div>
            <h2 className="text-xl font-semibold text-slate-900">Live Chat</h2>
          </div>
          <p className="text-slate-600 mb-4">
            Chat with our support team in real-time for immediate assistance with any questions or issues.
          </p>
          <button className="text-green-600 hover:text-green-700 font-medium flex items-center gap-2">
            Start Chat
            <ExternalLink className="w-4 h-4" />
          </button>
        </div>

        <div className="card p-6 hover:shadow-lg transition-shadow">
          <div className="flex items-center gap-4 mb-4">
            <div className="w-12 h-12 rounded-lg bg-purple-100 flex items-center justify-center">
              <Mail className="w-6 h-6 text-purple-600" />
            </div>
            <h2 className="text-xl font-semibold text-slate-900">Email Support</h2>
          </div>
          <p className="text-slate-600 mb-4">
            Send us an email and we'll get back to you within 24 hours with a detailed response.
          </p>
          <a
            href="mailto:support@example.com"
            className="text-purple-600 hover:text-purple-700 font-medium flex items-center gap-2"
          >
            support@example.com
            <ExternalLink className="w-4 h-4" />
          </a>
        </div>
      </div>

      {/* Common Questions */}
      <div className="card p-6">
        <div className="flex items-center gap-3 mb-6">
          <HelpCircle className="w-6 h-6 text-slate-600" />
          <h2 className="text-2xl font-semibold text-slate-900">Frequently Asked Questions</h2>
        </div>
        <div className="space-y-4">
          <div className="border-l-4 border-blue-500 pl-4 py-2">
            <h3 className="font-semibold text-slate-900 mb-1">How do I manage driver balances?</h3>
            <p className="text-slate-600 text-sm">
              Navigate to the Driver Balance page from the sidebar to view and manage driver account balances.
            </p>
          </div>
          <div className="border-l-4 border-blue-500 pl-4 py-2">
            <h3 className="font-semibold text-slate-900 mb-1">How do I configure order settings?</h3>
            <p className="text-slate-600 text-sm">
              Go to Settings to configure order radius, vehicle types, commission percentages, and other system-wide settings.
            </p>
          </div>
          <div className="border-l-4 border-blue-500 pl-4 py-2">
            <h3 className="font-semibold text-slate-900 mb-1">How do I view order details?</h3>
            <p className="text-slate-600 text-sm">
              Click on any order from the Orders page to view detailed information including tracking, driver assignment, and customer details.
            </p>
          </div>
          <div className="border-l-4 border-blue-500 pl-4 py-2">
            <h3 className="font-semibold text-slate-900 mb-1">How do I manage cities and villages?</h3>
            <p className="text-slate-600 text-sm">
              Use the Cities & Villages page to add, edit, or remove locations that are available for delivery services.
            </p>
          </div>
        </div>
      </div>

      {/* System Information */}
      <div className="card p-6">
        <h2 className="text-xl font-semibold mb-4 text-slate-900">System Information</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Dashboard Version</label>
            <p className="text-slate-600">v1.0.0</p>
          </div>
          <div>
            <label className="block text-sm font-medium text-slate-700 mb-1">Last Updated</label>
            <p className="text-slate-600">{new Date().toLocaleDateString()}</p>
          </div>
        </div>
      </div>

      {/* Contact Information */}
      <div className="card p-6">
        <h2 className="text-xl font-semibold mb-4 text-slate-900">Contact Information</h2>
        <div className="space-y-3">
          <div className="flex items-center gap-3">
            <Mail className="w-5 h-5 text-slate-500" />
            <div>
              <p className="text-sm font-medium text-slate-700">Email</p>
              <a href="mailto:support@example.com" className="text-blue-600 hover:text-blue-700">
                support@example.com
              </a>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <FileText className="w-5 h-5 text-slate-500" />
            <div>
              <p className="text-sm font-medium text-slate-700">Support Hours</p>
              <p className="text-slate-600">Monday - Friday, 9:00 AM - 5:00 PM</p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Support;

