import { MessageSquare, Search, Trash2, Eye, Flag } from 'lucide-react';
import { StatsCard } from '@/components/common/StatsCard';
import { useState } from 'react';

export function Comments() {
  const [selectedFilter, setSelectedFilter] = useState<'all' | 'flagged' | 'spam'>('all');

  // Mock data - replace with real API calls
  const stats = [
    { title: 'Total Comments', value: '1,234', icon: MessageSquare, iconColor: 'text-blue-600', iconBgColor: 'bg-blue-100' },
    { title: 'Flagged', value: '23', icon: Flag, iconColor: 'text-yellow-600', iconBgColor: 'bg-yellow-100' },
    { title: 'Spam', value: '12', icon: MessageSquare, iconColor: 'text-red-600', iconBgColor: 'bg-red-100' },
  ];

  const comments = [
    { id: 1, author: 'John Doe', event: 'Tech Conference 2025', content: 'Great event! Looking forward to attending.', date: '2025-01-15', flagged: false },
    { id: 2, author: 'Jane Smith', event: 'Music Festival Summer', content: 'This is spam content selling products', date: '2025-01-14', flagged: true },
    { id: 3, author: 'Mike Johnson', event: 'Sports Tournament', content: 'When will tickets be available?', date: '2025-01-10', flagged: false },
    { id: 4, author: 'Sarah Williams', event: 'Art Exhibition', content: 'Inappropriate content here', date: '2025-01-08', flagged: true },
    { id: 5, author: 'Tom Brown', event: 'Food Festival', content: 'Can\'t wait for this event!', date: '2025-01-05', flagged: false },
  ];

  const filteredComments = selectedFilter === 'all'
    ? comments
    : selectedFilter === 'flagged'
    ? comments.filter(c => c.flagged)
    : comments.filter(c => c.content.toLowerCase().includes('spam'));

  const handleDelete = (id: number) => {
    if (confirm('Are you sure you want to delete this comment?')) {
      console.log('Delete comment:', id);
      // TODO: Implement delete logic
    }
  };

  const handleView = (id: number) => {
    console.log('View comment:', id);
    // TODO: Navigate to comment detail
  };

  return (
    <div className="space-y-6">
      {/* Page Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Comments Moderation</h1>
        <p className="text-gray-500 mt-1">Monitor and moderate user comments</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
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
                { key: 'all', label: 'All Comments' },
                { key: 'flagged', label: 'Flagged' },
                { key: 'spam', label: 'Spam' },
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
                placeholder="Search comments..."
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          </div>
        </div>

        {/* Comments List */}
        <div className="divide-y divide-gray-200">
          {filteredComments.map((comment) => (
            <div key={comment.id} className="p-6 hover:bg-gray-50 transition-colors">
              <div className="flex items-start justify-between">
                <div className="flex items-start space-x-4 flex-1">
                  <div className="w-10 h-10 rounded-full bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center text-white font-semibold">
                    {comment.author.split(' ').map(n => n[0]).join('').toUpperCase()}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center space-x-2">
                      <h3 className="font-semibold text-gray-900">{comment.author}</h3>
                      {comment.flagged && (
                        <span className="flex items-center px-2 py-1 text-xs font-medium rounded-full bg-yellow-100 text-yellow-800">
                          <Flag className="w-3 h-3 mr-1" />
                          Flagged
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-gray-500 mt-1">
                      on <span className="font-medium">{comment.event}</span> • {new Date(comment.date).toLocaleDateString()}
                    </p>
                    <p className="text-gray-700 mt-2">{comment.content}</p>
                  </div>
                </div>

                {/* Actions */}
                <div className="flex items-center space-x-2 ml-4">
                  <button
                    type="button"
                    onClick={() => handleView(comment.id)}
                    className="p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                    title="View Details"
                  >
                    <Eye className="w-5 h-5" />
                  </button>
                  <button
                    type="button"
                    onClick={() => handleDelete(comment.id)}
                    className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                    title="Delete Comment"
                  >
                    <Trash2 className="w-5 h-5" />
                  </button>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
