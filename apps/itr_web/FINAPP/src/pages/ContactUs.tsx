const ContactUs = () => {
  return (
    <main className="bg-gray-950 text-gray-100 min-h-screen">

      {/* PAGE HEADER */}
      <section className="border-b border-gray-800 bg-gray-900">
        <div className="mx-auto max-w-6xl px-4 py-10 sm:px-6 lg:px-8">
          <h1 className="text-3xl font-bold tracking-tight sm:text-4xl text-white">
            Contact Us
          </h1>
          <p className="mt-3 max-w-3xl text-base text-gray-400">
            We're here to help you with tax filing, payments, and support.
            Reach out to us anytime — our experts are happy to assist.
          </p>
        </div>
      </section>

      {/* CONTENT */}
      <section className="py-10">
        <div className="mx-auto max-w-6xl px-4 sm:px-6 lg:px-8">
          <div className="grid gap-12 lg:grid-cols-2">

            {/* LEFT: APP DOWNLOAD */}
            <div className="rounded-lg bg-gray-900 border border-gray-800 p-8 sm:p-10">
              <h2 className="text-2xl font-semibold text-white">
                📱 Download Our App
              </h2>

              <p className="mt-4 text-sm leading-relaxed text-gray-400">
                Experience hassle-free income tax e-filing on the go with{' '}
                <span className="text-gray-300">FinApp - Next Gen</span> (offered by FinNextGen on Google Play).
                Download our mobile app to get expert support across India.
              </p>

              <div className="mt-8 flex flex-col gap-4 sm:flex-row">
                <a
                  href="#"
                  className="flex items-center justify-center rounded-lg
                             bg-white px-6 py-3 text-sm font-medium
                             text-black hover:bg-gray-200"
                >
                  Download for Android
                </a>

                <a
                  href="#"
                  className="flex items-center justify-center rounded-lg
                             border border-gray-700 px-6 py-3 text-sm
                             font-medium text-white hover:bg-gray-800"
                >
                  Download for iOS
                </a>
              </div>

              <p className="mt-4 text-xs text-gray-500">
                * App availability may vary by device and region.
              </p>
            </div>

            {/* RIGHT: CONTACT DETAILS */}
            <div className="rounded-lg bg-gray-900 border border-gray-800 p-8 sm:p-10">
              <h2 className="text-2xl font-semibold text-white">
                📍 Contact Details
              </h2>

              <div className="mt-6 space-y-4 text-sm text-gray-400">
                <p>
                  <strong className="text-gray-300">Address:</strong><br />
                  SA-18/127-3k, Maujahall Sarang Talave,<br />
                  Tapovan Aashram, Varanasi – 221007
                </p>

                <p>
                  <strong className="text-gray-300">Phone:</strong>{' '}
                  <a
                    href="tel:+919415555209"
                    className="text-white hover:underline"
                  >
                    +91-9415555209
                  </a>
                </p>

                <p>
                  <strong className="text-gray-300">Email:</strong>{' '}
                  <a
                    href="mailto:finnextgen2026@gmail.com"
                    className="text-white hover:underline"
                  >
                    finnextgen2026@gmail.com
                  </a>
                </p>

                <p>
                  <strong className="text-gray-300">Website:</strong>{' '}
                  <a
                    href="https://www.allindiaitr.in"
                    target="_blank"
                    rel="noreferrer"
                    className="text-white hover:underline"
                  >
                    www.allindiaitr.in
                  </a>
                </p>
              </div>
            </div>

          </div>
        </div>
      </section>

    </main>
  );
};

export default ContactUs;
