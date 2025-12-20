import { UserCheck, Search, Clock, CheckCircle, XCircle, Eye, X, Calendar, MapPin, Users, Ticket, Mail, Phone, Building } from 'lucide-react';
import { StatsCard } from '@/components/common/StatsCard';
import { StatusBadge } from '@/components/common/StatusBadge';
import { useState } from 'react';

interface OrganizerEvent {
  id: number;
  title: string;
  date: string;
  location: string;
  attendees: number;
  tickets_sold: number;
  status: 'published' | 'draft' | 'completed' | 'cancelled';
}

interface OrganizerRequest {
  id: number;
  name: string;
  organization: string;
  email: string;
  phone: string;
  status: 'pending' | 'approved' | 'rejected';
  date: string;
  documents: number;
  bio: string;
  events: OrganizerEvent[];
}

export function Organizers() {
  const [selectedTab, setSelectedTab] = useState<'all' | 'pending' | 'approved' | 'rejected'>('all');
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedOrganizer, setSelectedOrganizer] = useState<OrganizerRequest | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);

  // Mock data - replace with real API calls
  const stats = [
    { title: 'Total Requests', value: '156', icon: UserCheck, iconColor: 'text-blue-600', iconBgColor: 'bg-blue-100' },
    { title: 'Pending', value: '23', icon: Clock, iconColor: 'text-yellow-600', iconBgColor: 'bg-yellow-100' },
    { title: 'Approved', value: '112', icon: CheckCircle, iconColor: 'text-green-600', iconBgColor: 'bg-green-100' },
    { title: 'Rejected', value: '21', icon: XCircle, iconColor: 'text-red-600', iconBgColor: 'bg-red-100' },
  ];

  const requests: OrganizerRequest[] = [
    {
      id: 1,
      name: 'John Doe',
      organization: 'Tech Events Co.',
      email: 'john@techevents.com',
      phone: '+963 912 345 678',
      status: 'pending',
      date: '2025-01-15',
      documents: 3,
      bio: 'Professional event organizer with 5+ years of experience in tech conferences and workshops.',
      events: [],
    },
    {
      id: 2,
      name: 'Jane Smith',
      organization: 'Music Festival Group',
      email: 'jane@musicfest.com',
      phone: '+963 933 456 789',
      status: 'approved',
      date: '2025-01-14',
      documents: 5,
      bio: 'Passionate about bringing live music experiences to audiences across Syria.',
      events: [
        { id: 101, title: 'Summer Music Festival 2025', date: '2025-06-15', location: 'Damascus', attendees: 1500, tickets_sold: 1200, status: 'published' },
        { id: 102, title: 'Jazz Night', date: '2025-02-20', location: 'Aleppo', attendees: 300, tickets_sold: 280, status: 'published' },
        { id: 103, title: 'Classical Concert', date: '2024-12-10', location: 'Latakia', attendees: 450, tickets_sold: 450, status: 'completed' },
      ],
    },
    {
      id: 3,
      name: 'Mike Johnson',
      organization: 'Sports Events Ltd',
      email: 'mike@sportsevents.com',
      phone: '+963 944 567 890',
      status: 'rejected',
      date: '2025-01-10',
      documents: 2,
      bio: 'Sports enthusiast organizing local tournaments and competitions.',
      events: [],
    },
    {
      id: 4,
      name: 'Sarah Williams',
      organization: 'Art Gallery Events',
      email: 'sarah@artgallery.com',
      phone: '+963 955 678 901',
      status: 'pending',
      date: '2025-01-08',
      documents: 4,
      bio: 'Curator and event planner specializing in art exhibitions and cultural events.',
      events: [],
    },
    {
      id: 5,
      name: 'Tom Brown',
      organization: 'Conference Organizers',
      email: 'tom@conferences.com',
      phone: '+963 966 789 012',
      status: 'approved',
      date: '2025-01-05',
      documents: 6,
      bio: 'Expert in organizing business conferences and corporate events.',
      events: [
        { id: 201, title: 'Tech Summit 2025', date: '2025-03-10', location: 'Damascus', attendees: 800, tickets_sold: 650, status: 'published' },
        { id: 202, title: 'Startup Workshop', date: '2025-02-05', location: 'Homs', attendees: 150, tickets_sold: 120, status: 'published' },
        { id: 203, title: 'Business Networking', date: '2025-01-25', location: 'Damascus', attendees: 200, tickets_sold: 180, status: 'draft' },
        { id: 204, title: 'Annual Conference 2024', date: '2024-11-15', location: 'Aleppo', attendees: 500, tickets_sold: 500, status: 'completed' },
      ],
    },
  ];

  const filteredRequests = requests
    .filter(r => selectedTab === 'all' || r.status === selectedTab)
    .filter(r =>
      !searchQuery ||
      r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.organization.toLowerCase().includes(searchQuery.toLowerCase()) ||
      r.email.toLowerCase().includes(searchQuery.toLowerCase())
    );

  const handleApprove = (id: number) => {
    console.log('Approve request:', id);
    // TODO: Implement approve logic
  };

  const handleReject = (id: number) => {
    console.log('Reject request:', id);
    // TODO: Implement reject logic
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

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Organizer Requests</h1>
        <p className="text-gray-500 mt-1">Review and manage organizer applications</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
        {stats.map((stat, index) => (
          <StatsCard key={index} {...stat} />
        ))}
      </div>

      {/* Tabs */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-200">
        <div className="border-b border-gray-200">
          <nav className="flex space-x-4 px-6" aria-label="Tabs">
            {[
              { key: 'all', label: 'All Requests', count: requests.length },
              { key: 'pending', label: 'Pending', count: requests.filter(r => r.status === 'pending').length },
              { key: 'approved', label: 'Approved', count: requests.filter(r => r.status === 'approved').length },
              { key: 'rejected', label: 'Rejected', count: requests.filter(r => r.status === 'rejected').length },
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
                        <span>•</span>
                        <span>{request.documents} documents</span>
                        {request.status === 'approved' && request.events.length > 0 && (
                          <>
                            <span>•</span>
                            <span className="text-blue-600 font-medium">{request.events.length} events</span>
                          </>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Actions */}
                  <div className="flex items-center space-x-2 ml-4">
                    {/* View Details Button - Always visible */}
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
                          className="flex items-center px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
                        >
                          <CheckCircle className="w-4 h-4 mr-2" />
                          Approve
                        </button>
                        <button
                          type="button"
                          onClick={() => handleReject(request.id)}
                          className="flex items-center px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
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
                      <p className="text-gray-600 mt-1">{selectedOrganizer.bio}</p>

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
                          <span>{selectedOrganizer.phone}</span>
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
