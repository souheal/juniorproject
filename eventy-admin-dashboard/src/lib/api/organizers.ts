import apiClient from './client';

export interface OrganizerEvent {
  id: number;
  title: string;
  date: string;
  location: string;
  attendees: number;
  tickets_sold: number;
  status: 'published' | 'draft' | 'completed' | 'cancelled';
}

export interface OrganizerRequest {
  id: number;
  name: string;
  email: string;
  phone: string;
  organization: string;
  bio: string;
  status: 'pending' | 'approved' | 'rejected';
  date: string;
  created_at: string;
  documents: number;
  events: OrganizerEvent[];
}

export interface OrganizersStats {
  total: number;
  pending: number;
  approved: number;
  rejected: number;
}

export interface OrganizersResponse {
  requests: OrganizerRequest[];
  stats: OrganizersStats;
}

export interface OrganizerFilters {
  search?: string;
  status?: 'pending' | 'approved' | 'rejected' | 'all';
}

export const organizersAPI = {
  /**
   * Get all organizer requests with optional filters
   */
  getRequests: async (filters?: OrganizerFilters): Promise<OrganizersResponse> => {
    const params = new URLSearchParams();

    if (filters?.search) params.append('search', filters.search);
    if (filters?.status && filters.status !== 'all') params.append('status', filters.status);

    const { data } = await apiClient.get<OrganizersResponse>(`/admin/organizer-requests?${params.toString()}`);
    return data;
  },

  /**
   * Approve an organizer request
   */
  approveRequest: async (requestId: number, adminComment?: string): Promise<{ message: string }> => {
    const { data } = await apiClient.post<{ message: string }>(`/admin/organizer-requests/${requestId}/approve`, {
      admin_comment: adminComment,
    });
    return data;
  },

  /**
   * Reject an organizer request
   */
  rejectRequest: async (requestId: number, adminComment?: string): Promise<{ message: string }> => {
    const { data } = await apiClient.post<{ message: string }>(`/admin/organizer-requests/${requestId}/reject`, {
      admin_comment: adminComment,
    });
    return data;
  },
};
