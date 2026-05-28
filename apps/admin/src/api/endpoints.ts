// Use /login.php if backend only has that (e.g. main site); else /auth/login.php
const LOGIN_PATH = import.meta.env.VITE_LOGIN_PATH || '/auth/login.php';

export const API_ENDPOINTS = {
  // Authentication
  LOGIN: LOGIN_PATH,
  REGISTER_PROFESSIONAL: '/auth/signup.php',
  ADMIN_LOGIN: '/auth/admin_login.php',
  DELETE_ACCOUNT: '/auth/delete_account.php',

  // Dashboard
  DASHBOARD: '/admin/dashboard.php',
  
  // Users
  USERS: '/admin/users.php',
  USER_DETAILS: (id: number) => `/admin/users.php?id=${id}`,
  USER_STATS: (id: number) => `/admin/users.php?userId=${id}&stats=true`,
  
  // ITRs
  ITRS: '/admin/itrs.php',
  ITR_DETAILS: (id: number) => `/admin/itrs.php?id=${id}`,
  ITR_BY_USER: (userId: number) => `/get_itrbyuser.php?userId=${userId}`,
  ITR_BY_ID: (itrId: number) => `/get_itrbyitrid.php?itrId=${itrId}`,
  ITR_UPDATE: '/admin/itrs.php',
  ITR_COMMENT: '/admin/itrs.php?action=comment',
  ITR_ASSIGN: '/admin/itrs.php?action=assign',
  ITR_ACKNOWLEDGEMENT: '/admin/itrs.php?action=acknowledgement',
  SUBMIT_ACKNOWLEDGEMENT: '/admin/submit_acknowledgement.php?debug=1',

  // Professionals
  PROFESSIONALS: '/admin/professionals.php',
  PROFESSIONAL_DETAILS: (id: number) => `/admin/professionals.php?id=${id}`,
  
  // Personal Details
  PERSONAL_DETAILS: (userId: number, panNumber?: string) => {
    const base = `/itrdetails/get_personal_detail.php?UserId=${userId}`;
    return panNumber ? `${base}&PanNumber=${panNumber}` : base;
  },
  
  // Documents
  DOCUMENTS: (panNumber: string) => `/itrdetails/get_documents.php?PanNumber=${panNumber}`,
  DOCUMENT_DOWNLOAD: (filename: string) => `/admin/documents.php?download=true&file=${filename}`,
  DOCUMENTS_BY_ITR: (itrId: number) => `/admin/documents.php?itrId=${itrId}`,
  
  // Packages
  PACKAGES: '/package/getPackages.php',
  PACKAGE_ADD: '/package/addPackage.php',
  PACKAGE_DELETE: '/package/deletePackage.php',
} as const;

