import { Link } from 'react-router-dom';
import { FOOTER_LINKS } from '../../utils/links';
const Footer = () => {
  return (
    <footer className="bg-[#0B1220] text-gray-400">
      <div className="px-4 py-10 sm:px-6 lg:px-8">
        
        {/* Top Section */}
        <div className="flex flex-col gap-8 md:flex-row md:items-start md:justify-between">
          
          {/* Brand */}
          <div>
            <h3 className="text-lg font-semibold text-white">
              FinApp - Next Gen
            </h3>
            <p className="mt-2 max-w-xs text-sm">
              Smart, secure and simple tax filing with FinApp - Next Gen — offered by FinNextGen.
            </p>
          </div>

          {/* Links */}
          <div className="grid grid-cols-2 gap-6 sm:grid-cols-4">
            {FOOTER_LINKS.map(link => (
              <FooterLink key={link.to} to={link.to} label={link.label} />
            ))}
          </div>
        </div>

        {/* Divider */}
        <div className="my-8 border-t border-gray-800" />

        {/* Bottom Section */}
        <div className="flex flex-col items-center justify-between gap-4 text-sm sm:flex-row">
          <p>
            © {new Date().getFullYear()} FinNextGen. All rights reserved.
          </p>

          <p className="text-gray-500">
            Made for modern taxpayers 🇮🇳
          </p>
        </div>
      </div>
    </footer>
  );
};

export default Footer;

/* Small reusable link component */
const FooterLink = ({ to, label }: { to: string; label: string }) => (
  <Link
    to={to}
    className="text-sm hover:text-white transition"
  >
    {label}
  </Link>
);
