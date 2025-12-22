import { Calendar, Search, MapPin, Trash2, Eye, AlertCircle, Ticket, Users } from 'lucide-react';
import { StatsCard } from '@/components/common/StatsCard';
import { StatusBadge } from '@/components/common/StatusBadge';
import { useState, useEffect } from 'react';
import { eventsAPI, type EventListItem, type EventsStats } from '@/lib/api/events';

export function Events() {
  const [events, setEvents] = useState<EventListItem[]>([]);
  const [stats, setStats] = useState<EventsStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'published' | 'draft' | 'cancelled'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [isDeleting, setIsDeleting] = useState<number | null>(null);

  useEffect(() => {
    fetchEvents();
  }, []);

  const fetchEvents = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await eventsAPI.getEvents();
      setEvents(response.events);
      setStats(response.stats);
    } catch (err: any) {
      console.error('Failed to fetch events:', err);
      setError(err.message || 'Failed to load events');
    } finally {
      setIsLoading(false);
    }
  };

  // Filter events based on search and status
  const filteredEvents = events.filter((event) => {
    const matchesSearch =
      !searchQuery ||
      event.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      event.organizer.toLowerCase().includes(searchQuery.toLowerCase()) ||
      event.location?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesStatus =
      selectedFilter === 'all' || event.status === selectedFilter;

    return matchesSearch && matchesStatus;
  });

  // Stats cards
  const statsCards = stats ? [
    { title: 'Total Events', value: stats.total.toString(), icon: Calendar, iconColor: 'text-purple-600', iconBgColor: 'bg-purple-100' },
    { title: 'Published', value: stats.published.toString(), icon: Calendar, iconColor: 'text-blue-600', iconBgColor: 'bg-blue-100' },
    { title: 'Draft', value: stats.draft.toString(), icon: Calendar, iconColor: 'text-gray-600', iconBgColor: 'bg-gray-100' },
    { title: 'Cancelled', value: stats.cancelled.toString(), icon: Calendar, iconColor: 'text-red-600', iconBgColor: 'bg-red-100' },
  ] : [];

  const handleDelete = async (id: number, name: string) => {
    if (!confirm(`Are you sure you want to delete "${name}"?`)) {
      return;
    }

    setIsDeleting(id);
    try {
      await eventsAPI.deleteEvent(id);
      // Remove from local state
      setEvents(events.filter(e => e.id !== id));
      // Update stats
      if (stats) {
        const deletedEvent = events.find(e => e.id === id);
        if (deletedEvent) {
          setStats({
            ...stats,
            total: stats.total - 1,
            [deletedEvent.status]: stats[deletedEvent.status] - 1,
          });
        }
      }
    } catch (err: any) {
      alert(err.message || 'Failed to delete event');
    } finally {
      setIsDeleting(null);
    }
  };

  const handleView = (id: number) => {
    // TODO: Navigate to event detail page or open modal
    console.log('View event:', id);
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-[400px]">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Events Management</h1>
        <p className="text-gray-500 mt-1">Manage all events on the platform</p>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm text-red-800">{error}</p>
            <button
              onClick={fetchEvents}
              className="text-sm text-red-600 hover:text-red-800 font-medium mt-1"
            >
              Try again
            </button>
          </div>
        </div>
      )}

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {statsCards.map((stat, index) => (
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
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </div>

        {/* Events Grid */}
        {filteredEvents.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-12 text-gray-500">
            <Calendar className="w-12 h-12 mb-3 text-gray-300" />
            <p className="text-lg font-medium">No events found</p>
            <p className="text-sm">Try adjusting your search or filters</p>
          </div>
        ) : (
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
                  {event.image && (
                    <img
                      src={event.image}
                      alt={event.name}
                      className="w-16 h-16 rounded-lg object-cover ml-4"
                    />
                  )}
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
                    {event.location || 'No location'}
                  </div>
                </div>

                <div className="flex items-center space-x-4 text-sm text-gray-500 mb-4">
                  <div className="flex items-center">
                    <Ticket className="w-4 h-4 mr-1" />
                    {event.tickets_sold} / {event.max_attendees || '∞'} tickets
                  </div>
                  <div className="flex items-center">
                    <span className="font-medium text-green-600">
                      ${event.ticket_price || 0}
                    </span>
                  </div>
                </div>

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
                    disabled={isDeleting === event.id}
                    className="flex items-center justify-center px-3 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors text-sm disabled:opacity-50"
                  >
                    {isDeleting === event.id ? (
                      <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    ) : (
                      <Trash2 className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Footer with count */}
        {filteredEvents.length > 0 && (
          <div className="px-6 py-4 border-t border-gray-200 bg-gray-50">
            <p className="text-sm text-gray-600">
              Showing <span className="font-medium">{filteredEvents.length}</span> of{' '}
              <span className="font-medium">{events.length}</span> events
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
