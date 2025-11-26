import { Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Truck,
  Package,
  MapPin,
  FolderTree,
  Map,
  Settings,
  Menu,
  X,
  DollarSign,
  Shield,
} from 'lucide-react';
import { useState, useEffect } from 'react';

interface NavItem {
  path: string;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
}

const navItems: NavItem[] = [
  { path: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { path: '/dashboard/users', label: 'Users', icon: Users },
  { path: '/dashboard/drivers', label: 'Drivers', icon: Truck },
  { path: '/dashboard/driver-balance', label: 'Driver Balance', icon: DollarSign },
  { path: '/dashboard/orders', label: 'Orders', icon: Package },
  { path: '/dashboard/cities', label: 'Cities & Villages', icon: MapPin },
  { path: '/dashboard/order-categories', label: 'Order Categories', icon: FolderTree },
  { path: '/dashboard/map', label: 'Map View', icon: Map },
  { path: '/dashboard/privacy-policy', label: 'Privacy Policy', icon: Shield },
  { path: '/dashboard/settings', label: 'Settings', icon: Settings },
];

interface SidebarProps {
  isOpen: boolean;
  onToggle: () => void;
  isMobile: boolean;
  isCollapsed?: boolean;
  onCollapseChange?: (collapsed: boolean) => void;
}

const Sidebar = ({ isOpen, onToggle, isMobile, isCollapsed: externalCollapsed, onCollapseChange }: SidebarProps) => {
  const location = useLocation();
  const [internalCollapsed, setInternalCollapsed] = useState(false);
  
  // Use external collapsed state if provided, otherwise use internal
  const isCollapsed = externalCollapsed !== undefined ? externalCollapsed : internalCollapsed;
  const setIsCollapsed = (value: boolean) => {
    if (onCollapseChange) {
      onCollapseChange(value);
    } else {
      setInternalCollapsed(value);
    }
  };

  // Handle window resize
  useEffect(() => {
    if (!isMobile) {
      // Desktop: start collapsed on smaller screens
      const shouldCollapse = window.innerWidth < 1280;
      setIsCollapsed(shouldCollapse);
    } else {
      setIsCollapsed(false);
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isMobile]);

  const isActive = (path: string) => {
    if (path === '/dashboard') {
      return location.pathname === '/dashboard';
    }
    return location.pathname.startsWith(path);
  };

  return (
    <>
      {/* Mobile Overlay */}
      {isMobile && isOpen && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden transition-opacity duration-300"
          onClick={onToggle}
        />
      )}

      {/* Sidebar */}
      <aside
        className={`
          fixed top-0 left-0 h-full bg-gradient-to-b from-slate-900 to-slate-800 text-white z-50
          transition-all duration-300 ease-in-out
          ${isMobile ? (isOpen ? 'translate-x-0' : '-translate-x-full') : 'translate-x-0'}
          ${isCollapsed && !isMobile ? 'w-20' : 'w-64'}
          shadow-2xl
        `}
        style={{ width: isMobile ? (isOpen ? '256px' : '0') : (isCollapsed ? '80px' : '256px') }}
      >
        {/* Sidebar Header */}
        <div className="flex items-center justify-between h-16 px-4 border-b border-slate-700/50">
          {(!isCollapsed || isMobile) && (
            <h1 className="text-xl font-bold text-white">Delivery System</h1>
          )}
          <div className="flex items-center gap-2">
            {!isMobile && (
              <button
                onClick={() => setIsCollapsed(!isCollapsed)}
                className="p-2 rounded-lg hover:bg-slate-700/50 transition-colors"
                aria-label="Toggle sidebar"
              >
                <Menu className="w-5 h-5" />
              </button>
            )}
            {isMobile && (
              <button
                onClick={onToggle}
                className="p-2 rounded-lg hover:bg-slate-700/50 transition-colors"
                aria-label="Close sidebar"
              >
                <X className="w-5 h-5" />
              </button>
            )}
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 overflow-y-auto py-4 px-2 custom-scrollbar">
          <ul className="space-y-1">
            {navItems.map((item) => {
              const Icon = item.icon;
              const active = isActive(item.path);
              return (
                <li key={item.path}>
                  <Link
                    to={item.path}
                    onClick={() => {
                      if (isMobile) {
                        onToggle();
                      }
                    }}
                    className={`
                      flex items-center gap-3 px-4 py-3 rounded-lg
                      transition-all duration-200 ease-in-out
                      ${
                        active
                          ? 'bg-blue-600 text-white shadow-lg shadow-blue-600/30'
                          : 'text-slate-300 hover:bg-slate-700/50 hover:text-white'
                      }
                      group
                    `}
                    title={isCollapsed && !isMobile ? item.label : undefined}
                  >
                    <Icon
                      className={`
                        w-5 h-5 flex-shrink-0
                        ${active ? 'text-white' : 'text-slate-400 group-hover:text-white'}
                        transition-colors
                      `}
                    />
                    {(!isCollapsed || isMobile) && (
                      <span className="font-medium">{item.label}</span>
                    )}
                    {isCollapsed && !isMobile && active && (
                      <div className="absolute left-0 top-1/2 -translate-y-1/2 w-1 h-8 bg-blue-400 rounded-r-full" />
                    )}
                  </Link>
                </li>
              );
            })}
          </ul>
        </nav>

        {/* Sidebar Footer */}
        <div className="border-t border-slate-700/50 p-4">
          {(!isCollapsed || isMobile) && (
            <div className="text-xs text-slate-400 text-center">
              <p>Admin Dashboard</p>
              <p className="mt-1">v1.0.0</p>
            </div>
          )}
        </div>
      </aside>
    </>
  );
};

export default Sidebar;

