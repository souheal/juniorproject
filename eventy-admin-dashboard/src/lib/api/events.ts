import apiClient from './client';

export interface EventListItem {
  id: number;
  name: string;
  organizer: string;
  organizer_id: number;
  date: string;
  end_date: string | null;
  location: string;
  status: 'published' | 'draft' | 'cancelled';
  ticket_price: number;
  max_attendees: number;
  tickets_sold: number;
  image: string | null;
  created_at: string;
}

export interface EventsStats {
  total: number;
  published: number;
  draft: number;
  cancelled: number;
}

export interface EventsResponse {
  events: EventListItem[];
  stats: EventsStats;
}

export interface EventFilters {
  search?: string;
  status?: 'published' | 'draft' | 'cancelled' | 'all';
}

export const eventsAPI = {
  /**
   * Get all events with optional filters
   */
  getEvents: async (filters?: EventFilters): Promise<EventsResponse> => {
    const params = new URLSearchParams();

    if (filters?.search) params.append('search', filters.search);
    if (filters?.status && filters.status !== 'all') params.append('status', filters.status);

    const { data } = await apiClient.get<EventsResponse>(`/admin/events?${params.toString()}`);
    return data;
  },

  /**
   * Delete an event
   */
  deleteEvent: async (eventId: number): Promise<{ message: string }> => {
    const { data } = await apiClient.delete<{ message: string }>(`/admin/events/${eventId}`);
    return data;
  },
};
