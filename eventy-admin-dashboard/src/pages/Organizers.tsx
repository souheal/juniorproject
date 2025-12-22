import { UserCheck, Search, Clock, CheckCircle, XCircle, Eye, X, Calendar, MapPin, Users, Ticket, Mail, Phone, Building, AlertCircle } from 'lucide-react';
import { StatsCard } from '@/components/common/StatsCard';
import { StatusBadge } from '@/components/common/StatusBadge';
import { useState, useEffect } from 'react';
import { organizersAPI, type OrganizerRequest, type OrganizersStats } from '@/lib/api/organizers';

export function Organizers() {
  const [requests, setRequests] = useState<OrganizerRequest[]>([]);
  const [stats, setStats] = useState<OrganizersStats | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [selectedTab, setSelectedTab] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedOrganizer, setSelectedOrganizer] = useState<OrganizerRequest | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [isProcessing, setIsProcessing] = useState<number | null>(null);

  useEffect(() => {
    fetchRequests();
  }, []);

  const fetchRequests = async () => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await organizersAPI.getRequests();
      setRequests(response.requests);
      setStats(response.stats);
    } catch (err: any) {
      console.error('Failed to fetch organizer requests:', err);
      setError(err.message || 'Failed to load organizer requests');
    } finally {
      setIsLoading(false);
    }
  };

  // Filter requests
  const filteredRequests = requests
    .filter(r => selectedTab === 'all' || r.status === selectedTab)
    .filter(r =>
      !searchQuery ||
      r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.organization.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.email.toLowerCase().includes(searchQuery.toLowerCase())
    );

  // Stats cards
  const statsCards = stats ? [
    { title: 'Total Requests', value: stats.total.toString(), icon: UserCheck, iconColor: 'text-blue-600', iconBgColor: 'bg-blue-100' },
    { title: 'Pending', value: stats.pending.toString(), icon: Clock, iconColor: 'text-yellow-600', iconBgColor: 'bg-yellow-100' },
    { title: 'Approved', value: stats.approved.toString(), icon: CheckCircle, iconColor: 'text-green-600', iconBgColor: 'bg-green-100' },
    { title: 'Rejected', value: stats.rejected.toString(), icon: XCircle, iconColor: 'text-red-600', iconBgColor: 'bg-red-100' },
  ] : [];

  const handleApprove = async (id: number) => {
    setIsProcessing(id);
    try {
      await organizersAPI.approveRequest(id);
      // Update local state
      setRequests(requests.map(r =>
        r.id === id ? { ...r, status: 'approved' as const } : r
      ));
      // Update stats
      if (stats) {
        setStats({
          ...stats,
          pending: stats.pending - 1,
          approved: stats.approved + 1,
        });
      }
    } catch (err: any) {
      alert(err.message || 'Failed to approve request');
    } finally {
      setIsProcessing(null);
    }
  };

  const handleReject = async (id: number) => {
    const reason = prompt('Enter rejection reason (optional):');
    setIsProcessing(id);
    try {
      await organizersAPI.rejectRequest(id, reason || undefined);
      // Update local state
      setRequests(requests.map(r =>
        r.id === id ? { ...r, status: 'rejected' as const } : r
      ));
      // Update stats
      if (stats) {
        setStats({
          ...stats,
          pending: stats.pending - 1,
          rejected: stats.rejected + 1,
        });
      }
    } catch (err: any) {
      alert(err.message || 'Failed to reject request');
    } finally {
      setIsProcessing(null);
    }
  };

  const handleViewDetails = (organizer: OrganizerRequest) => {
    setSelectedOrganizer(organizer);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setSelectedOrganizer(null);
  };

  // Get event status badge color
  const getEventStatusColor = (status: string) => {
    switch (status) {
      case 'published':
        return 'bg-blue-100 text-blue-800';
      case 'completed':
        return 'bg-green-100 text-green-800';
      case 'draft':
        return 'bg-gray-100 text-gray-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
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
        <h1 className="text-2xl font-bold text-gray-900">Organizer Requests</h1>
        <p className="text-gray-500 mt-1">Review and manage organizer applications</p>
      </div>

      {/* Error Alert */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start gap-3">
          <AlertCircle className="w-5 h-5 text-red-600 flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm text-red-800">{error}</p>
            <button
              onClick={fetchRequests}
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

      {/* Tabs */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="border-b border-gray-200">
          <nav className="flex space-x-4 px-6" aria-label="Tabs">
            {[
              { key: 'all', label: 'All Requests', count: stats?.total || 0 },
              { key: 'pending', label: 'Pending', count: stats?.pending || 0 },
              { key: 'approved', label: 'Approved', count: stats?.approved || 0 },
              { key: 'rejected', label: 'Rejected', count: stats?.rejected || 0 },
            ].map((tab) => (
              <button
                key={tab.key}
                type="button"
                onClick={() => setSelectedTab(tab.key as any)}
                className={`
                  py-4 px-1 border-b-2 font-medium text-sm transition-colors
                  ${selectedTab === tab.key
                    ? 'border-blue-500 text-blue-600'
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                  }
                `}
              >
                {tab.label}
                <span className="ml-2 py-0.5 px-2 rounded-full text-xs bg-gray-100">
                  {tab.count}
                </span>
              </button>
            ))}
          </nav>
        </div>

        {/* Search */}
        <div className="p-6 border-b border-gray-200">
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              placeholder="Search by name, organization, or email..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Requests List */}
        <div className="divide-y divide-gray-200">
          {filteredRequests.length === 0 ? (
            <div className="flex flex-col items-center justify-center py-12 text-gray-500">
              <UserCheck className="w-12 h-12 mb-3 text-gray-300" />
              <p className="text-lg font-medium">No organizers found</p>
              <p className="text-sm">Try adjusting your search or filters</p>
            </div>
          ) : (
            filteredRequests.map((request) => (
              <div key={request.id} className="p-6 hover:bg-gray-50 transition-colors">
                <div className="flex items-start justify-between">
                  <div className="flex items-start space-x-4 flex-1">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold text-lg">
                      {request.name.split(' ').map(n => n[0]).join('').toUpperCase()}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center space-x-2">
                        <h3 className="text-lg font-semibold text-gray-900">{request.name}</h3>
                        <StatusBadge status={request.status} />
                      </div>
                      <p className="text-sm text-gray-600 mt-1">{request.organization}</p>
                      <p className="text-sm text-gray-500 mt-1">{request.email}</p>
                      <div className="flex items-center space-x-4 mt-2 text-sm text-gray-500">
                        <span>Applied: {new Date(request.date).toLocaleDateString()}</span>
                        {request.status === 'approved' && request.events.length > 0 && (
                          <>
                            <span>-</span>
                            <span className="text-blue-600 font-medium">{request.events.length} events</span>
                          </>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center space-x-2 ml-4">
                    {/* View Details Button */}
                    <button
                      type="button"
                      onClick={() => handleViewDetails(request)}
                      className="flex items-center px-4 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
                    >
                      <Eye className="w-4 h-4 mr-2" />
                      View Details
                    </button>

                    {/* Approve/Reject Buttons - Only for pending */}
                    {request.status === 'pending' && (
                      <>
                        <button
                          type="button"
                          onClick={() => handleApprove(request.id)}
                          disabled={isProcessing === request.id}
                          className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors disabled:opacity-50"
                        >
                          {isProcessing === request.id ? (
                            <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2" />
                          ) : (
                            <CheckCircle className="w-4 h-4 mr-2" />
                          )}
                          Approve
                        </button>
                        <button
                          type="button"
                          onClick={() => handleReject(request.id)}
                          disabled={isProcessing === request.id}
                          className="flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50"
                        >
                          <XCircle className="w-4 h-4 mr-2" />
                          Reject
                        </button>
                      </>
                    )}
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      {/* View Details Modal */}
      {isModalOpen && selectedOrganizer && (
        <div className="fixed inset-0 z-50 overflow-y-auto">
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
            onClick={closeModal}
          />

          {/* Modal */}
          <div className="flex min-h-full items-center justify-center p-4">
            <div className="relative bg-white rounded-2xl shadow-xl max-w-4xl w-full max-h-[90vh] overflow-hidden">
              {/* Modal Header */}
              <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 bg-gradient-to-r from-blue-600 to-purple-600">
                <h2 className="text-xl font-bold text-white">Organizer Details</h2>
                <button
                  type="button"
                  onClick={closeModal}
                  className="text-white hover:bg-white/20 rounded-lg p-2 transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {/* Modal Body */}
              <div className="overflow-y-auto max-h-[calc(90vh-80px)]">
                {/* Organizer Profile Section */}
                <div className="p-6 border-b border-gray-200">
                  <div className="flex items-start space-x-4">
                    <div className="w-20 h-20 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-bold text-2xl flex-shrink-0">
                      {selectedOrganizer.name.split(' ').map(n => n[0]).join('').toUpperCase()}
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center space-x-3">
                        <h3 className="text-2xl font-bold text-gray-900">{selectedOrganizer.name}</h3>
                        <StatusBadge status={selectedOrganizer.status} />
                      </div>
                      <p className="text-gray-600 mt-1">{selectedOrganizer.bio || 'No bio provided'}</p>

                      <div className="grid grid-cols-2 gap-4 mt-4">
                        <div className="flex items-center text-gray-600">
                          <Building className="w-4 h-4 mr-2 text-gray-400" />
                          <span>{selectedOrganizer.organization}</span>
                        </div>
                        <div className="flex items-center text-gray-600">
                          <Mail className="w-4 h-4 mr-2 text-gray-400" />
                          <span>{selectedOrganizer.email}</span>
                        </div>
                        <div className="flex items-center text-gray-600">
                          <Phone className="w-4 h-4 mr-2 text-gray-400" />
                          <span>{selectedOrganizer.phone || 'No phone'}</span>
                        </div>
                        <div className="flex items-center text-gray-600">
                          <Calendar className="w-4 h-4 mr-2 text-gray-400" />
                          <span>Applied: {new Date(selectedOrganizer.date).toLocaleDateString()}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Events Section */}
                <div className="p-6">
                  <h4 className="text-lg font-semibold text-gray-900 mb-4 flex items-center">
                    <Calendar className="w-5 h-5 mr-2 text-blue-600" />
                    Events ({selectedOrganizer.events.length})
                  </h4>

                  {selectedOrganizer.events.length === 0 ? (
                    <div className="bg-gray-50 rounded-lg p-8 text-center">
                      <Calendar className="w-12 h-12 mx-auto text-gray-300 mb-3" />
                      <p className="text-gray-500">No events created yet</p>
                      {selectedOrganizer.status === 'pending' && (
                        <p className="text-sm text-gray-400 mt-1">
                          Events can be created after approval
                        </p>
                      )}
                    </div>
                  ) : (
                    <div className="space-y-4">
                      {selectedOrganizer.events.map((event) => (
                        <div
                          key={event.id}
                          className="bg-gray-50 rounded-lg p-4 hover:bg-gray-100 transition-colors"
                        >
                          <div className="flex items-start justify-between">
                            <div className="flex-1">
                              <div className="flex items-center space-x-2">
                                <h5 className="font-semibold text-gray-900">{event.title}</h5>
                                <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${getEventStatusColor(event.status)}`}>
                                  {event.status.charAt(0).toUpperCase() + event.status.slice(1)}
                                </span>
                              </div>
                              <div className="flex items-center space-x-4 mt-2 text-sm text-gray-500">
                                <span className="flex items-center">
                                  <Calendar className="w-4 h-4 mr-1" />
                                  {new Date(event.date).toLocaleDateString('en-US', {
                                    year: 'numeric',
                                    month: 'short',
                                    day: 'numeric',
                                  })}
                                </span>
                                <span className="flex items-center">
                                  <MapPin className="w-4 h-4 mr-1" />
                                  {event.location}
                                </span>
                              </div>
                            </div>
                            <div className="flex items-center space-x-6 text-sm">
                              <div className="text-center">
                                <div className="flex items-center text-gray-600">
                                  <Users className="w-4 h-4 mr-1" />
                                  <span className="font-semibold">{event.attendees}</span>
                                </div>
                                <p className="text-xs text-gray-400">Attendees</p>
                              </div>
                              <div className="text-center">
                                <div className="flex items-center text-gray-600">
                                  <Ticket className="w-4 h-4 mr-1" />
                                  <span className="font-semibold">{event.tickets_sold}</span>
                                </div>
                                <p className="text-xs text-gray-400">Tickets Sold</p>
                              </div>
                            </div>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                {/* Summary Stats for Approved Organizers */}
                {selectedOrganizer.status === 'approved' && selectedOrganizer.events.length > 0 && (
                  <div className="px-6 pb-6">
                    <div className="bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg p-4">
                      <h5 className="font-semibold text-gray-900 mb-3">Summary</h5>
                      <div className="grid grid-cols-3 gap-4">
                        <div className="text-center">
                          <p className="text-2xl font-bold text-blue-600">{selectedOrganizer.events.length}</p>
                          <p className="text-sm text-gray-500">Total Events</p>
                        </div>
                        <div className="text-center">
                          <p className="text-2xl font-bold text-green-600">
                            {selectedOrganizer.events.reduce((sum, e) => sum + e.attendees, 0).toLocaleString()}
                          </p>
                          <p className="text-sm text-gray-500">Total Attendees</p>
                        </div>
                        <div className="text-center">
                          <p className="text-2xl font-bold text-purple-600">
                            {selectedOrganizer.events.reduce((sum, e) => sum + e.tickets_sold, 0).toLocaleString()}
                          </p>
                          <p className="text-sm text-gray-500">Tickets Sold</p>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </div>

              {/* Modal Footer */}
              <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-200 bg-gray-50">
                {selectedOrganizer.status === 'pending' && (
                  <>
                    <button
                      type="button"
                      onClick={() => {
                        handleReject(selectedOrganizer.id);
                        closeModal();
                      }}
                      className="flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                    >
                      <XCircle className="w-4 h-4 mr-2" />
                      Reject
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        handleApprove(selectedOrganizer.id);
                        closeModal();
                      }}
                      className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                    >
                      <CheckCircle className="w-4 h-4 mr-2" />
                      Approve
                    </button>
                  </>
                )}
                <button
                  type="button"
                  onClick={closeModal}
                  className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors"
                >
                  Close
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
