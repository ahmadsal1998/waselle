import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Landing from '@/pages/Landing';
import PrivacyPolicyPage from '@/pages/PrivacyPolicyPage';
import Login from '@/pages/Login';
import Dashboard from '@/pages/Dashboard';
import Users from '@/pages/Users';
import Drivers from '@/pages/Drivers';
import Orders from '@/pages/Orders';
import OrderDetails from '@/pages/OrderDetails';
import MapView from '@/pages/MapView';
import Settings from '@/pages/Settings';
import Cities from '@/pages/Cities';
import OrderCategories from '@/pages/OrderCategories';
import DriverBalance from '@/pages/DriverBalance';
import PrivacyPolicy from '@/pages/PrivacyPolicy';
import TermsOfService from '@/pages/TermsOfService';
import TermsOfServicePage from '@/pages/TermsOfServicePage';
import Layout from '@/components/layout/Layout';
import { AuthProvider, useAuth } from '@/store/auth';
import { LanguageProvider } from '@/store/language/LanguageContext';

const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { isAuthenticated, isLoading } = useAuth();

  // Show loading state while checking authentication
  if (isLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  // Only redirect if not authenticated after loading completes
  return isAuthenticated ? <>{children}</> : <Navigate to="/login" />;
};

function App() {
  return (
    <LanguageProvider>
      <AuthProvider>
        <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
          <Routes>
            <Route path="/" element={<Landing />} />
            <Route path="/privacy-policy" element={<PrivacyPolicyPage />} />
            <Route path="/terms-of-service" element={<TermsOfServicePage />} />
            <Route path="/login" element={<Login />} />
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute>
                  <Layout />
                </ProtectedRoute>
              }
            >
              <Route index element={<Dashboard />} />
              <Route path="users" element={<Users />} />
              <Route path="drivers" element={<Drivers />} />
              <Route path="orders" element={<Orders />} />
              <Route path="orders/:orderId" element={<OrderDetails />} />
              <Route path="map" element={<MapView />} />
              <Route path="settings" element={<Settings />} />
              <Route path="cities" element={<Cities />} />
              <Route path="order-categories" element={<OrderCategories />} />
              <Route path="driver-balance" element={<DriverBalance />} />
              <Route path="privacy-policy" element={<PrivacyPolicy />} />
              <Route path="terms-of-service" element={<TermsOfService />} />
            </Route>
          </Routes>
        </Router>
      </AuthProvider>
    </LanguageProvider>
  );
}

export default App;
