import { Calendar, Search, MapPin, Trash2, Eye } from 'lucide-react';
import { StatsCard } from '@/components/common/StatsCard';
import { StatusBadge } from '@/components/common/StatusBadge';
import { useState } from 'react';

export function Events() {
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'published' | 'draft' | 'cancelled'>('all');

  // Mock data - replace with real API calls
  const stats = [
    { title: 'Total Events', value: '156', icon: Calendar, iconColor: 'text-purple-600', iconBgColor: 'bg-purple-100' },
    { title: 'Published', value: '112', icon: Calendar, iconColor: 'text-blue-600', iconBgColor: 'bg-blue-100' },
    { title: 'Draft', value: '32', icon: Calendar, iconColor: 'text-gray-600', iconBgColor: 'bg-gray-100' },
    { title: 'Cancelled', value: '12', icon: Calendar, iconColor: 'text-red-600', iconBgColor: 'bg-red-100' },
  ];

  const events = [
    { id: 1, name: 'Tech Conference 2025', organizer: 'John Doe', date: '2025-01-20', location: 'San Francisco', status: 'published' as const, attendees: 250 },
    { id: 2, name: 'Music Festival Summer', organizer: 'Jane Smith', date: '2025-02-15', location: 'Los Angeles', status: 'published' as const, attendees: 500 },
    { id: 3, name: 'Sports Tournament', organizer: 'Mike Johnson', date: '2025-03-10', location: 'New York', status: 'draft' as const, attendees: 0 },
    { id: 4, name: 'Art Exhibition', organizer: 'Sarah Williams', date: '2025-04-05', location: 'Chicago', status: 'published' as const, attendees: 120 },
    { id: 5, name: 'Food Festival', organizer: 'Tom Brown', date: '2025-05-01', location: 'Miami', status: 'cancelled' as const, attendees: 0 },
  ];

  const filteredEvents = selectedFilter === 'all'
    ? events
    : events.filter(e => e.status === selectedFilter);

  const handleDelete = (id: number, name: string) => {
    if (confirm(`Are you sure you want to delete "${name}"?`)) {
      console.log('Delete event:', id);
      // TODO: Implement delete logic
    }
  };

  const handleView = (id: number) => {
    console.log('View event:', id);
    // TODO: Navigate to event detail page
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Events Management</h1>
        <p className="text-gray-500 mt-1">Manage all events on the platform</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <StatsCard key={index} {...stat} />
        ))}
      </div>

      {/* Filters */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="p-6 border-b border-gray-200">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between space-y-4 md:space-y-0">
            {/* Filter Tabs */}
            <div className="flex space-x-2">
              {[
                { key: 'all', label: 'All Events' },
                { key: 'published', label: 'Published' },
                { key: 'draft', label: 'Draft' },
                { key: 'cancelled', label: 'Cancelled' },
              ].map((filter) => (
                <button
                  key={filter.key}
                  type="button"
                  onClick={() => setSelectedFilter(filter.key as any)}
                  className={`
                    px-4 py-2 rounded-lg text-sm font-medium transition-colors
                    ${selectedFilter === filter.key
                      ? 'bg-blue-600 text-white'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                    }
                  `}
                >
                  {filter.label}
                </button>
              ))}
            </div>

            {/* Search */}
            <div className="relative w-full md:w-64">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search events..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </div>

        {/* Events Grid */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 p-6">
          {filteredEvents.map((event) => (
            <div key={event.id} className="border border-gray-200 rounded-lg p-6 hover:shadow-md transition-all duration-200">
              <div className="flex items-start justify-between mb-4">
                <div className="flex-1">
                  <div className="flex items-center space-x-2 mb-2">
                    <h3 className="text-lg font-semibold text-gray-900">{event.name}</h3>
                    <StatusBadge status={event.status} />
                  </div>
                  <p className="text-sm text-gray-500">by {event.organizer}</p>
                </div>
              </div>

              <div className="space-y-2 mb-4">
                <div className="flex items-center text-sm text-gray-600">
                  <Calendar className="w-4 h-4 mr-2 text-gray-400" />
                  {new Date(event.date).toLocaleDateString('en-US', {
                    weekday: 'short',
                    year: 'numeric',
                    month: 'long',
                    day: 'numeric'
                  })}
                </div>
                <div className="flex items-center text-sm text-gray-600">
                  <MapPin className="w-4 h-4 mr-2 text-gray-400" />
                  {event.location}
                </div>
              </div>

              {event.attendees > 0 && (
                <div className="text-sm text-gray-500 mb-4">
                  {event.attendees} attendees
                </div>
              )}

              <div className="flex items-center space-x-2 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => handleView(event.id)}
                  className="flex-1 flex items-center justify-center px-3 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors text-sm"
                >
                  <Eye className="w-4 h-4 mr-2" />
                  View Details
                </button>
                <button
                  type="button"
                  onClick={() => handleDelete(event.id, event.name)}
                  className="flex items-center justify-center px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors text-sm"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
