export interface Role {
  id: number;
  name: 'user' | 'organizer' | 'admin';
}

export interface User {
  id: number;
  role_id: number;
  name: string;
  email: string;
  phone: string | null;
  location: string | null;
  picture: string | null;
  birth_date: string | null;
  email_verified_at: string | null;
  notifications_enabled: boolean;
  created_at: string;
  updated_at: string;
  role?: Role;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface LoginResponse {
  message: string;
  user: User;
  token: string;
}

export interface AuthState {
  user: User | null;
  token: string | null;
  isLoading: boolean;
  isAuthenticated: boolean;
}
