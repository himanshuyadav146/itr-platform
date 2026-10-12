import type TermBlockProps from "../types/block";

const Block = ({ title, content }: TermBlockProps) => {
  return (
    <div>
      <h2 className="text-lg font-semibold">{title}</h2>
      <p className="mt-2 text-sm leading-relaxed text-slate-600">
        {content}
      </p>
    </div>
  );
};

export default Block;