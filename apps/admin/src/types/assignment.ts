import type { Professional } from './professional';
import type { User } from './auth';
import type { ITRWithDetails } from './itr';

export type AssignmentStatus = 'assigned' | 'in_progress' | 'completed' | 'rejected';

export type AssignmentPriority = 'low' | 'normal' | 'high' | 'urgent';

export interface Assignment {
    id: number;
    itrId: number;
    orderId?: string;
    userId: number;
    professionalId: number;
    assignedBy: number;
    assignmentDate: string;
    status: AssignmentStatus;
    priority: AssignmentPriority;
    dueDate: string;
    completedAt?: string;
    notes?: string;
    createdAt: string;
    updatedAt: string;
    itr?: Partial<ITRWithDetails>;
    professional?: Partial<Professional>;
    user?: Partial<User>;
    assignedByUser?: Partial<User>;
}

export interface CreateAssignmentPayload {
    itrId: number;
    professionalId: number;
}

export interface UpdateAssignmentPayload {
    assignmentId: number;
    status?: AssignmentStatus;
    priority?: AssignmentPriority;
    dueDate?: string;
    notes?: string;
    professionalId?: number;
}
