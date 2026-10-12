import Block from "../components/Block";
const PrivacyPolicy = () => {
  return (
    <main className="bg-gray-950 text-gray-100 min-h-screen">

      {/* PAGE HEADER */}
      <section className="border-b border-gray-800 bg-gray-900">
        <div className="mx-auto max-w-5xl px-4 py-10 sm:px-6 lg:px-8">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl text-white">
            Privacy Policy
          </h1>
          <p className="mt-2 text-sm text-gray-400">
            Effective Date: <span className="font-medium">01 July 2025</span>
          </p>

          <p className="mt-4 max-w-3xl text-base leading-relaxed text-gray-400">
            <span className="text-gray-300 font-medium">FinApp - Next Gen</span> is our mobile
            application and related services. These services are operated by{' '}
            <span className="text-gray-300 font-medium">FinNextGen</span>.
          </p>
          <p className="mt-3 max-w-3xl text-base leading-relaxed text-gray-400">
            This Privacy Policy explains how we collect, use, store, and protect your personal
            information when you use FinApp - Next Gen, our website (including allindiaitr.in),
            and related services.
          </p>
        </div>
      </section>

      {/* CONTENT */}
      <section className="py-10">
        <div className="mx-auto max-w-5xl px-4 sm:px-6 lg:px-8">
          <div className="space-y-6 rounded-lg bg-gray-900 p-8 border border-gray-800 sm:p-12">

            <Block
              title="Who operates this app"
              content={
                <ul className="list-disc space-y-2 pl-5">
                  <li>
                    <strong>App name:</strong> FinApp - Next Gen
                  </li>
                  <li>
                    <strong>Developer / operator:</strong> FinNextGen
                  </li>
                </ul>
              }
            />

            <Block
              title="1. Information We Collect"
              content={
                <>
                  <ul className="list-disc space-y-2 pl-5">
                    <li>
                      <strong>Personal Information:</strong> Full name, email
                      address, mobile number, PAN, Aadhaar, address, date of
                      birth, etc.
                    </li>
                    <li>
                      <strong>Financial Data:</strong> Bank details, UPI IDs,
                      transaction references (payment details processed securely
                      via third-party gateways).
                    </li>
                    <li>
                      <strong>Tax Information:</strong> Income details,
                      deductions, tax filings, and related records.
                    </li>
                    <li>
                      <strong>Technical Information:</strong> IP address, device
                      type, browser details, and access logs.
                    </li>
                  </ul>
                </>
              }
            />

            <Block
              title="2. How We Use Your Information"
              content={
                <ul className="list-disc space-y-2 pl-5">
                  <li>To provide and manage tax filing and advisory services</li>
                  <li>To process payments securely using trusted gateways</li>
                  <li>To comply with legal and regulatory requirements</li>
                  <li>To send important notifications, reminders, and updates</li>
                  <li>To enhance user experience and platform performance</li>
                </ul>
              }
            />

            <Block
              title="3. Payment & Financial Data"
              content={
                <>
                  <p>
                    We use third-party payment gateways such as Razorpay,
                    CCAvenue, and Paytm to process payments securely.
                  </p>
                  <p className="mt-3">
                    Your card or UPI information is <strong>never stored</strong>{' '}
                    on our servers. We may receive limited payment metadata such
                    as transaction status and confirmation.
                  </p>
                  <p className="mt-3">
                    All financial data is encrypted and processed in compliance
                    with PCI-DSS standards and RBI guidelines.
                  </p>
                </>
              }
            />

            <Block
              title="4. Data Security"
              content="We implement industry-standard security measures including
              256-bit SSL encryption, firewalls, access controls, and encrypted
              storage to safeguard your data from unauthorized access."
            />

            <Block
              title="5. Disclosure of Information"
              content={
                <ul className="list-disc space-y-2 pl-5">
                  <li>When required by Indian law or government authorities</li>
                  <li>With payment processors for transaction completion</li>
                  <li>With legal professionals during dispute or fraud handling</li>
                </ul>
              }
            />

            <Block
              title="6. Cookies & Tracking"
              content={
                <>
                  <p>
                    We use cookies and similar technologies to:
                  </p>
                  <ul className="mt-2 list-disc space-y-2 pl-5">
                    <li>Personalize your dashboard and experience</li>
                    <li>Analyze usage and improve platform performance</li>
                  </ul>
                  <p className="mt-3">
                    You may manage or disable cookies through your browser
                    settings at any time.
                  </p>
                </>
              }
            />

            <Block
              title="7. Your Rights"
              content={
                <ul className="list-disc space-y-2 pl-5">
                  <li>Access and review your personal data</li>
                  <li>Request corrections to inaccurate information</li>
                  <li>Withdraw consent where legally applicable</li>
                  <li>Request deletion of data (subject to legal obligations)</li>
                </ul>
              }
            />

            <Block
              title="8. Changes to This Policy"
              content="We may update this Privacy Policy periodically. Any changes
              will be posted on this page with an updated effective date."
            />

            <Block
              title="9. Refund & Return Policy"
              content={
                <>
                  <p>
                    As FinNextGen provides digital tax services through FinApp - Next Gen,
                    refunds are not applicable once the service has started or a tax return has
                    been filed.
                  </p>
                  <p className="mt-3">
                    Refunds may be considered only if:
                  </p>
                  <ul className="mt-2 list-disc space-y-2 pl-5">
                    <li>Payment failure due to technical issues</li>
                    <li>Payment received but not reflected in our system</li>
                  </ul>
                  <p className="mt-3">
                    To request a refund, contact{' '}
                    <a
                      href="mailto:support@allindiaitr.in"
                      className="font-medium text-blue-600 hover:underline"
                    >
                      support@allindiaitr.in
                    </a>{' '}
                    within 7 working days along with transaction details.
                  </p>
                </>
              }
            />

          </div>
        </div>
      </section>

    </main>
  );
};

export default PrivacyPolicy;
