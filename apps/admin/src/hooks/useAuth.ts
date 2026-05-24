import { useAppSelector, useAppDispatch } from '../store/hooks';
import { login, logout, setUser, updateToken } from '../store/slices/authSlice';
import type { User } from '../types';

export const useAuth = () => {
  const dispatch = useAppDispatch();
  const { user, token, isAuthenticated, role } = useAppSelector((state) => state.auth);

  return {
    user,
    token,
    isAuthenticated,
    role,
    login: (user: User, token: string) => dispatch(login({ user, token })),
    logout: () => dispatch(logout()),
    setUser: (user: User) => dispatch(setUser(user)),
    updateToken: (token: string) => dispatch(updateToken(token)),
  };
};

