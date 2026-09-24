/**
 * Authentication Types
 */

export interface User {
  id?: string;
  UserId?: string | number;
  name: string;
  email: string;
  mobile: string;
  role?: string;
  platform?: string;
  PanNumber?: string;
  pan?: string;
}

export interface AuthCredentials {
  email: string;
  password: string;
  platform:string;
  version:string;
}

export interface SignupData {
  name: string;
  email: string;
  mobile: string;
  password: string;
  platform?: string;
  version?: string;
  role?: string;
}

export interface AuthResponse {
  token: string;
  user?: User;
  UserId?: string | number;
  name?: string;
  email?: string;
  mobile?: string;
}

export interface ChangePasswordData {
  currentPassword: string;
  newPassword: string;
}

export interface ForgotPasswordData {
  email: string;
  password: string;
}

export interface ResetPasswordData {
  token: string;
  newPassword: string;
}

export interface VerifyEmailData {
  token: string;
}
