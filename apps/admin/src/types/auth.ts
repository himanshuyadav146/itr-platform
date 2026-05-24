import { UserRole } from './enums';

export interface User {
  UserId: number;
  FirstName: string;
  MiddleName?: string;
  LastName: string;
  Email: string;
  Mobile?: string;
  role?: UserRole;
  Platform?: string;
  Version?: string;
  CreatedAt?: string;
  UpdatedAt?: string;
}



export interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  role: UserRole | null;
}

export interface LoginCredentials {
  email: string;
  password: string;
  platform?: string;
  version?: string;
}

export interface LoginResponse {
  statusCode: number;
  status: 'success' | 'error';
  data: {
    message: string;
    UserId: number;
    email: string;
    token: string;
    role?: string; // Role from API
  };
}

export interface RegisterProfessionalData {
  name: string;
  email: string;
  phone: string;
  password: string;
  occupation: string;
}

