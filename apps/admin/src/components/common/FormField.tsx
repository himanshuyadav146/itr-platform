import { TextField, MenuItem } from '@mui/material';
import type { TextFieldProps } from '@mui/material';
import { forwardRef } from 'react';

export type FormFieldType = 'text' | 'select' | 'date' | 'number' | 'email' | 'tel' | 'textarea';

interface FormFieldProps extends Omit<TextFieldProps, 'type'> {
    fieldType?: FormFieldType;
    options?: Array<{ value: string | number; label: string }>;
}

export const FormField = forwardRef<HTMLDivElement, FormFieldProps>(
    ({ fieldType = 'text', options, ...props }, ref) => {
        const isSelect = fieldType === 'select';
        const isTextarea = fieldType === 'textarea';

        return (
            <TextField
                ref={ref}
                select={isSelect}
                type={isTextarea ? undefined : fieldType === 'text' ? 'text' : fieldType}
                multiline={isTextarea}
                rows={isTextarea ? 4 : undefined}
                fullWidth
                margin="normal"
                {...props}
            >
                {isSelect &&
                    options?.map((option) => (
                        <MenuItem key={option.value} value={option.value}>
                            {option.label}
                        </MenuItem>
                    ))}
            </TextField>
        );
    }
);

FormField.displayName = 'FormField';
