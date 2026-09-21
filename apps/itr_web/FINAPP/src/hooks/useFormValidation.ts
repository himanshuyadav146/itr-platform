import { useState, useCallback } from 'react';
import { validateForm, hasErrors } from '../utils/validation';
import type { ValidationRule, ValidationError } from '../utils/validation';

interface UseFormValidationOptions {
  onSuccess?: () => void;
  onError?: (errors: ValidationError) => void;
}

/**
 * Custom hook for form validation
 * Handles form state, validation, and submission logic
 */
export const useFormValidation = <T extends Record<string, any>>(
  initialState: T,
  validationRules: (formData: T) => ValidationRule[],
  options?: UseFormValidationOptions
) => {
  const [formData, setFormData] = useState<T>(initialState);
  const [errors, setErrors] = useState<ValidationError>({});
  const [loading, setLoading] = useState(false);

  const handleChange = useCallback(
    (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) => {
      const { name, value } = e.target;
      setFormData(prev => ({
        ...prev,
        [name]: value,
      }));
      // Clear error for this field when user starts typing
      if (errors[name]) {
        setErrors(prev => {
          const newErrors = { ...prev };
          delete newErrors[name];
          return newErrors;
        });
      }
    },
    [errors]
  );

  const validate = useCallback((): boolean => {
    const rules = validationRules(formData);
    const newErrors = validateForm(rules);
    setErrors(newErrors);

    if (!hasErrors(newErrors) && options?.onSuccess) {
      options.onSuccess();
    } else if (hasErrors(newErrors) && options?.onError) {
      options.onError(newErrors);
    }

    return !hasErrors(newErrors);
  }, [formData, validationRules, options]);

  const handleSubmit = useCallback(
    async (onSubmitCallback: (data: T) => Promise<void> | void) => {
      return async (e: React.FormEvent) => {
        e.preventDefault();
        if (!validate()) return;

        setLoading(true);
        try {
          await onSubmitCallback(formData);
        } finally {
          setLoading(false);
        }
      };
    },
    [formData, validate]
  );

  const reset = useCallback(() => {
    setFormData(initialState);
    setErrors({});
  }, [initialState]);

  return {
    formData,
    errors,
    loading,
    setFormData,
    setErrors,
    setLoading,
    handleChange,
    validate,
    handleSubmit,
    reset,
  };
};
