import type { Admin } from './user';

export interface AuthUser extends Admin {}

export interface AuthResponse {
  token: string;
  user: AuthUser;
}


