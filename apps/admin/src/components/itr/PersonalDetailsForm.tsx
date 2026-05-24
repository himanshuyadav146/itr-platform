import { useState } from 'react';
import { Box, Button, Alert, CircularProgress, Grid } from '@mui/material';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { personalDetailsApi } from '../../api/personalDetails';
import type { PersonalDetails } from '../../api/personalDetails';
import { FormField } from '../common/FormField';
import { useAppDispatch } from '../../store/hooks';
import { addNotification } from '../../store/slices/uiSlice';

const personalDetailsSchema = z.object({
    FirstName: z.string().min(1, 'First name is required'),
    MiddleName: z.string().optional(),
    LastName: z.string().min(1, 'Last name is required'),
    DateOfBirth: z.string().optional(),
    Gender: z.string().optional(),
    Email: z.string().email('Invalid email').optional().or(z.literal('')),
    MobileNumber: z.string().optional(),
    AadharNumber: z.string().optional(),
    Address: z.string().optional(),
    City: z.string().optional(),
    State: z.string().optional(),
    PinCode: z.string().optional(),
    Occupation: z.string().optional(),
    EmployerName: z.string().optional(),
    EmployerAddress: z.string().optional(),
    BankName: z.string().optional(),
    BankAccountNumber: z.string().optional(),
    BankIFSC: z.string().optional(),
});

type PersonalDetailsFormData = z.infer<typeof personalDetailsSchema>;

interface PersonalDetailsFormProps {
    userId: number;
    panNumber: string;
    initialData?: PersonalDetails;
    onCancel?: () => void;
}

export const PersonalDetailsForm = ({ userId, panNumber, initialData, onCancel }: PersonalDetailsFormProps) => {
    const [error, setError] = useState<string | null>(null);
    const dispatch = useAppDispatch();
    const queryClient = useQueryClient();

    const {
        register,
        handleSubmit,
        formState: { errors, isSubmitting },
    } = useForm<PersonalDetailsFormData>({
        resolver: zodResolver(personalDetailsSchema),
        defaultValues: initialData || {},
    });

    const updateMutation = useMutation({
        mutationFn: (data: Partial<PersonalDetails>) => {
            return personalDetailsApi.updatePersonalDetails(userId, panNumber, data);
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['personalDetails', userId, panNumber] });
            dispatch(
                addNotification({
                    message: 'Personal details updated successfully',
                    type: 'success',
                })
            );
            if (onCancel) onCancel();
        },
        onError: (err: any) => {
            setError(err.response?.data?.message || 'Failed to update personal details');
        },
    });

    const onSubmit = async (data: PersonalDetailsFormData) => {
        setError(null);
        await updateMutation.mutateAsync(data);
    };

    return (
        <Box component="form" onSubmit={handleSubmit(onSubmit)}>
            {error && (
                <Alert severity="error" sx={{ mb: 2 }}>
                    {error}
                </Alert>
            )}

            <Grid container spacing={2}>
                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('FirstName')}
                        label="First Name"
                        error={!!errors.FirstName}
                        helperText={errors.FirstName?.message}
                        required
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('MiddleName')}
                        label="Middle Name"
                        error={!!errors.MiddleName}
                        helperText={errors.MiddleName?.message}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('LastName')}
                        label="Last Name"
                        error={!!errors.LastName}
                        helperText={errors.LastName?.message}
                        required
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                    <FormField
                        {...register('DateOfBirth')}
                        label="Date of Birth"
                        fieldType="date"
                        error={!!errors.DateOfBirth}
                        helperText={errors.DateOfBirth?.message}
                        InputLabelProps={{ shrink: true }}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 6 }}>
                    <FormField
                        {...register('Gender')}
                        label="Gender"
                        fieldType="select"
                        options={[
                            { value: 'Male', label: 'Male' },
                            { value: 'Female', label: 'Female' },
                            { value: 'Other', label: 'Other' },
                        ]}
                        error={!!errors.Gender}
                        helperText={errors.Gender?.message}
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                    <FormField
                        {...register('Email')}
                        label="Email"
                        fieldType="email"
                        error={!!errors.Email}
                        helperText={errors.Email?.message}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 6 }}>
                    <FormField
                        {...register('MobileNumber')}
                        label="Mobile Number"
                        fieldType="tel"
                        error={!!errors.MobileNumber}
                        helperText={errors.MobileNumber?.message}
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                    <FormField
                        {...register('AadharNumber')}
                        label="Aadhar Number"
                        error={!!errors.AadharNumber}
                        helperText={errors.AadharNumber?.message}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 6 }}>
                    <FormField
                        {...register('Occupation')}
                        label="Occupation"
                        error={!!errors.Occupation}
                        helperText={errors.Occupation?.message}
                    />
                </Grid>

                <Grid size={{ xs: 12 }}>
                    <FormField
                        {...register('Address')}
                        label="Address"
                        fieldType="textarea"
                        error={!!errors.Address}
                        helperText={errors.Address?.message}
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('City')}
                        label="City"
                        error={!!errors.City}
                        helperText={errors.City?.message}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('State')}
                        label="State"
                        error={!!errors.State}
                        helperText={errors.State?.message}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('PinCode')}
                        label="Pin Code"
                        error={!!errors.PinCode}
                        helperText={errors.PinCode?.message}
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 6 }}>
                    <FormField
                        {...register('EmployerName')}
                        label="Employer Name"
                        error={!!errors.EmployerName}
                        helperText={errors.EmployerName?.message}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 6 }}>
                    <FormField
                        {...register('EmployerAddress')}
                        label="Employer Address"
                        error={!!errors.EmployerAddress}
                        helperText={errors.EmployerAddress?.message}
                    />
                </Grid>

                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('BankName')}
                        label="Bank Name"
                        error={!!errors.BankName}
                        helperText={errors.BankName?.message}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('BankAccountNumber')}
                        label="Bank Account Number"
                        error={!!errors.BankAccountNumber}
                        helperText={errors.BankAccountNumber?.message}
                    />
                </Grid>
                <Grid size={{ xs: 12, md: 4 }}>
                    <FormField
                        {...register('BankIFSC')}
                        label="Bank IFSC Code"
                        error={!!errors.BankIFSC}
                        helperText={errors.BankIFSC?.message}
                    />
                </Grid>
            </Grid>

            <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
                <Button
                    type="submit"
                    variant="contained"
                    disabled={isSubmitting || updateMutation.isPending}
                >
                    {isSubmitting || updateMutation.isPending ? (
                        <CircularProgress size={24} />
                    ) : (
                        'Save Changes'
                    )}
                </Button>
                {onCancel && (
                    <Button variant="outlined" onClick={onCancel}>
                        Cancel
                    </Button>
                )}
            </Box>
        </Box>
    );
};
