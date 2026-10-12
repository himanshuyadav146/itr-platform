export const UserRole = {
  ADMIN: 'ADMIN',
  CA: 'CA',
  TAX_EXPERT: 'TAX_EXPERT',
  ACCOUNTANT: 'ACCOUNTANT',
  CLIENT: 'CLIENT',
} as const;

export type UserRole = typeof UserRole[keyof typeof UserRole];

export const ITRStatus = {
  PENDING: 'PENDING',
  ASSIGNED: 'ASSIGNED',
  REQUIRED: 'REQUIRED',
  INCORRECT: 'INCORRECT',
  FILED: 'FILED',
  COMPLETED: 'COMPLETED',
} as const;

export type ITRStatus = typeof ITRStatus[keyof typeof ITRStatus];

export const Permission = {
  VIEW_ALL_ITRS: 'VIEW_ALL_ITRS',
  VIEW_ASSIGNED_ITRS: 'VIEW_ASSIGNED_ITRS',
  VIEW_PAYMENTS: 'VIEW_PAYMENTS',
  ASSIGN_ITR: 'ASSIGN_ITR',
  EDIT_ITR: 'EDIT_ITR',
  VIEW_USERS: 'VIEW_USERS',
  VIEW_PROFESSIONALS: 'VIEW_PROFESSIONALS',
  MANAGE_USERS: 'MANAGE_USERS',
} as const;

export type Permission = typeof Permission[keyof typeof Permission];

export const ProfessionalOccupation = {
  CA: 'CA',
  TAX_EXPERT: 'TAX_EXPERT',
  ACCOUNTANT: 'ACCOUNTANT',
} as const;

export type ProfessionalOccupation = typeof ProfessionalOccupation[keyof typeof ProfessionalOccupation];

