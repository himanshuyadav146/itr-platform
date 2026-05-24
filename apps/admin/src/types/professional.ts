export interface ProfessionalStatistics {
    assignmentsCount: number;
    activeAssignmentsCount: number;
    completedAssignmentsCount: number;
}

export interface Professional {
    id: number;
    firstName: string;
    lastName: string;
    email: string;
    mobile?: string;
    qualification?: string;
    experience?: number;
    specialization?: string;
    licenseNumber?: string;
    isActive: boolean;
    createdAt: string;
    updatedAt: string;
    statistics?: ProfessionalStatistics;

    // Computed helpers (optional)
    name?: string;
    occupation?: string; // Mapped from specialization or similar
}
