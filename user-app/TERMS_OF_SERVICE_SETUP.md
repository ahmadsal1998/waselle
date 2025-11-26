# Terms of Service Implementation Guide

## ✅ Implementation Status

The Terms of Service has been successfully implemented in the app code. The following components have been added:

### 1. ✅ Translations Added
- **English** (`lib/l10n/app_en.arb`): Added Terms of Service translations
- **Arabic** (`lib/l10n/app_ar.arb`): Added Terms of Service translations

### 2. ✅ Screen Component Created
- **File**: `lib/screens/home/terms_of_service_screen.dart`
- **Functionality**: Opens Terms of Service URL in external browser
- **Design**: Matches Privacy Policy screen design

### 3. ✅ Profile Screen Updated
- **File**: `lib/screens/home/profile_screen.dart`
- **Added**: Terms of Service menu item with link
- **Location**: Below Privacy Policy, above Settings

### 4. ✅ HTML Template Created
- **File**: `TERMS_OF_SERVICE_TEMPLATE.html`
- **Purpose**: Template for hosting Terms of Service on website
- **URL**: Should be hosted at `https://www.wassle.ps/terms-of-service`

---

## 📋 Remaining Tasks

### Task 1: Host Terms of Service Webpage ⚠️ CRITICAL

**Action Required**: Host the Terms of Service HTML file on your website

1. **Review the Template**:
   - Open `TERMS_OF_SERVICE_TEMPLATE.html`
   - Review all sections and customize as needed:
     - Replace `[INSERT DATE]` with actual last updated date
     - Replace `[INSERT JURISDICTION]` with your legal jurisdiction
     - Replace `[INSERT EMAIL]` with your support email
     - Replace `[INSERT ADDRESS]` with your business address
     - Replace `[INSERT YEAR]` with current year

2. **Customize Content**:
   - Review all terms and adjust to match your business model
   - Add any specific terms relevant to your service
   - Ensure compliance with local laws and regulations
   - Consider having a lawyer review the terms

3. **Host the File**:
   - Upload the HTML file to your web server
   - Ensure it's accessible at: `https://www.wassle.ps/terms-of-service`
   - Test the URL to ensure it loads correctly
   - Verify it's accessible without login (required by app stores)

4. **Create Arabic Version** (Optional but recommended):
   - Translate the Terms of Service to Arabic
   - Host at: `https://www.wassle.ps/ar/terms-of-service` or similar
   - Update app to detect language and use appropriate URL

---

### Task 2: Add to App Store Connect (iOS) ⚠️ CRITICAL

**Action Required**: Add Terms of Service URL in App Store Connect

1. **Log in to App Store Connect**:
   - Go to https://appstoreconnect.apple.com
   - Navigate to your app listing

2. **Add Terms of Service URL**:
   - Go to **App Information** section
   - Find **Terms of Service URL** field
   - Enter: `https://www.wassle.ps/terms-of-service`
   - Save changes

3. **Verify**:
   - Ensure the URL is accessible
   - Test the link opens correctly
   - Verify it's accessible without login

---

### Task 3: Add to Google Play Console (Android) ⚠️ CRITICAL

**Action Required**: Add Terms of Service URL in Google Play Console

1. **Log in to Google Play Console**:
   - Go to https://play.google.com/console
   - Navigate to your app

2. **Add Terms of Service URL**:
   - Go to **Store listing** section
   - Find **Terms of Service URL** field
   - Enter: `https://www.wassle.ps/terms-of-service`
   - Save changes

3. **Verify**:
   - Ensure the URL is accessible
   - Test the link opens correctly
   - Verify it's accessible without login

---

## 🧪 Testing Checklist

Before submitting to app stores, verify:

- [ ] Terms of Service URL is live and accessible: `https://www.wassle.ps/terms-of-service`
- [ ] Terms of Service link appears in Profile screen
- [ ] Clicking Terms of Service link opens the webpage in browser
- [ ] Terms of Service is accessible without login
- [ ] Terms of Service URL added to App Store Connect (iOS)
- [ ] Terms of Service URL added to Google Play Console (Android)
- [ ] Terms of Service content is complete and accurate
- [ ] Terms of Service has been reviewed by legal counsel (recommended)
- [ ] Terms of Service includes all required sections
- [ ] Terms of Service matches your actual business practices

---

## 📝 Terms of Service Content Checklist

Ensure your Terms of Service includes:

- [ ] Acceptance of Terms
- [ ] Description of Service
- [ ] User Account Requirements
- [ ] User Responsibilities
- [ ] Prohibited Uses
- [ ] Payment Terms
- [ ] Service Availability and Limitations
- [ ] Cancellation Policy
- [ ] Limitation of Liability
- [ ] Indemnification
- [ ] Intellectual Property Rights
- [ ] Privacy Policy Reference
- [ ] Termination Policy
- [ ] Dispute Resolution
- [ ] Governing Law
- [ ] Changes to Terms
- [ ] Contact Information
- [ ] Last Updated Date

---

## 🔗 Related Files

- **App Code**: `lib/screens/home/profile_screen.dart`
- **Screen Component**: `lib/screens/home/terms_of_service_screen.dart`
- **English Translations**: `lib/l10n/app_en.arb`
- **Arabic Translations**: `lib/l10n/app_ar.arb`
- **HTML Template**: `TERMS_OF_SERVICE_TEMPLATE.html`

---

## 📞 Support

If you need help with:
- **Legal Review**: Consult with a lawyer familiar with app store requirements
- **Web Hosting**: Contact your web hosting provider
- **App Store Setup**: Refer to Apple App Store Connect documentation
- **Play Store Setup**: Refer to Google Play Console documentation

---

## ✅ Completion Status

- [x] Code implementation complete
- [ ] Terms of Service webpage hosted
- [ ] App Store Connect URL added
- [ ] Google Play Console URL added
- [ ] Legal review completed
- [ ] Testing completed

---

**Last Updated**: [Current Date]  
**Next Review**: After Terms of Service webpage is hosted

