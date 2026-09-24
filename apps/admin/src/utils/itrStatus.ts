/** Unified display statuses shown on dashboard, list, and detail (synced with mobile workflow). */
export const ITR_DISPLAY_STATUSES = ['PENDING', 'PAID', 'IN_PROGRESS', 'COMPLETED'] as const;
export type ITRDisplayStatus = (typeof ITR_DISPLAY_STATUSES)[number];

/** Workflow statuses professionals set via ITR Status edit (itr_detail.status). */
export const ITR_WORKFLOW_STATUSES = ['ASSIGNED', 'REQUIRED', 'INCORRECT', 'FILED'] as const;
export type ITRWorkflowStatus = (typeof ITR_WORKFLOW_STATUSES)[number];

export function normalizeDisplayStatus(raw: string | undefined | null): ITRDisplayStatus {
  const upper = (raw ?? '').toUpperCase().trim();
  if (upper === 'SUCCESS') return 'COMPLETED';
  if (ITR_DISPLAY_STATUSES.includes(upper as ITRDisplayStatus)) {
    return upper as ITRDisplayStatus;
  }
  return 'PENDING';
}

export function resolveDisplayStatusFromApi(itr: Record<string, unknown>): ITRDisplayStatus {
  if (itr.displayStatus) {
    return normalizeDisplayStatus(String(itr.displayStatus));
  }
  if (itr.statusDisplayText) {
    const text = String(itr.statusDisplayText).toLowerCase();
    if (text.includes('complete')) return 'COMPLETED';
    if (text.includes('progress')) return 'IN_PROGRESS';
    if (text === 'paid') return 'PAID';
    if (text.includes('pending')) return 'PENDING';
  }
  const ack =
    itr.acknowledgementNumber ??
    itr.acknowledgement_number ??
    itr.acknowledgement;
  if (ack != null && String(ack).trim() !== '') return 'COMPLETED';

  const hasPay =
    itr.hasSuccessfulPayment === true ||
    (Array.isArray(itr.payments) &&
      (itr.payments as Array<{ paymentStatus?: string }>).some(
        (p) => String(p.paymentStatus ?? '').toLowerCase() === 'success'
      ));

  if (!hasPay) return 'PENDING';
  return 'PAID';
}

export function isCompletedStatus(status: string | undefined | null): boolean {
  return normalizeDisplayStatus(status) === 'COMPLETED';
}

export function canAssignItr(itr: {
  status?: string;
  hasSuccessfulPayment?: boolean;
  assignedProfessionalName?: string;
}): boolean {
  if (isCompletedStatus(itr.status)) return false;
  if (itr.assignedProfessionalName) return false;
  return (
    itr.hasSuccessfulPayment === true ||
    itr.status === 'PAID' ||
    itr.status === 'IN_PROGRESS'
  );
}
