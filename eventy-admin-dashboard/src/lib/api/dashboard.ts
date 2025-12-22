import apiClient from './client';

export interface DashboardStats {
  total_users: number;
  total_events: number;
  total_organizers: number;
  pending_requests: number;
  total_revenue: number;
}

export interface RecentRequest {
  id: number;
  name: string;
  organization: string;
  status: 'pending' | 'approved' | 'rejected';
  date: string;
}

export interface RecentEvent {
  id: number;
  name: string;
  organizer: string;
  date: string;
  status: 'published' | 'draft' | 'cancelled';
}

export interface MonthlyStats {
  month: string;
  users: number;
  events: number;
}

export interface DashboardResponse {
  stats: DashboardStats;
  recent_requests: RecentRequest[];
  recent_events: RecentEvent[];
  monthly_stats: MonthlyStats[];
}

export const dashboardAPI = {
  /**
   * Get dashboard statistics
   */
  getDashboard: async (): Promise<DashboardResponse> => {
    const { data } = await apiClient.get<DashboardResponse>('/admin/dashboard');
    return data;
  },
};
