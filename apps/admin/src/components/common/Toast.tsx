import { useEffect } from 'react';
import { Snackbar, Alert } from '@mui/material';
import { useAppSelector, useAppDispatch } from '../../store/hooks';
import { removeNotification } from '../../store/slices/uiSlice';

export const Toast = () => {
  const dispatch = useAppDispatch();
  const notifications = useAppSelector((state) => state.ui.notifications);
  const currentNotification = notifications[0];

  const handleClose = () => {
    if (currentNotification) {
      dispatch(removeNotification(currentNotification.id));
    }
  };

  useEffect(() => {
    if (currentNotification && currentNotification.duration) {
      const timer = setTimeout(() => {
        handleClose();
      }, currentNotification.duration);

      return () => clearTimeout(timer);
    }
  }, [currentNotification]);

  return (
    <Snackbar
      open={!!currentNotification}
      autoHideDuration={currentNotification?.duration || 6000}
      onClose={handleClose}
      anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
    >
      {currentNotification && (
        <Alert
          onClose={handleClose}
          severity={currentNotification.type}
          sx={{ width: '100%' }}
        >
          {currentNotification.message}
        </Alert>
      )}
    </Snackbar>
  );
};

