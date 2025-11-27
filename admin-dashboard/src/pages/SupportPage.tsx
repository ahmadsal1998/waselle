import { useState } from 'react';
import { Mail, Phone, Clock, MessageSquare, HelpCircle } from 'lucide-react';

const SupportPage = () => {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    subject: '',
    message: '',
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const { name, email, subject, message } = formData;
    const mailtoLink = `mailto:support@wassle.ps?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(`Name: ${name}\nEmail: ${email}\n\nMessage:\n${message}`)}`;
    window.location.href = mailtoLink;
  };

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value,
    });
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-slate-50 to-white">
      {/* Header */}
      <header className="bg-gradient-to-r from-blue-700 via-blue-800 to-blue-900 shadow-lg">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <h1 className="text-3xl md:text-4xl font-bold text-white mb-2">
            Support
          </h1>
          <p className="text-blue-100 text-lg">
            We're here to help! Get in touch with our support team.
          </p>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Contact Information Section */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-8 border-l-4 border-blue-600">
          <h2 className="text-2xl font-semibold text-slate-900 mb-6 flex items-center gap-2">
            <Mail className="w-6 h-6 text-blue-600" />
            Contact Information
          </h2>
          
          <div className="space-y-4">
            <div className="flex items-start gap-4">
              <Mail className="w-5 h-5 text-blue-600 mt-1 flex-shrink-0" />
              <div>
                <p className="font-semibold text-slate-900">Email</p>
                <a 
                  href="mailto:support@wassle.ps" 
                  className="text-blue-600 hover:text-blue-700 hover:underline"
                >
                  support@wassle.ps
                </a>
              </div>
            </div>

            <div className="flex items-start gap-4">
              <Phone className="w-5 h-5 text-blue-600 mt-1 flex-shrink-0" />
              <div>
                <p className="font-semibold text-slate-900">Phone</p>
                <p className="text-slate-600">+970 593 20 20 26</p>
                <p className="text-sm text-slate-500 mt-1">Please update with your actual phone number</p>
              </div>
            </div>

            <div className="flex items-start gap-4">
              <Clock className="w-5 h-5 text-blue-600 mt-1 flex-shrink-0" />
              <div>
                <p className="font-semibold text-slate-900">Support Hours</p>
                <p className="text-slate-600">Sunday - Thursday: 9:00 AM - 6:00 PM (Palestine Time)</p>
              </div>
            </div>
          </div>
        </div>

        {/* Contact Form */}
        <div className="bg-white rounded-lg shadow-md p-6 mb-8">
          <h2 className="text-2xl font-semibold text-slate-900 mb-6 flex items-center gap-2">
            <MessageSquare className="w-6 h-6 text-blue-600" />
            Send us a Message
          </h2>
          
          <form onSubmit={handleSubmit} className="space-y-6">
            <div>
              <label htmlFor="name" className="block text-sm font-medium text-slate-700 mb-2">
                Your Name *
              </label>
              <input
                type="text"
                id="name"
                name="name"
                required
                value={formData.name}
                onChange={handleChange}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-colors"
                placeholder="Enter your name"
              />
            </div>

            <div>
              <label htmlFor="email" className="block text-sm font-medium text-slate-700 mb-2">
                Your Email *
              </label>
              <input
                type="email"
                id="email"
                name="email"
                required
                value={formData.email}
                onChange={handleChange}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-colors"
                placeholder="your.email@example.com"
              />
            </div>

            <div>
              <label htmlFor="subject" className="block text-sm font-medium text-slate-700 mb-2">
                Subject *
              </label>
              <input
                type="text"
                id="subject"
                name="subject"
                required
                value={formData.subject}
                onChange={handleChange}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-colors"
                placeholder="What is this regarding?"
              />
            </div>

            <div>
              <label htmlFor="message" className="block text-sm font-medium text-slate-700 mb-2">
                Message *
              </label>
              <textarea
                id="message"
                name="message"
                required
                rows={6}
                value={formData.message}
                onChange={handleChange}
                className="w-full px-4 py-2 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-colors resize-vertical"
                placeholder="Please describe your issue or question in detail..."
              />
            </div>

            <button
              type="submit"
              className="w-full bg-blue-600 text-white py-3 px-6 rounded-lg font-semibold hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-colors"
            >
              Send Message
            </button>
          </form>

          <p className="mt-4 text-sm text-slate-500 text-center">
            The form will open your email client. If it doesn't work, please email us directly at{' '}
            <a href="mailto:support@wassle.ps" className="text-blue-600 hover:underline">
              support@wassle.ps
            </a>
          </p>
        </div>

        {/* FAQ Section */}
        <div className="bg-white rounded-lg shadow-md p-6">
          <h2 className="text-2xl font-semibold text-slate-900 mb-6 flex items-center gap-2">
            <HelpCircle className="w-6 h-6 text-blue-600" />
            Frequently Asked Questions
          </h2>
          
          <div className="space-y-6">
            <div className="border-l-4 border-blue-200 pl-4">
              <h3 className="font-semibold text-slate-900 mb-2">
                How do I report a problem with my delivery?
              </h3>
              <p className="text-slate-600">
                If you experience any issues with your delivery, please contact us immediately via email at{' '}
                <a href="mailto:support@wassle.ps" className="text-blue-600 hover:underline">
                  support@wassle.ps
                </a>
                {' '}or use the contact form above. Include your order number and a detailed description of the issue.
              </p>
            </div>

            <div className="border-l-4 border-blue-200 pl-4">
              <h3 className="font-semibold text-slate-900 mb-2">
                How long does it take to get a response?
              </h3>
              <p className="text-slate-600">
                We aim to respond to all support inquiries within 24 hours during business days. For urgent matters, please call us directly.
              </p>
            </div>

            <div className="border-l-4 border-blue-200 pl-4">
              <h3 className="font-semibold text-slate-900 mb-2">
                Can I cancel or modify my order?
              </h3>
              <p className="text-slate-600">
                You can cancel or modify your order through the app before a driver accepts it. Once a driver has accepted your order, please contact support for assistance.
              </p>
            </div>

            <div className="border-l-4 border-blue-200 pl-4">
              <h3 className="font-semibold text-slate-900 mb-2">
                How do I request a refund?
              </h3>
              <p className="text-slate-600">
                For refund requests, please contact our support team with your order details. We'll review your request and process it according to our refund policy.
              </p>
            </div>

            <div className="border-l-4 border-blue-200 pl-4">
              <h3 className="font-semibold text-slate-900 mb-2">
                I'm having trouble with the app. What should I do?
              </h3>
              <p className="text-slate-600">
                If you're experiencing technical issues with the app, please try restarting the app first. If the problem persists, contact us with details about the issue, your device type, and app version.
              </p>
            </div>
          </div>
        </div>

        {/* Additional Info */}
        <div className="mt-8 bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="font-semibold text-blue-900 mb-2">Need Immediate Assistance?</h3>
          <p className="text-blue-800">
            For urgent matters or delivery issues that require immediate attention, please call us directly or send an email with "URGENT" in the subject line.
          </p>
        </div>
      </main>

      {/* Footer */}
      <footer className="bg-slate-900 text-white py-8 mt-16">
        <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
          <p className="mb-4">© 2024 Wassle. All rights reserved.</p>
          <div className="flex justify-center gap-6 text-sm">
            <a
              href="/privacy-policy"
              className="text-blue-300 hover:text-white transition-colors underline"
            >
              Privacy Policy
            </a>
            <a
              href="/terms-of-service"
              className="text-blue-300 hover:text-white transition-colors underline"
            >
              Terms of Service
            </a>
            <a
              href="/"
              className="text-blue-300 hover:text-white transition-colors underline"
            >
              Home
            </a>
          </div>
        </div>
      </footer>
    </div>
  );
};

export default SupportPage;

