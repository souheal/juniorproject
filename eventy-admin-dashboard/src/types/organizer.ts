import { User } from './auth';

export type OrganizerRequestStatus = 'pending' | 'approved' | 'rejected';

export interface OrganizerRequest {
  id: number;
  user_id: number;
  organization_name: string;
  description: string;
  documents: string | null;
  status: OrganizerRequestStatus;
  admin_comment: string | null;
  created_at: string;
  updated_at: string;
  user?: User;
}

export interface OrganizerProfile {
  id: number;
  user_id: number;
  website: string | null;
  verified: boolean;
  created_at: string;
  updated_at: string;
}

export interface ApproveOrganizerPayload {
  admin_comment?: string;
}

export interface RejectOrganizerPayload {
  admin_comment?: string;
}
