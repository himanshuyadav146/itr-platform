import { Link } from 'react-router-dom';
import StepCard from './StepCard';
import WhyCard from './WhyCard';
import { UIStringConstants } from '../../utils/stringConstant';
import { HOME_LINKS } from '../../utils/links';

const Home = () => {
  return (
    <main className="bg-gray-950 min-h-screen">

      {/* HERO */}
      <section className="px-4 py-16 sm:px-6 lg:px-8">
        <div className="max-w-3xl">
          <h1 className="text-3xl font-bold tracking-tight text-white sm:text-4xl lg:text-5xl">
            {UIStringConstants.aswtf}
            <span className="block text-white">
              {UIStringConstants.yitr}
            </span>
          </h1>

          <p className="mt-6 text-base leading-relaxed text-gray-400 sm:text-lg">
            {UIStringConstants.description}
          </p>

          {/* CTA */}
          <div className="mt-10 flex flex-col gap-4 sm:flex-row sm:items-center">
            <Link
              to={HOME_LINKS.startFiling}
              className="inline-flex items-center justify-center rounded-lg bg-white text-black px-8 py-3 text-base font-semibold hover:bg-gray-200 transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-white"
            >
              {UIStringConstants.startFilling}
            </Link>

            <span className="text-sm text-gray-400">
              {UIStringConstants.noCreditCard}
            </span>
          </div>
        </div>
      </section>

      {/* HOW IT WORKS */}
      <section className="bg-gray-900 py-16">
        <div className="px-4 sm:px-6 lg:px-8">
          <h2 className="text-center text-3xl font-semibold text-white">
            {UIStringConstants.howItWorks}
          </h2>

          <div className="mt-14 grid gap-8 sm:grid-cols-2 lg:grid-cols-4">
            <StepCard step="01" title={UIStringConstants.startFilling}>
              {UIStringConstants.Afbqif}
            </StepCard>

            <StepCard step="02" title={UIStringConstants.choosePackage}>
              {UIStringConstants.selectPackage}
            </StepCard>

            <StepCard step="03" title={UIStringConstants.fillDetails}>
              {UIStringConstants.reviewReturn}
            </StepCard>

            <StepCard step="04" title={UIStringConstants.doPayment}>
              {UIStringConstants.makeSecurePayment}
            </StepCard>
          </div>
        </div>
      </section>

      {/* WHY US */}
      <section className="bg-gray-950 py-20">
        <div className="px-4 sm:px-6 lg:px-8">
          <h2 className="text-center text-3xl font-semibold text-white">
            {UIStringConstants.whyChooseUs}
          </h2>

          <div className="mt-12 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
            <WhyCard>{UIStringConstants.cleanInterface}</WhyCard>
            <WhyCard>{UIStringConstants.dataSecurity}</WhyCard>
            <WhyCard>{UIStringConstants.designedForUsers}</WhyCard>
          </div>
        </div>
      </section>

    </main>
  );
};

export default Home;
