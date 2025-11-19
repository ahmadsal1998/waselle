import { Outlet } from 'react-router-dom';
import { useState, useEffect } from 'react';
import Sidebar from './Sidebar';
import Header from './Header';

const Layout = () => {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isMobile, setIsMobile] = useState(false);
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);

  useEffect(() => {
    const checkMobile = () => {
      const mobile = window.innerWidth < 1024;
      setIsMobile(mobile);
      if (!mobile) {
        setSidebarOpen(false); // Close sidebar on desktop resize
        // Auto-collapse on smaller desktop screens
        setSidebarCollapsed(window.innerWidth < 1280);
      }
    };

    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  const toggleSidebar = () => {
    setSidebarOpen(!sidebarOpen);
  };

  // Calculate sidebar width based on collapsed state
  const sidebarWidth = isMobile ? 0 : (sidebarCollapsed ? 80 : 256); // 80px collapsed, 256px (64*4) expanded

  return (
    <div className="min-h-screen bg-slate-50 flex">
      {/* Sidebar */}
      <Sidebar 
        isOpen={sidebarOpen} 
        onToggle={toggleSidebar} 
        isMobile={isMobile}
        isCollapsed={sidebarCollapsed}
        onCollapseChange={setSidebarCollapsed}
      />

      {/* Main Content Area */}
      <div 
        className="flex-1 flex flex-col transition-all duration-300 min-w-0"
        style={{ marginLeft: isMobile ? 0 : `${sidebarWidth}px` }}
      >
        {/* Header */}
        <Header onMenuClick={toggleSidebar} />

        {/* Main Content */}
        <main className="flex-1 overflow-y-auto p-4 md:p-6 lg:p-8 custom-scrollbar">
          <div className="max-w-7xl mx-auto">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
};

export default Layout;
