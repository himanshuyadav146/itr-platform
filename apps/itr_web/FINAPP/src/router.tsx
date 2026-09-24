import { createBrowserRouter } from 'react-router-dom';
import Layout from './components/layout/Layout';
import Home from './components/home/Home';
import AboutUs from './pages/aboutUs';
import TermsAndConditions from './pages/TermandCondition';
import PrivacyPolicy from './pages/PrivactPlociy';
import ContactUs from './pages/ContactUs';
import Signup from './pages/signUp';
import Login from './pages/Login';
import Dashboard from './pages/dashboard';
import Packages from './pages/Packages';
import PersonalDetails from './pages/PersonalDetails';
import DocumentUpload from './pages/DocumentUpload';
import Payment from './pages/Payment';
import AssociateRegister from './pages/AssociateRegister';
import Services from './pages/Services';
import Associates from './pages/Associates';
import AssociateDetail from './pages/AssociateDetail';
export const router = createBrowserRouter([
  {
    path: '/',
    element: <Layout />,
    children: [
      {
        index: true,
        element: <Home />,
      },
      {
        path: '/about-us',
        element: <AboutUs />,
      },
      {
        path: '/term-and-condition',
        element: <TermsAndConditions />,
      },{
        path: '/privacy-policy',
        element: <PrivacyPolicy />,
      },{
        path: '/contact-us',
        element: <ContactUs />,
      },
      {
        path: '/sign-up',
        element: <Signup />,
      },
      {
        path: '/login',
        element: <Login />,
      },
      {
        path: '/dashboard',
        element: <Dashboard />,
      },
      {
        path: '/packages',
        element: <Packages />,
      },
      {
        path: '/services',
        element: <Services />,
      },
      {
        path: '/associates',
        element: <Associates />,
      },
      {
        path: '/associates/:id',
        element: <AssociateDetail />,
      },
      {
        path: '/associate-register',
        element: <AssociateRegister />,
      },
      {
        path: '/personal-details',
        element: <PersonalDetails />,
      },
      {
        path: '/documents',
        element: <DocumentUpload />,
      },
      {
        path: '/payment',
        element: <Payment />,
      },
    ],
  },
]);
