import { useAuth } from '@/lib/hooks/useAuth';
import { StatsCard } from '@/components/common/StatsCard';
import { StatusBadge } from '@/components/common/StatusBadge';
import { Link } from 'react-router-dom';
import {
  Users,
  Calendar,
  UserCheck,
  TrendingUp,
  Clock,
  CheckCircle2,
  XCircle,
} from 'lucide-react';

export function Dashboard() {
  const { user } = useAuth();

  // Mock data - replace with real API calls
  const stats = [
    {
      title: 'Total Users',
      value: '2,543',
      icon: Users,
      trend: { value: 12.5, isPositive: true },
      iconColor: 'text-blue-600',
      iconBgColor: 'bg-blue-100',
    },
    {
      title: 'Total Events',
      value: '156',
      icon: Calendar,
      trend: { value: 8.2, isPositive: true },
      iconColor: 'text-purple-600',
      iconBgColor: 'bg-purple-100',
    },
    {
      title: 'Organizers',
      value: '89',
      icon: UserCheck,
      trend: { value: 3.1, isPositive: false },
      iconColor: 'text-green-600',
      iconBgColor: 'bg-green-100',
    },
    {
      title: 'Revenue',
      value: '$45,231',
      icon: TrendingUp,
      trend: { value: 15.3, isPositive: true },
      iconColor: 'text-yellow-600',
      iconBgColor: 'bg-yellow-100',
    },
  ];

  const recentRequests = [
    {
      id: 1,
      name: 'John Doe',
      organization: 'Tech Events Co.',
      status: 'pending' as const,
      date: '2 hours ago',
    },
    {
      id: 2,
      name: 'Jane Smith',
      organization: 'Music Festival Group',
      status: 'approved' as const,
      date: '5 hours ago',
    },
    {
      id: 3,
      name: 'Mike Johnson',
      organization: 'Sports Events Ltd',
      status: 'rejected' as const,
      date: '1 day ago',
    },
  ];

  const recentEvents = [
    { id: 1, name: 'Tech Conference 2025', organizer: 'John Doe', date: '2025-01-15', status: 'published' as const },
    { id: 2, name: 'Music Festival', organizer: 'Jane Smith', date: '2025-02-20', status: 'published' as const },
    { id: 3, name: 'Sports Tournament', organizer: 'Mike Johnson', date: '2025-03-10', status: 'draft' as const },
  ];

  return (
    <div className="space-y-6">
      {/* Welcome Section */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-xl shadow-lg p-8 text-white">
        <h1 className="text-3xl font-bold mb-2">
          Welcome back, {user?.name}! 👋
        </h1>
        <p className="text-blue-100">
          Here's what's happening with your platform today.
        </p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <StatsCard key={index} {...stat} />
        ))}
      </div>

      {/* Two Column Layout */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Recent Organizer Requests */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-gray-900">
              Recent Organizer Requests
            </h2>
            <Link
              to="/organizers"
              className="text-sm text-blue-600 hover:text-blue-700 font-medium"
            >
              View all →
            </Link>
          </div>

          <div className="space-y-4">
            {recentRequests.map((request) => (
              <div
                key={request.id}
                className="flex items-center justify-between p-4 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="flex-1">
                  <p className="font-medium text-gray-900">{request.name}</p>
                  <p className="text-sm text-gray-500">{request.organization}</p>
                </div>
                <div className="flex items-center space-x-4">
                  <StatusBadge status={request.status} />
                  <span className="text-xs text-gray-400 whitespace-nowrap">
                    {request.date}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recent Events */}
        <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
          <div className="flex items-center justify-between mb-6">
            <h2 className="text-lg font-semibold text-gray-900">
              Recent Events
            </h2>
            <Link
              to="/events"
              className="text-sm text-blue-600 hover:text-blue-700 font-medium"
            >
              View all →
            </Link>
          </div>

          <div className="space-y-4">
            {recentEvents.map((event) => (
              <div
                key={event.id}
                className="flex items-center justify-between p-4 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="flex-1">
                  <p className="font-medium text-gray-900">{event.name}</p>
                  <p className="text-sm text-gray-500">
                    by {event.organizer} • {new Date(event.date).toLocaleDateString()}
                  </p>
                </div>
                <StatusBadge status={event.status} />
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <h2 className="text-lg font-semibold text-gray-900 mb-4">Quick Actions</h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <Link
            to="/organizers"
            className="flex items-center p-4 rounded-lg border-2 border-gray-200 hover:border-blue-500 hover:shadow-md transition-all duration-200 group"
          >
            <div className="p-3 rounded-lg bg-blue-100 group-hover:bg-blue-600 transition-colors">
              <Clock className="w-6 h-6 text-blue-600 group-hover:text-white" />
            </div>
            <div className="ml-4">
              <p className="font-medium text-gray-900">Pending Requests</p>
              <p className="text-sm text-gray-500">Review applications</p>
            </div>
          </Link>

          <Link
            to="/events"
            className="flex items-center p-4 rounded-lg border-2 border-gray-200 hover:border-purple-500 hover:shadow-md transition-all duration-200 group"
          >
            <div className="p-3 rounded-lg bg-purple-100 group-hover:bg-purple-600 transition-colors">
              <Calendar className="w-6 h-6 text-purple-600 group-hover:text-white" />
            </div>
            <div className="ml-4">
              <p className="font-medium text-gray-900">Manage Events</p>
              <p className="text-sm text-gray-500">View all events</p>
            </div>
          </Link>

          <Link
            to="/users"
            className="flex items-center p-4 rounded-lg border-2 border-gray-200 hover:border-green-500 hover:shadow-md transition-all duration-200 group"
          >
            <div className="p-3 rounded-lg bg-green-100 group-hover:bg-green-600 transition-colors">
              <Users className="w-6 h-6 text-green-600 group-hover:text-white" />
            </div>
            <div className="ml-4">
              <p className="font-medium text-gray-900">User Management</p>
              <p className="text-sm text-gray-500">Manage all users</p>
            </div>
          </Link>
        </div>
      </div>
    </div>
  );
}
