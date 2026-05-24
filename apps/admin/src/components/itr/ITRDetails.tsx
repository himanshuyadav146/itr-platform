import { Box, Button } from '@mui/material';
import { Edit as EditIcon, Assignment as AssignmentIcon } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import type { ITRWithDetails } from '../../types';
import { formatCurrency } from '../../utils/formatters';
import { usePermissions } from '../../hooks/usePermissions';
import { Permission } from '../../types/enums';
import { InfoCard } from '../common/InfoCard';
import { InfoRow } from '../common/InfoRow';
import { StatusChip } from '../common/StatusChip';

interface ITRDetailsProps {
  itr: ITRWithDetails;
  onEdit?: () => void;
  onAssign?: () => void;
  /** Show Assign button only when payment is successful (PAID or SUCCESS). Default false. */
  hasSuccessfulPayment?: boolean;
}

export const ITRDetails = ({ itr, onEdit, onAssign, hasSuccessfulPayment = false }: ITRDetailsProps) => {
  const navigate = useNavigate();
  const { hasPermission, role } = usePermissions();

  const handleEdit = () => {
    if (onEdit) {
      onEdit();
    } else {
      navigate(`/itrs/${itr.id}?edit=true`);
    }
  };

  const handleAssign = () => {
    if (onAssign) {
      onAssign();
    }
  };

  // Permission checks with logging for debugging
  const canAssign = hasPermission(Permission.ASSIGN_ITR);
  const canEdit = hasPermission(Permission.EDIT_ITR);

  // Type-safe admin check using enum instead of string literal
  const isAdmin = role === 'ADMIN';

  // Debug logging for production (can be viewed in browser console)
  console.log('[ITRDetails] Permission Check:', {
    itrId: itr.id,
    userRole: role,
    userRoleType: typeof role,
    canAssign,
    canEdit,
    isAdmin,
    timestamp: new Date().toISOString()
  });

  const actions = (
    <>
      {(canEdit || isAdmin) && (
        <Button
          size="small"
          variant="outlined"
          startIcon={<EditIcon />}
          onClick={handleEdit}
        >
          Edit
        </Button>
      )}
      {(canAssign || isAdmin) && hasSuccessfulPayment && (
        <Button
          size="small"
          variant="outlined"
          startIcon={<AssignmentIcon />}
          onClick={handleAssign}
        >
          Assign
        </Button>
      )}
    </>
  );

  return (
    <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 3 }}>
      <Box sx={{ flex: { xs: '1 1 100%', md: '1 1 calc(50% - 12px)' } }}>
        <InfoCard title="ITR Information" actions={actions}>
          <InfoRow label="ITR ID" value={itr.id} />
          <InfoRow label="Client Name" value={itr.clientName} />
          <InfoRow label="Financial Year" value={itr.financialYear} />
          <InfoRow label="PAN Number" value={itr.panNumber} />
          <InfoRow
            label="Status"
            value={<StatusChip status={itr.status || 'PENDING'} size="medium" />}
          />
          {itr.assignedProfessionalName && (
            <InfoRow label="Assigned To" value={itr.assignedProfessionalName} />
          )}
          {itr.acknowledgement_number && (
            <InfoRow label="Acknowledgement Number" value={itr.acknowledgement_number} />
          )}
          <InfoRow
            label="Created Date"
            value={itr.createdAt ? new Date(itr.createdAt).toLocaleDateString() : 'N/A'}
          />
        </InfoCard>
      </Box>

      {itr.sources && itr.sources.length > 0 && (
        <Box sx={{ flex: { xs: '1 1 100%', md: '1 1 calc(50% - 12px)' } }}>
          <InfoCard title="Income Sources">
            <Box sx={{ mt: 2 }}>
              {itr.sources.map((source) => (
                <Box key={source.id} sx={{ mb: 2, pb: 2, borderBottom: 1, borderColor: 'divider' }}>
                  <InfoRow label="Source Name" value={source.sourceName} />
                  <InfoRow label="Type" value={source.sourceType} />
                  <InfoRow label="Amount" value={formatCurrency(source.amount)} />
                </Box>
              ))}
            </Box>
          </InfoCard>
        </Box>
      )}
    </Box>
  );
};
