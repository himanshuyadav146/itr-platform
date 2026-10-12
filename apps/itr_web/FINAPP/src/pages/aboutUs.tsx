const AboutUs = () => {
  return (
    <main className="bg-gray-950 text-gray-100 min-h-screen">

      {/* HERO SECTION */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 opacity-95" />

        <div className="relative mx-auto px-4 py-10 sm:px-6 lg:px-8">
          <div className="max-w-3xl">
            <h1 className="text-4xl font-bold leading-tight tracking-tight text-white sm:text-5xl">
              Welcome to <span className="text-gray-400">FinApp - Next Gen</span>
            </h1>

            <p className="mt-6 text-lg leading-relaxed text-gray-400">
              FinApp - Next Gen is India’s trusted digital platform for income tax filing
              and advisory — built for individuals, salaried professionals, and
              growing businesses.
            </p>
            <p className="mt-4 text-sm text-gray-500">
              On Google Play, FinApp - Next Gen is offered by FinNextGen.
            </p>
          </div>
        </div>
      </section>

      {/* WHAT WE DO */}
      <section className="py-10">
        <div className="mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid gap-10 lg:grid-cols-2 lg:items-center">

            {/* TEXT */}
            <div>
              <h2 className="text-3xl font-semibold tracking-tight text-white">
                What We Do
              </h2>

              <p className="mt-5 text-base leading-relaxed text-gray-400">
                Through our secure and easy-to-use platform, users upload their
                tax documents which are reviewed and filed by experienced
                Chartered Accountants.
              </p>

              <p className="mt-4 text-base leading-relaxed text-gray-400">
                From start to finish — filing, tracking, follow-ups, and
                support — everything is handled with speed, transparency,
                and accountability.
              </p>
            </div>

            {/* FEATURE CARDS */}
            <div className="grid gap-4 sm:grid-cols-2">
              {[
                'Secure document upload',
                'CA-reviewed filings',
                'Live status tracking',
                'Timely compliance',
              ].map((item) => (
                <div
                  key={item}
                  className="rounded-lg border border-gray-800 bg-gray-900 p-6 shadow-sm transition hover:shadow-md hover:border-gray-700"
                >
                  <div className="flex items-start gap-3">
                    <span className="mt-1 inline-block h-3 w-3 rounded-full bg-white" />
                    <p className="text-sm font-medium text-gray-300">
                      {item}
                    </p>
                  </div>
                </div>
              ))}
            </div>

          </div>
        </div>
      </section>

      {/* MISSION */}
      <section className="bg-gray-900 py-10">
        <div className="mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid gap-12 lg:grid-cols-2 lg:items-center">

            <div>
              <h2 className="text-3xl font-semibold tracking-tight text-white">
                Our Mission
              </h2>

              <p className="mt-5 text-base leading-relaxed text-gray-400">
                Our mission is to deliver a stress-free, tech-enabled tax filing
                experience with full legal compliance and enterprise-grade
                data security.
              </p>

              <p className="mt-4 text-base leading-relaxed text-gray-400">
                We remove confusion, reduce effort, and help users file their
                taxes with confidence — no jargon, just clear results.
              </p>
            </div>

            {/* MISSION CARD */}
            <div className="rounded-lg bg-gray-800 border border-gray-700 p-10">
              <ul className="space-y-5 text-sm text-gray-300">
                <li>✔ Transparency at every step</li>
                <li>✔ Speed without compromising accuracy</li>
                <li>✔ Secure & compliant systems</li>
                <li>✔ Human support backed by technology</li>
              </ul>
            </div>

          </div>
        </div>
      </section>

    </main>
  );
};

export default AboutUs;
