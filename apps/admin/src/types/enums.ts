export const UserRole = {
  ADMIN: 'ADMIN',
  CA: 'CA',
  TAX_EXPERT: 'TAX_EXPERT',
  ACCOUNTANT: 'ACCOUNTANT',
  CLIENT: 'CLIENT',
} as const;

export type UserRole = typeof UserRole[keyof typeof UserRole];

/** Display statuses for dashboard/list/detail (synced with mobile). */
export const ITRDisplayStatus = {
  PENDING: 'PENDING',
  PAID: 'PAID',
  IN_PROGRESS: 'IN_PROGRESS',
  COMPLETED: 'COMPLETED',
} as const;

export type ITRDisplayStatus = typeof ITRDisplayStatus[keyof typeof ITRDisplayStatus];

/** Legacy workflow statuses set via ITR Status edit tab. */
export const ITRWorkflowStatus = {
  ASSIGNED: 'ASSIGNED',
  REQUIRED: 'REQUIRED',
  INCORRECT: 'INCORRECT',
  FILED: 'FILED',
} as const;

export type ITRWorkflowStatus = typeof ITRWorkflowStatus[keyof typeof ITRWorkflowStatus];

/** @deprecated Use ITRDisplayStatus for chips/filters; ITRWorkflowStatus for edit form. */
export const ITRStatus = {
  ...ITRDisplayStatus,
  ...ITRWorkflowStatus,
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

