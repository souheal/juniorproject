import { User as AuthUser } from './auth';

// Extend the AuthUser type for user management features
export type User = AuthUser;

export type UserStatus = 'active' | 'inactive' | 'suspended';

export interface UserFilters {
  role?: 'user' | 'organizer' | 'all';
  search?: string;
  status?: UserStatus | 'all';
}

export interface UserStats {
  total_events: number;
  total_tickets: number;
  saved_events: number;
}

export interface AdminUserStats {
  total: number;
  active: number;
  inactive: number;
  suspended: number;
}
