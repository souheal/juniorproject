import { Link, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  UserCheck,
  Calendar,
  Settings,
  ChevronLeft,
  ChevronRight
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useState } from 'react';

interface SidebarProps {
  collapsed?: boolean;
  onCollapse?: (collapsed: boolean) => void;
}

const navigation = [
  { name: 'Dashboard', href: '/dashboard', icon: LayoutDashboard },
  { name: 'Users', href: '/users', icon: Users },
  { name: 'Organizers', href: '/organizers', icon: UserCheck },
  { name: 'Events', href: '/events', icon: Calendar },
  { name: 'Settings', href: '/settings', icon: Settings },
];

export function Sidebar({ collapsed: controlledCollapsed, onCollapse }: SidebarProps) {
  const location = useLocation();
  const [internalCollapsed, setInternalCollapsed] = useState(false);

  const collapsed = controlledCollapsed ?? internalCollapsed;
  const setCollapsed = onCollapse ?? setInternalCollapsed;

  return (
    <div
      className={cn(
        'flex flex-col bg-gray-900 text-white transition-all duration-300 ease-in-out',
        collapsed ? 'w-16' : 'w-64'
      )}
    >
      {/* Logo */}
      <div className="flex items-center justify-between h-16 px-4 border-b border-gray-800">
        {!collapsed && (
          <div className="flex items-center space-x-2 animate-fade-in">
            <div className="w-8 h-8 bg-gradient-to-br from-blue-500 to-purple-600 rounded-lg flex items-center justify-center font-bold text-sm">
              E
            </div>
            <span className="text-xl font-bold bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
              Eventy
            </span>
          </div>
        )}
        <button
          onClick={() => setCollapsed(!collapsed)}
          className="p-1.5 rounded-lg hover:bg-gray-800 transition-colors ml-auto"
          aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
        >
          {collapsed ? (
            <ChevronRight className="w-5 h-5" />
          ) : (
            <ChevronLeft className="w-5 h-5" />
          )}
        </button>
      </div>

      {/* Navigation */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {navigation.map((item) => {
          const isActive = location.pathname === item.href ||
                          location.pathname.startsWith(item.href + '/');

          return (
            <Link
              key={item.name}
              to={item.href}
              className={cn(
                'flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200',
                'hover:bg-gray-800 hover:scale-105',
                isActive
                  ? 'bg-gradient-to-r from-blue-600 to-purple-600 text-white shadow-lg shadow-blue-500/50'
                  : 'text-gray-300 hover:text-white'
              )}
              title={collapsed ? item.name : undefined}
            >
              <item.icon className={cn('w-5 h-5 flex-shrink-0', collapsed ? '' : 'mr-3')} />
              {!collapsed && (
                <span className="animate-fade-in">{item.name}</span>
              )}
              {isActive && !collapsed && (
                <div className="ml-auto w-1.5 h-1.5 bg-white rounded-full animate-pulse" />
              )}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="p-4 border-t border-gray-800">
        {!collapsed ? (
          <div className="flex items-center space-x-3 animate-fade-in">
            <div className="flex-1">
              <p className="text-xs text-gray-400">Admin Dashboard</p>
              <p className="text-xs text-gray-500">v1.0.0</p>
            </div>
          </div>
        ) : (
          <div className="w-2 h-2 bg-green-500 rounded-full mx-auto animate-pulse" />
        )}
      </div>

      <style>{`
        @keyframes fade-in {
          from {
            opacity: 0;
            transform: translateX(-10px);
          }
          to {
            opacity: 1;
            transform: translateX(0);
          }
        }
        .animate-fade-in {
          animation: fade-in 0.3s ease-out;
        }
      `}</style>
    </div>
  );
}
