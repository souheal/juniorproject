import {
  Users as UsersIcon,
  Search,
  MoreVertical,
  Eye,
  UserCog,
  AlertCircle,
  Info,
  Bell,
  BellOff,
} from 'lucide-react';
import { StatsCard } from '@/components/common/StatsCard';
import { useState, useEffect, useRef } from 'react';
import type { UserListItem } from '@/lib/api/users';
import { usersAPI } from '@/lib/api/users';

export function Users() {
  const [users, setUsers] = useState<UserListItem[]>([]);
  const [totalUsers, setTotalUsers] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'user' | 'organizer'>('all');
  const [openMenuId, setOpenMenuId] = useState<number | null>(null);
  const menuRef = useRef<HTMLDivElement>(null);

  // Close menu when clicking outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setOpenMenuId(null);
      }
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  // Fetch users from API
  useEffect(() => {
    fetchUsers();
  }, []);

  const fetchUsers = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await usersAPI.getUsers();
      setUsers(response.users);
      setTotalUsers(response.stats.total);
    } catch (err: any) {
      console.error('Failed to fetch users:', err);
      // Use mock data as fallback during development
      setUsers(mockUsers);
      setTotalUsers(mockUsers.length);
      setError(err.message || 'Failed to load users. Showing sample data.');
    } finally {
      setIsLoading(false);
    }
  };

  // Filter users based on search and role filter
  const filteredUsers = users.filter((user) => {
    const matchesSearch =
      !searchQuery ||
      user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
      user.phone?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      user.location?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesRole =
      roleFilter === 'all' || user.role?.name === roleFilter;

    return matchesSearch && matchesRole;
  });

  // Count users and organizers
  const usersCount = users.filter((u) => u.role?.name === 'user').length;
  const organizersCount = users.filter((u) => u.role?.name === 'organizer').length;

  // Action handlers
  const handleViewProfile = (user: UserListItem) => {
    // TODO: Implement view profile modal or navigation
    console.log('View profile:', user);
    setOpenMenuId(null);
  };

  // Format date helper
  const formatDate = (dateString: string | null) => {
    if (!dateString) return '-';
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  };

  // Format datetime helper
  const formatDateTime = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  };

  // Stats cards data
  const statsCards = [
    {
      title: 'Total Users',
      value: totalUsers.toLocaleString(),
      icon: UsersIcon,
      iconColor: 'text-blue-600',
      iconBgColor: 'bg-blue-100',
    },
    {
      title: 'Regular Users',
      value: usersCount.toLocaleString(),
      icon: UsersIcon,
      iconColor: 'text-green-600',
      iconBgColor: 'bg-green-100',
    },
    {
      title: 'Organizers',
      value: organizersCount.toLocaleString(),
      icon: UserCog,
      iconColor: 'text-purple-600',
      iconBgColor: 'bg-purple-100',
    },
  ];

  // Role badge component
  const RoleBadge = ({ isOrganizer }: { isOrganizer: boolean }) => {
    const baseClasses = 'inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium';

    if (isOrganizer) {
      return (
        <div className="relative group">
          <span className={`${baseClasses} bg-purple-100 text-purple-800`}>
            <UserCog className="w-3 h-3 mr-1" />
            Organizer
          </span>
          {/* Tooltip */}
          <div className="absolute bottom-full left-1/2 transform -translate-x-1/2 mb-2 px-3 py-2 bg-gray-900 text-white text-xs rounded-lg opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap pointer-events-none z-10">
            <div className="flex items-center gap-1">
              <Info className="w-3 h-3" />
              <span>Organizer management is handled in the Organizers section</span>
            </div>
            <div className="absolute top-full left-1/2 transform -translate-x-1/2 -mt-1">
              <div className="border-4 border-transparent border-t-gray-900" />
            </div>
          </div>
        </div>
      );
    }

    return (
      <span className={`${baseClasses} bg-blue-100 text-blue-800`}>
        User
      </span>
    );
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Users Management</h1>
        <p className="text-gray-500 mt-1">
          View and manage all platform users. Organizer approvals are handled in the Organizers section.
        </p>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-yellow-600 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm text-yellow-800">{error}</p>
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {statsCards.map((stat, index) => (
          <StatsCard key={index} {...stat} />
        ))}
      </div>

      {/* Users Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        {/* Filters Header */}
        <div className="p-6 border-b border-gray-200">
          <div className="flex flex-col sm:flex-row sm:items-center gap-4">
            <h2 className="text-lg font-semibold text-gray-900">All Users</h2>

            <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 sm:ml-auto">
              {/* Search */}
              <div className="relative">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search by name, email, phone..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full sm:w-72 pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                />
              </div>

              {/* Role Filter */}
              <select
                value={roleFilter}
                onChange={(e) => setRoleFilter(e.target.value as any)}
                className="px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm bg-white"
              >
                <option value="all">All Roles</option>
                <option value="user">Users Only</option>
                <option value="organizer">Organizers Only</option>
              </select>
            </div>
          </div>
        </div>

        {/* Table */}
        <div className="overflow-x-auto">
          {isLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600" />
            </div>
          ) : filteredUsers.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-gray-500">
              <UsersIcon className="w-12 h-12 mb-3 text-gray-300" />
              <p className="text-lg font-medium">No users found</p>
              <p className="text-sm">Try adjusting your search or filters</p>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Picture
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Name
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Email
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Phone
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Location
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Birth Date
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Notifications
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Role
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Created At
                  </th>
                  <th className="px-4 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Updated At
                  </th>
                  <th className="px-4 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
                    Actions
                  </th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {filteredUsers.map((user) => (
                  <tr key={user.id} className="hover:bg-gray-50 transition-colors">
                    {/* Picture */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold flex-shrink-0 overflow-hidden">
                        {user.picture ? (
                          <img
                            src={user.picture}
                            alt={user.name}
                            className="w-10 h-10 rounded-full object-cover"
                          />
                        ) : (
                          user.name
                            .split(' ')
                            .map((n) => n[0])
                            .join('')
                            .toUpperCase()
                            .slice(0, 2)
                        )}
                      </div>
                    </td>

                    {/* Name */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <span className="text-sm font-medium text-gray-900">{user.name}</span>
                    </td>

                    {/* Email */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-600">{user.email}</span>
                    </td>

                    {/* Phone */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-600">{user.phone || '-'}</span>
                    </td>

                    {/* Location */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-600">{user.location || '-'}</span>
                    </td>

                    {/* Birth Date */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-600">{formatDate(user.birth_date)}</span>
                    </td>

                    {/* Notifications Enabled */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      {user.notifications_enabled ? (
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                          <Bell className="w-3 h-3 mr-1" />
                          Enabled
                        </span>
                      ) : (
                        <span className="inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-600">
                          <BellOff className="w-3 h-3 mr-1" />
                          Disabled
                        </span>
                      )}
                    </td>

                    {/* Role */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <RoleBadge isOrganizer={user.role?.name === 'organizer'} />
                    </td>

                    {/* Created At */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-500">{formatDateTime(user.created_at)}</span>
                    </td>

                    {/* Updated At */}
                    <td className="px-4 py-4 whitespace-nowrap">
                      <span className="text-sm text-gray-500">{formatDateTime(user.updated_at)}</span>
                    </td>

                    {/* Actions */}
                    <td className="px-4 py-4 whitespace-nowrap text-right text-sm font-medium">
                      <div className="relative" ref={openMenuId === user.id ? menuRef : null}>
                        <button
                          type="button"
                          onClick={() => setOpenMenuId(openMenuId === user.id ? null : user.id)}
                          className="text-gray-400 hover:text-gray-600 transition-colors p-1 rounded-lg hover:bg-gray-100"
                        >
                          <MoreVertical className="w-5 h-5" />
                        </button>

                        {/* Dropdown Menu */}
                        {openMenuId === user.id && (
                          <div className="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-lg border border-gray-200 py-1 z-20">
                            {/* View Profile */}
                            <button
                              type="button"
                              onClick={() => handleViewProfile(user)}
                              className="w-full flex items-center px-4 py-2 text-sm text-gray-700 hover:bg-gray-50 transition-colors"
                            >
                              <Eye className="w-4 h-4 mr-3 text-gray-400" />
                              View Profile
                            </button>
                          </div>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Footer with count */}
        {!isLoading && filteredUsers.length > 0 && (
          <div className="px-6 py-4 border-t border-gray-200 bg-gray-50">
            <p className="text-sm text-gray-600">
              Showing <span className="font-medium">{filteredUsers.length}</span> of{' '}
              <span className="font-medium">{users.length}</span> users
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

// Mock data for development/fallback
const mockUsers: UserListItem[] = [
  {
    id: 1,
    name: 'John Doe',
    email: 'john@example.com',
    phone: '+963 912 345 678',
    location: 'Damascus',
    picture: null,
    birth_date: '1990-05-15',
    notifications_enabled: true,
    status: 'active',
    created_at: '2025-01-15T10:30:00Z',
    updated_at: '2025-01-15T10:30:00Z',
    role: { id: 1, name: 'user' },
  },
  {
    id: 2,
    name: 'Jane Smith',
    email: 'jane@example.com',
    phone: '+963 933 456 789',
    location: 'Aleppo',
    picture: null,
    birth_date: '1988-03-22',
    notifications_enabled: true,
    status: 'active',
    created_at: '2025-01-14T09:30:00Z',
    updated_at: '2025-01-16T14:20:00Z',
    role: { id: 2, name: 'organizer' },
  },
  {
    id: 3,
    name: 'Mike Johnson',
    email: 'mike@example.com',
    phone: '+963 944 567 890',
    location: 'Homs',
    picture: null,
    birth_date: '1995-07-10',
    notifications_enabled: false,
    status: 'active',
    created_at: '2025-01-10T14:20:00Z',
    updated_at: '2025-01-10T14:20:00Z',
    role: { id: 1, name: 'user' },
  },
  {
    id: 4,
    name: 'Sarah Williams',
    email: 'sarah@example.com',
    phone: '+963 955 678 901',
    location: 'Latakia',
    picture: null,
    birth_date: '1992-11-30',
    notifications_enabled: true,
    status: 'active',
    created_at: '2025-01-05T16:45:00Z',
    updated_at: '2025-01-18T08:15:00Z',
    role: { id: 2, name: 'organizer' },
  },
  {
    id: 5,
    name: 'Tom Brown',
    email: 'tom@example.com',
    phone: '+963 966 789 012',
    location: 'Damascus',
    picture: null,
    birth_date: '1985-01-25',
    notifications_enabled: true,
    status: 'active',
    created_at: '2025-01-01T08:00:00Z',
    updated_at: '2025-01-01T08:00:00Z',
    role: { id: 1, name: 'user' },
  },
  {
    id: 6,
    name: 'Emily Davis',
    email: 'emily@example.com',
    phone: '+963 977 890 123',
    location: 'Tartus',
    picture: null,
    birth_date: '1993-09-18',
    notifications_enabled: true,
    status: 'active',
    created_at: '2024-12-28T11:15:00Z',
    updated_at: '2025-01-12T09:45:00Z',
    role: { id: 1, name: 'user' },
  },
  {
    id: 7,
    name: 'Ahmed Hassan',
    email: 'ahmed@example.com',
    phone: '+963 988 901 234',
    location: 'Hama',
    picture: null,
    birth_date: '1991-04-05',
    notifications_enabled: false,
    status: 'active',
    created_at: '2024-12-20T13:30:00Z',
    updated_at: '2024-12-20T13:30:00Z',
    role: { id: 2, name: 'organizer' },
  },
];
