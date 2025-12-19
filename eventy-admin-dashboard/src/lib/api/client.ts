import axios, { AxiosError } from 'axios';
import type { ApiError } from '@/types/api';

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL + '/api',
  headers: {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  },
  timeout: 30000, // 30 seconds
});

// Request interceptor: Add auth token
apiClient.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response interceptor: Handle errors globally
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  (error: AxiosError<any>) => {
    const apiError: ApiError = {
      message: 'An error occurred',
      status: error.response?.status,
    };

    if (error.response) {
      // Server responded with error
      apiError.message = error.response.data?.message || error.message;
      apiError.errors = error.response.data?.errors;

      // Handle 401 Unauthorized - token expired or invalid
      if (error.response.status === 401) {
        localStorage.removeItem('auth_token');
        localStorage.removeItem('auth_user');

        // Only redirect if not already on login page
        if (!window.location.pathname.includes('/login')) {
          window.location.href = '/login?session=expired';
        }
      }

      // Handle 403 Forbidden - not admin
      if (error.response.status === 403) {
        apiError.message = error.response.data?.message || 'Access denied. Admin privileges required.';
      }
    } else if (error.request) {
      // Request made but no response
      apiError.message = 'Network error. Please check your connection.';
    } else {
      // Error setting up request
      apiError.message = error.message;
    }

    return Promise.reject(apiError);
  }
);

export default apiClient;
