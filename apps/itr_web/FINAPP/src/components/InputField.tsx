import React from 'react';
import clsx from 'clsx';
import type InputFieldProps from '../types/inputField';

const InputField = React.forwardRef<HTMLInputElement, InputFieldProps>(
  (
    {
      label,
      error,
      helperText,
      className,
      containerClassName,
      id,
      ...props
    },
    ref
  ) => {
    const inputId = id || props.name;

    return (
      <div className={clsx('w-full', containerClassName)}>
        {label && (
          <label
            htmlFor={inputId}
            className="mb-1.5 block text-sm font-medium text-white"
          >
            {label}
          </label>
        )}

        <input
          ref={ref}
          id={inputId}
          className={clsx(
            'w-full rounded-xl border px-3 py-2.5 text-sm bg-gray-800 text-white',
            'placeholder:text-gray-500',
            'focus:outline-none focus:border-gray-500',
            error
              ? 'border-red-700 focus:border-red-700'
              : 'border-gray-700 hover:border-gray-600',
            className
          )}
          {...props}
        />

        {error ? (
          <p className="mt-1 text-xs font-medium text-red-400">
            {error}
          </p>
        ) : helperText ? (
          <p className="mt-1 text-xs text-gray-400">
            {helperText}
          </p>
        ) : null}
      </div>
    );
  }
);

InputField.displayName = 'InputField';

export default InputField;
