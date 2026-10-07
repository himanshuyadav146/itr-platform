import type { StepCardProps } from '../../types/Home';

const StepCard = ({ step, title, children }: StepCardProps) => {
  return (
    <div className="rounded-lg border border-gray-800 bg-gray-900 p-6">
      <span className="text-sm font-semibold text-white">
        {step}
      </span>
      <h3 className="mt-2 text-lg font-medium text-white">
        {title}
      </h3>
      <p className="mt-2 text-sm leading-relaxed text-gray-400">
        {children}
      </p>
    </div>
  );
};

export default StepCard;
