import { Routes, Route, Navigate } from 'react-router-dom';
import { PrivateRoute } from './PrivateRoute';
import { UserRole } from '../types/enums';

// Pages
import LoginPage from '../pages/LoginPage';
import RegisterPage from '../pages/RegisterPage';
import ForgotPasswordPage from '../pages/ForgotPasswordPage';
import DashboardPage from '../pages/DashboardPage';
import UsersPage from '../pages/UsersPage';
import UserDetailPage from '../pages/UserDetailPage';
import ITRsPage from '../pages/ITRsPage';
import ITRDetailPage from '../pages/ITRDetailPage';
import ProfessionalsPage from '../pages/ProfessionalsPage';
import PackagesPage from '../pages/PackagesPage';
import PackageFormPage from '../pages/PackageFormPage';
import NotificationTemplatesPage from '../pages/NotificationTemplatesPage';
import NotificationTemplateFormPage from '../pages/NotificationTemplateFormPage';
import DeleteAccountPage from '../pages/DeleteAccountPage';
import NotFoundPage from '../pages/NotFoundPage';

export const AppRoutes = () => {
  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/register" element={<RegisterPage />} />
      <Route path="/forgot-password" element={<ForgotPasswordPage />} />
      <Route path="/delete-account" element={<DeleteAccountPage />} />

      <Route
        path="/dashboard"
        element={
          <PrivateRoute>
            <DashboardPage />
          </PrivateRoute>
        }
      />

      <Route
        path="/users"
        element={
          <PrivateRoute allowedRoles={[UserRole.ADMIN]}>
            <UsersPage />
          </PrivateRoute>
        }
      />

      <Route
        path="/users/:id"
        element={
          <PrivateRoute allowedRoles={[UserRole.ADMIN]}>
            <UserDetailPage />
          </PrivateRoute>
        }
      />

      <Route
        path="/itrs"
        element={
          <PrivateRoute>
            <ITRsPage />
          </PrivateRoute>
        }
      />

      <Route
        path="/itrs/:id"
        element={
          <PrivateRoute>
            <ITRDetailPage />
          </PrivateRoute>
        }
      />

      <Route
        path="/professionals"
        element={
          <PrivateRoute>
            <ProfessionalsPage />
          </PrivateRoute>
        }
      />

      <Route
        path="/packages"
        element={
          <PrivateRoute allowedRoles={[UserRole.ADMIN]}>
            <PackagesPage />
          </PrivateRoute>
        }
      />
      <Route
        path="/packages/new"
        element={
          <PrivateRoute allowedRoles={[UserRole.ADMIN]}>
            <PackageFormPage />
          </PrivateRoute>
        }
      />
      <Route
        path="/packages/:id"
        element={
          <PrivateRoute allowedRoles={[UserRole.ADMIN]}>
            <PackageFormPage />
          </PrivateRoute>
        }
      />

      <Route
        path="/notification-templates"
        element={
          <PrivateRoute allowedRoles={[UserRole.ADMIN]}>
            <NotificationTemplatesPage />
          </PrivateRoute>
        }
      />
      <Route
        path="/notification-templates/:id"
        element={
          <PrivateRoute allowedRoles={[UserRole.ADMIN]}>
            <NotificationTemplateFormPage />
          </PrivateRoute>
        }
      />

      <Route path="/" element={<Navigate to="/dashboard" replace />} />
      <Route path="*" element={<NotFoundPage />} />
    </Routes>
  );
};

