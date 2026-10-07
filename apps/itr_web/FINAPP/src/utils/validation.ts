/**
 * Email validation regex pattern
 * Matches standard email format
 */
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/**
 * Mobile number validation regex pattern
 * Matches 10-digit Indian mobile numbers
 */
const MOBILE_REGEX = /^[6-9]\d{9}$/;

/**
 * Password strength validation
 * Requires: min 8 chars, at least 1 uppercase, 1 lowercase, 1 number, 1 special char
 */
const PASSWORD_REGEX = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$/;

export interface ValidationRule {
  field: string;
  value: any;
  rules: {
    required?: boolean;
    minLength?: number;
    maxLength?: number;
    pattern?: RegExp;
    custom?: (value: any) => boolean | string;
  };
}

export interface ValidationError {
  [key: string]: string;
}

/**
 * Validates a single field based on provided rules
 */
export const validateField = (
  value: any,
  rules: ValidationRule['rules'],
  fieldName: string
): string | null => {
  // Check required
  if (rules.required && (!value || value.trim() === '')) {
    return `${fieldName} is required`;
  }

  if (!value) return null;

  // Check minLength
  if (rules.minLength && value.length < rules.minLength) {
    return `${fieldName} must be at least ${rules.minLength} characters`;
  }

  // Check maxLength
  if (rules.maxLength && value.length > rules.maxLength) {
    return `${fieldName} must not exceed ${rules.maxLength} characters`;
  }

  // Check pattern
  if (rules.pattern && !rules.pattern.test(value)) {
    return `${fieldName} is invalid`;
  }

  // Check custom validator
  if (rules.custom) {
    const result = rules.custom(value);
    if (typeof result === 'string') return result;
    if (!result) return `${fieldName} validation failed`;
  }

  return null;
};

/**
 * Validates multiple fields at once
 */
export const validateForm = (
  validationRules: ValidationRule[]
): ValidationError => {
  const errors: ValidationError = {};

  validationRules.forEach((rule) => {
    const error = validateField(rule.value, rule.rules, rule.field);
    if (error) {
      errors[rule.field] = error;
    }
  });

  return errors;
};

/**
 * Predefined validators for common fields
 */
export const validators = {
  name: () => ({
    required: true,
    minLength: 2,
    maxLength: 50,
  }),

  email: () => ({
    required: true,
    pattern: EMAIL_REGEX,
  }),

  mobile: () => ({
    required: true,
    pattern: MOBILE_REGEX,
  }),

  password: () => ({
    required: true,
    minLength: 8,
    pattern: PASSWORD_REGEX,
  }),

  confirmPassword: (_: string, passwordValue?: string) => ({
    required: true,
    custom: (val: string) =>
      val === passwordValue ? true : 'Passwords do not match',
  }),

  pan: () => ({
    required: true,
    pattern: /^[A-Z]{5}[0-9]{4}[A-Z]{1}$/,
  }),

  gstin: () => ({
    required: true,
    pattern: /^\d{2}[A-Z]{5}\d{4}[A-Z]{1}[A-Z\d]{1}[Z]{1}[A-Z\d]{1}$/,
  }),

  aadhar: () => ({
    required: true,
    pattern: /^\d{12}$/,
  }),
};

/**
 * Helper function to check if form has any errors
 */
export const hasErrors = (errors: ValidationError): boolean => {
  return Object.keys(errors).length > 0;
};

/**
 * Helper function to get first error message
 */
export const getFirstError = (errors: ValidationError): string | null => {
  const errorKeys = Object.keys(errors);
  return errorKeys.length > 0 ? errors[errorKeys[0]] : null;
};
