import Block from "../components/Block";
const TermsAndConditions = () => {
  return (
    <main className="bg-gray-950 text-gray-100 min-h-screen">

      {/* HERO / PAGE HEADER */}
      <section className="border-b border-gray-800 bg-gray-900">
        <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:px-8">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl text-white">
            Terms & Conditions
          </h1>
          <p className="mt-3 max-w-3xl text-base leading-relaxed text-gray-400">
            <span className="text-gray-300 font-medium">FinApp - Next Gen</span> is our mobile application and related services.
            Payment and related services are provided by{' '}
            <span className="text-gray-300 font-medium">FinNextGen</span>.
          </p>
          <p className="mt-3 max-w-3xl text-base leading-relaxed text-gray-400">
            These Terms &amp; Conditions govern the use of FinApp - Next Gen payment services.
            By proceeding with any transaction, you agree to the terms outlined below.
          </p>
        </div>
      </section>

      {/* CONTENT */}
      <section className="py-10">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <div className="space-y-10 rounded-lg bg-gray-900 p-8 border border-gray-800 sm:p-12">

            <Block
              title="1. Introduction"
              content="These Terms and Conditions apply to your use of our payment gateway services. By accessing or using the service, you confirm that you have read, understood, and agreed to be bound by these Terms."
            />

            <Block
              title="2. Payment Processing"
              content="All payments are processed securely using industry-standard encryption, authentication, and compliance protocols. Transactions are subject to verification and authorization by payment partners and financial institutions."
            />

            <Block
              title="3. Fees and Charges"
              content="Transaction fees may apply based on the selected payment method. By completing a payment, you acknowledge and accept all applicable fees associated with the transaction."
            />

            <Block
              title="4. Refunds and Cancellations"
              content="Refunds and cancellations are governed by our Refund Policy. Users are advised to review the policy carefully before initiating any transaction."
            />

            <Block
              title="5. Privacy & Data Security"
              content="We prioritize data security and privacy. Personal and financial information is handled in accordance with our Privacy Policy and protected using robust security practices."
            />

            <Block
              title="6. Limitation of Liability"
              content="FinNextGen shall not be liable for any loss, damage, or unauthorized transactions resulting from misuse of credentials, third-party failures, or technical issues beyond our reasonable control."
            />

            <Block
              title="7. Changes to Terms"
              content="We reserve the right to modify these Terms at any time. Continued use of our services after updates are published constitutes acceptance of the revised Terms."
            />

            <div>
              <h2 className="text-lg font-semibold">8. Contact Us</h2>
              <p className="mt-2 text-sm leading-relaxed text-slate-600">
                For questions or concerns regarding these Terms, please contact us at{' '}
                <a
                  href="mailto:support@allindiaitr.in"
                  className="font-medium text-blue-600 hover:underline"
                >
                     finnextgen2026@gmail.com                </a>
                .
              </p>
            </div>

          </div>
        </div>
      </section>

    </main>
  );
};

export default TermsAndConditions;
