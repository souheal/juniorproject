import { useAuth } from '@/lib/hooks/useAuth';
import { StatsCard } from '@/components/common/StatsCard';
import { StatusBadge } from '@/components/common/StatusBadge';
import { Link } from 'react-router-dom';
import { useState, useEffect } from 'react';
import { dashboardAPI, type DashboardResponse } from '@/lib/api/dashboard';
import {
  Users,
  Calendar,
  UserCheck,
  TrendingUp,
  Clock,
  AlertCircle,
} from 'lucide-react';

export function Dashboard() {
  const { user } = useAuth();
  const [data, setData] = useState<DashboardResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    fetchDashboard();
  }, []);

  const fetchDashboard = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await dashboardAPI.getDashboard();
      setData(response);
    } catch (err: any) {
      console.error('Failed to fetch dashboard:', err);
      setError(err.message || 'Failed to load dashboard data');
    } finally {
      setIsLoading(false);
    }
  };

  // Stats cards from API data
  const stats = data ? [
    {
      title: 'Total Users',
      value: data.stats.total_users.toLocaleString(),
      icon: Users,
      iconColor: 'text-blue-600',
      iconBgColor: 'bg-blue-100',
    },
    {
      title: 'Total Events',
      value: data.stats.total_events.toLocaleString(),
      icon: Calendar,
      iconColor: 'text-purple-600',
      iconBgColor: 'bg-purple-100',
    },
    {
      title: 'Organizers',
      value: data.stats.total_organizers.toLocaleString(),
      icon: UserCheck,
      iconColor: 'text-green-600',
      iconBgColor: 'bg-green-100',
    },
    {
      title: 'Revenue',
      value: `$${(data.stats.total_revenue || 0).toLocaleString()}`,
      icon: TrendingUp,
      iconColor: 'text-yellow-600',
      iconBgColor: 'bg-yellow-100',
    },
  ] : [];

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Welcome Section */}
      <div className="bg-gradient-to-r from-blue-600 to-purple-600 rounded-xl shadow-lg p-8 text-white">
        <h1 className="text-3xl font-bold mb-2">
          Welcome back, {user?.name}!
        </h1>
        <p className="text-blue-100">
          Here's what's happening with your platform today.
        </p>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm text-red-800">{error}</p>
            <button
              onClick={fetchDashboard}
              className="text-sm text-red-600 hover:text-red-800 font-medium mt-1"
            >
              Try again
            </button>
          </div>
        </div>
      )}

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <StatsCard key={index} {...stat} />
        ))}
      </div>

      {/* Pending Requests Alert */}
      {data && data.stats.pending_requests > 0 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Clock className="w-5 h-5 text-yellow-600" />
            <p className="text-sm text-yellow-800">
              You have <span className="font-bold">{data.stats.pending_requests}</span> pending organizer requests
            </p>
          </div>
          <Link
            to="/organizers"
            className="text-sm bg-yellow-600 text-white px-4 py-2 rounded-lg hover:bg-yellow-700 transition-colors"
          >
            Review Now
          </Link>
        </div>
      )}

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
              View all
            </Link>
          </div>

          <div className="space-y-4">
            {data?.recent_requests && data.recent_requests.length > 0 ? (
              data.recent_requests.map((request) => (
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
              ))
            ) : (
              <div className="text-center py-8 text-gray-500">
                <UserCheck className="w-12 h-12 mx-auto text-gray-300 mb-3" />
                <p>No recent requests</p>
              </div>
            )}
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
              View all
            </Link>
          </div>

          <div className="space-y-4">
            {data?.recent_events && data.recent_events.length > 0 ? (
              data.recent_events.map((event) => (
                <div
                  key={event.id}
                  className="flex items-center justify-between p-4 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  <div className="flex-1">
                    <p className="font-medium text-gray-900">{event.name}</p>
                    <p className="text-sm text-gray-500">
                      by {event.organizer} - {new Date(event.date).toLocaleDateString()}
                    </p>
                  </div>
                  <StatusBadge status={event.status} />
                </div>
              ))
            ) : (
              <div className="text-center py-8 text-gray-500">
                <Calendar className="w-12 h-12 mx-auto text-gray-300 mb-3" />
                <p>No recent events</p>
              </div>
            )}
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
