/**
 * API Request/Response Types
 */

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  message?: string;
  error?: string;
  timestamp?: number;
}

export interface RequestOptions extends RequestInit {
  params?: Record<string, any>;
  timeout?: number;
  retries?: number;
}

export interface HttpStatusCode {
  OK: 200;
  CREATED: 201;
  BAD_REQUEST: 400;
  UNAUTHORIZED: 401;
  FORBIDDEN: 403;
  NOT_FOUND: 404;
  CONFLICT: 409;
  INTERNAL_SERVER_ERROR: 500;
  SERVICE_UNAVAILABLE: 503;
}

export class ApiErrorType extends Error {
  constructor(
    public status: number,
    public message: string,
    public data?: any
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

/**
 * Personal Details Types
 */
export interface PersonalDetail {
  id: string;
  UserId: string;
  PANNumber: string;
  FirstName: string;
  MiddleName: string;
  LastName: string;
  Gender: string;
  DATEOFBIRTH: string | null;
  EMAIL: string;
  MobileNumber: string;
  aadharCardNumber: string;
  FinancialYear: string;
  Address: string;
  Country: string;
  isActive: string;
  createdAt: string;
  createdBy: string | null;
  updatedAt: string | null;
  updatedBy: string | null;
}

export interface PersonalDetailsResponse {
  status: string;
  statusCode: number;
  data: {
    personal_details: PersonalDetail;
  };
}
