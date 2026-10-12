import type {MainContainerProps} from '../../types/MainContainer'

const ITRMainContainer = ({ children }: MainContainerProps) => {
  return (
    <div className="mx-auto w-full max-w-[1800px] bg-gray-950">
      {children}
    </div>
  );
};

export default ITRMainContainer;
