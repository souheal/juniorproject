import apiClient from './client';

export interface UserListItem {
  id: number;
  name: string;
  email: string;
  phone: string | null;
  location: string | null;
  picture: string | null;
  birth_date: string | null;
  notifications_enabled: boolean;
  status: 'active' | 'inactive' | 'suspended';
  created_at: string;
  updated_at: string;
  role: {
    id: number;
    name: 'user' | 'organizer' | 'admin';
  } | null;
}

export interface UsersListResponse {
  users: UserListItem[];
  stats: {
    total: number;
    active: number;
    inactive: number;
    suspended: number;
  };
}

export interface UserFilters {
  search?: string;
  role?: 'user' | 'organizer' | 'all';
  status?: 'active' | 'inactive' | 'suspended' | 'all';
  page?: number;
  per_page?: number;
}

export const usersAPI = {
  /**
   * Get all users with optional filters
   */
  getUsers: async (filters?: UserFilters): Promise<UsersListResponse> => {
    const params = new URLSearchParams();

    if (filters?.search) params.append('search', filters.search);
    if (filters?.role && filters.role !== 'all') params.append('role', filters.role);
    if (filters?.status && filters.status !== 'all') params.append('status', filters.status);
    if (filters?.page) params.append('page', filters.page.toString());
    if (filters?.per_page) params.append('per_page', filters.per_page.toString());

    const { data } = await apiClient.get<UsersListResponse>(`/admin/users?${params.toString()}`);
    return data;
  },

  /**
   * Get a single user by ID
   */
  getUser: async (userId: number): Promise<UserListItem> => {
    const { data } = await apiClient.get<{ user: UserListItem }>(`/admin/users/${userId}`);
    return data.user;
  },

  /**
   * Activate a user account
   */
  activateUser: async (userId: number): Promise<{ message: string }> => {
    const { data } = await apiClient.post<{ message: string }>(`/admin/users/${userId}/activate`);
    return data;
  },

  /**
   * Deactivate a user account
   */
  deactivateUser: async (userId: number): Promise<{ message: string }> => {
    const { data } = await apiClient.post<{ message: string }>(`/admin/users/${userId}/deactivate`);
    return data;
  },

  /**
   * Suspend a user account
   */
  suspendUser: async (userId: number): Promise<{ message: string }> => {
    const { data } = await apiClient.post<{ message: string }>(`/admin/users/${userId}/suspend`);
    return data;
  },

  /**
   * Unsuspend a user account
   */
  unsuspendUser: async (userId: number): Promise<{ message: string }> => {
    const { data } = await apiClient.post<{ message: string }>(`/admin/users/${userId}/unsuspend`);
    return data;
  },
};
