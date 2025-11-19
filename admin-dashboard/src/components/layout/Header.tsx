import { useAuth } from '@/store/auth';
import { Menu, Bell, LogOut, User } from 'lucide-react';
import { useState } from 'react';
import { useLocation } from 'react-router-dom';

interface HeaderProps {
  onMenuClick: () => void;
}

const getBreadcrumbs = (pathname: string): string[] => {
  const pathMap: Record<string, string> = {
    '/': 'Dashboard',
    '/users': 'Users',
    '/drivers': 'Drivers',
    '/orders': 'Orders',
    '/cities': 'Cities & Villages',
    '/order-categories': 'Order Categories',
    '/map': 'Map View',
    '/settings': 'Settings',
  };

  const paths = pathname.split('/').filter(Boolean);
  const breadcrumbs = ['Admin'];

  if (pathname === '/') {
    breadcrumbs.push('Dashboard');
  } else {
    paths.forEach((path, index) => {
      const fullPath = '/' + paths.slice(0, index + 1).join('/');
      const label = pathMap[fullPath] || path.charAt(0).toUpperCase() + path.slice(1);
      breadcrumbs.push(label);
    });
  }

  return breadcrumbs;
};

const Header = ({ onMenuClick }: HeaderProps) => {
  const { user, logout } = useAuth();
  const [showUserMenu, setShowUserMenu] = useState(false);
  const location = useLocation();
  const breadcrumbs = getBreadcrumbs(location.pathname);

  return (
    <header className="sticky top-0 z-30 bg-white/80 backdrop-blur-sm border-b border-slate-200 shadow-sm">
      <div className="flex items-center justify-between h-16 px-4 lg:px-6">
        {/* Left: Menu Button & Breadcrumbs */}
        <div className="flex items-center gap-4">
          <button
            onClick={onMenuClick}
            className="p-2 rounded-lg hover:bg-slate-100 transition-colors lg:hidden"
            aria-label="Toggle menu"
          >
            <Menu className="w-6 h-6 text-slate-700" />
          </button>
          <div className="hidden md:flex items-center gap-2 text-sm text-slate-600">
            {breadcrumbs.map((crumb, index) => (
              <div key={index} className="flex items-center gap-2">
                {index > 0 && <span className="text-slate-400">/</span>}
                <span
                  className={
                    index === breadcrumbs.length - 1
                      ? 'text-slate-900 font-medium'
                      : 'text-slate-500'
                  }
                >
                  {crumb}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Right: Notifications & User Menu */}
        <div className="flex items-center gap-4">
          {/* Notifications */}
          <button
            className="relative p-2 rounded-lg hover:bg-slate-100 transition-colors"
            aria-label="Notifications"
          >
            <Bell className="w-5 h-5 text-slate-700" />
            <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full"></span>
          </button>

          {/* User Menu */}
          <div className="relative">
            <button
              onClick={() => setShowUserMenu(!showUserMenu)}
              className="flex items-center gap-3 px-3 py-2 rounded-lg hover:bg-slate-100 transition-colors"
            >
              <div className="w-8 h-8 rounded-full bg-gradient-to-br from-blue-500 to-blue-600 flex items-center justify-center">
                <User className="w-4 h-4 text-white" />
              </div>
              <div className="hidden md:block text-left">
                <p className="text-sm font-medium text-slate-900">{user?.name || 'Admin'}</p>
                <p className="text-xs text-slate-500">Administrator</p>
              </div>
            </button>

            {/* Dropdown Menu */}
            {showUserMenu && (
              <>
                <div
                  className="fixed inset-0 z-40"
                  onClick={() => setShowUserMenu(false)}
                />
                <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-slate-200 py-2 z-50">
                  <div className="px-4 py-2 border-b border-slate-100">
                    <p className="text-sm font-medium text-slate-900">{user?.name || 'Admin'}</p>
                    <p className="text-xs text-slate-500">{user?.email || 'admin@example.com'}</p>
                  </div>
                  <button
                    onClick={() => {
                      logout();
                      setShowUserMenu(false);
                    }}
                    className="w-full flex items-center gap-2 px-4 py-2 text-sm text-red-600 hover:bg-red-50 transition-colors"
                  >
                    <LogOut className="w-4 h-4" />
                    Logout
                  </button>
                </div>
              </>
            )}
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;

