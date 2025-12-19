import { User } from './auth';

export type EventStatus = 'draft' | 'published' | 'cancelled' | 'completed';

export interface Event {
  id: number;
  organizer_id: number;
  name: string;
  description: string;
  location: string;
  city: string | null;
  venue: string | null;
  price: number;
  capacity: number;
  start_time: string;
  end_time: string;
  online_link: string | null;
  picture: string | null;
  status: EventStatus;
  published_at: string | null;
  is_live: boolean;
  created_at: string;
  updated_at: string;
  organizer?: User;
}

export interface Category {
  id: number;
  name: string;
}

export interface EventFilters {
  status?: EventStatus;
  city?: string;
  search?: string;
  start_date?: string;
  end_date?: string;
}
