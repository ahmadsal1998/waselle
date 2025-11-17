import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
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
import Layout from '@/components/layout/Layout';
import { AuthProvider, useAuth } from '@/store/auth';

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
    <AuthProvider>
      <Router future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/"
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
          </Route>
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;
