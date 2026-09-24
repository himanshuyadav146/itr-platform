export const NAV_LINKS = [
  { label: 'Associates', to: '/services' },
];

export const CTA_LINK = {
  label: 'Sign Up',
  to: '/sign-up',
};

export const FOOTER_LINKS =[
    { label: 'Privacy Policy', to: '/privacy-policy' },
    { label: 'Terms & Conditions', to: '/term-and-condition' },
    { label: 'About Us', to: '/about-us' },
    { label: 'Contact Us', to: '/contact-us' },
    { label: 'Join as associate', to: '/associate-register' },
]

export const HOME_LINKS ={
    startFiling: '/services',
}

export const ADMIN_LOGIN_URL =
  import.meta.env.VITE_ADMIN_LOGIN_URL || 'https://allindiaitr.in/admin/login';
