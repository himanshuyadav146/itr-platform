import { useState } from 'react';
import { useParams, useSearchParams, useNavigate } from 'react-router-dom';
import { Box, Typography, Button, Tabs, Tab, Alert, AlertTitle } from '@mui/material';
import { ArrowBack as ArrowBackIcon } from '@mui/icons-material';
import { DashboardLayout } from '../components/layout/DashboardLayout';
import { LoadingSpinner } from '../components/common/LoadingSpinner';
import { useQuery, useQueryClient } from '@tanstack/react-query';
import { itrApi } from '../api/itr';
import { personalDetailsApi } from '../api/personalDetails';
import { documentsApi } from '../api/documents';
import type { Document } from '../api/documents';
import { DUMMY_DOCUMENT_PLACEHOLDER } from '../api/documents';
import type { ITRWithDetails } from '../types/itr';
import { ITREditForm } from '../components/itr/ITREditForm';
import { ITRDetails } from '../components/itr/ITRDetails';
import { ITRComments } from '../components/itr/ITRComments';
import { DocumentList } from '../components/documents/DocumentList';
import { DocumentViewer } from '../components/documents/DocumentViewer';
import { AssignProfessionalModal } from '../components/itr/AssignProfessionalModal';
import { PersonalDetailsForm } from '../components/itr/PersonalDetailsForm';
import { MarkITRCompleteForm } from '../components/itr/MarkITRCompleteForm';
import { InfoCard } from '../components/common/InfoCard';

/** Backend `documents.php?itrId=` expects itrDetails[].itrId, not personalDetailId (route id). */
function resolveBackendItrIdForDocuments(itr: ITRWithDetails | null | undefined): number {
  if (!itr) return 0;
  if (typeof itr.itrId === 'number' && itr.itrId > 0) return itr.itrId;
  const nested = (itr as { _itrDetails?: Array<{ itrId?: number; itr_id?: number }> })._itrDetails;
  const fromNested = nested?.[0]?.itrId ?? nested?.[0]?.itr_id;
  if (fromNested != null && Number(fromNested) > 0) return Number(fromNested);
  const raw = (itr as { _rawITRData?: { itrDetails?: Array<{ itrId?: number; itr_id?: number }> } })._rawITRData
    ?.itrDetails?.[0];
  const fromRaw = raw?.itrId ?? raw?.itr_id;
  if (fromRaw != null && Number(fromRaw) > 0) return Number(fromRaw);
  return 0;
}

const ITRDetailPage = () => {
  const { id } = useParams<{ id: string }>();
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const [assignModalOpen, setAssignModalOpen] = useState(false);
  const [viewerOpen, setViewerOpen] = useState(false);
  const [selectedDocument, setSelectedDocument] = useState<Document | null>(null);
  const [activeTab, setActiveTab] = useState(0);
  const itrId = id ? parseInt(id, 10) : 0;
  const isEditMode = searchParams.get('edit') === 'true';

  const queryClient = useQueryClient();

  // Fetch ITR from list API (as user mentioned "we can use last page data to show here")
  // This is the primary and most reliable method
  const { data: itrsListData, isLoading: isLoadingList, error: listError } = useQuery({
    queryKey: ['itrs', 'detail', itrId],
    queryFn: async () => {
      // First, check if we can find it in existing cached queries from the list page
      const allQueries = queryClient.getQueriesData({ queryKey: ['itrs'] });
      for (const [, cachedData] of allQueries) {
        if (cachedData && typeof cachedData === 'object') {
          // Handle PaginatedResponse structure
          const items = (cachedData as any).items || (cachedData as any).data?.items || [];
          const found = items.find((item: any) =>
            item.id === itrId ||
            item.id === Number(itrId) ||
            item.personalDetailId === itrId ||
            item.personalDetailId === Number(itrId)
          );
          if (found) {
            return {
              ...found,
              sources: [],
              comments: [],
            } as ITRWithDetails;
          }
        }
      }

      // If not in cache, fetch all ITRs from API
      const result = await itrApi.getITRs({ page: 1, limit: 1000 });

      // Try to find by exact ID match first
      let foundItr = result.items.find((item) => item.id === itrId || item.id === Number(itrId));

      // If not found, try matching by personalDetailId
      if (!foundItr) {
        foundItr = result.items.find((item) =>
          (item as any).personalDetailId === itrId ||
          (item as any).personalDetailId === Number(itrId)
        );
      }

      if (foundItr) {
        // Ensure all required fields are present
        return {
          ...foundItr,
          id: foundItr.id || itrId,
          clientName: foundItr.clientName || 'N/A',
          financialYear: foundItr.financialYear || 'N/A',
          panNumber: foundItr.panNumber || '',
          status: foundItr.status || 'PENDING',
          createdAt: foundItr.createdAt || new Date().toISOString(),
          updatedAt: foundItr.updatedAt || new Date().toISOString(),
          sources: [],
          comments: [],
        } as ITRWithDetails;
      }

      return null;
    },
    enabled: !!itrId,
    staleTime: 30000, // Cache for 30 seconds
    retry: 1,
  });

  // Try detail API as secondary option only if list data is not available
  const { data: itrDetail, isLoading: isLoadingDetail, error: detailError } = useQuery({
    queryKey: ['itr-detail', itrId],
    queryFn: () => itrApi.getITRDetails(itrId),
    enabled: !!itrId && !itrsListData && !isLoadingList,
    retry: 0,
  });

  // Use list data first, fallback to detail API
  const currentItr = itrsListData || itrDetail;
  const documentsBackendItrId = resolveBackendItrIdForDocuments(currentItr);
  const isLoading = (isLoadingList || isLoadingDetail) && !currentItr;

  // Get personal details - first check if it's already in the ITR data, otherwise fetch from API
  const { data: personalDetails, isLoading: personalDetailsLoading } = useQuery({
    queryKey: ['personalDetails', currentItr?.userId, currentItr?.panNumber, currentItr?.id],
    queryFn: async () => {
      if (!currentItr) return null;

      // First, check if personal details are already embedded in the ITR data
      const itrWithPersonalDetails = currentItr as any;
      const embeddedPersonalDetails = itrWithPersonalDetails?._personalDetails;

      if (embeddedPersonalDetails && Object.keys(embeddedPersonalDetails).length > 0) {
        const pd = embeddedPersonalDetails;
        // Transform to PersonalDetails format
        const transformed = {
          UserId: pd.userId || pd.UserId || currentItr.userId || 0,
          PanNumber: pd.panNumber || pd.PanNumber || currentItr.panNumber || '',
          FirstName: pd.firstName || pd.first_name || pd.FirstName,
          MiddleName: pd.middleName || pd.middle_name || pd.MiddleName,
          LastName: pd.lastName || pd.last_name || pd.LastName,
          Email: pd.email || pd.Email,
          MobileNumber: pd.mobileNumber || pd.mobile_number || pd.MobileNumber || pd.mobile,
          DateOfBirth: pd.dateOfBirth || pd.date_of_birth || pd.DateOfBirth || pd.dob,
          Address: pd.address || pd.Address,
          City: pd.city || pd.City,
          State: pd.state || pd.State,
          PinCode: pd.pinCode || pd.pin_code || pd.PinCode,
          Occupation: pd.occupation || pd.Occupation,
        };

        // Only return if we have at least some data
        if (transformed.FirstName || transformed.LastName || transformed.Email || transformed.MobileNumber) {
          return transformed;
        }
      }

      // If not in ITR data or incomplete, fetch from API
      // Extract userId and panNumber from currentItr (they might be in nested structure)
      const userId = currentItr.userId || (currentItr as any).userId || (embeddedPersonalDetails as any)?.userId || (embeddedPersonalDetails as any)?.UserId;
      const panNumber = currentItr.panNumber || (currentItr as any).panNumber || (embeddedPersonalDetails as any)?.panNumber || (embeddedPersonalDetails as any)?.PanNumber;

      if (userId && panNumber) {
        try {
          return await personalDetailsApi.getPersonalDetails(userId, panNumber);
        } catch (error) {
          console.error('Error fetching personal details from API:', error);
          // Return embedded data even if incomplete
          if (embeddedPersonalDetails) {
            return {
              UserId: userId,
              PanNumber: panNumber,
              FirstName: embeddedPersonalDetails.firstName || embeddedPersonalDetails.first_name || embeddedPersonalDetails.FirstName,
              MiddleName: embeddedPersonalDetails.middleName || embeddedPersonalDetails.middle_name || embeddedPersonalDetails.MiddleName,
              LastName: embeddedPersonalDetails.lastName || embeddedPersonalDetails.last_name || embeddedPersonalDetails.LastName,
              Email: embeddedPersonalDetails.email || embeddedPersonalDetails.Email,
              MobileNumber: embeddedPersonalDetails.mobileNumber || embeddedPersonalDetails.mobile_number || embeddedPersonalDetails.MobileNumber || embeddedPersonalDetails.mobile,
              DateOfBirth: embeddedPersonalDetails.dateOfBirth || embeddedPersonalDetails.date_of_birth || embeddedPersonalDetails.DateOfBirth || embeddedPersonalDetails.dob,
              Address: embeddedPersonalDetails.address || embeddedPersonalDetails.Address,
              City: embeddedPersonalDetails.city || embeddedPersonalDetails.City,
              State: embeddedPersonalDetails.state || embeddedPersonalDetails.State,
              PinCode: embeddedPersonalDetails.pinCode || embeddedPersonalDetails.pin_code || embeddedPersonalDetails.PinCode,
              Occupation: embeddedPersonalDetails.occupation || embeddedPersonalDetails.Occupation,
            };
          }
          throw error;
        }
      }

      return null;
    },
    enabled: !!currentItr,
    retry: 1,
  });

  const { data: documents } = useQuery({
    queryKey: ['documents', 'itr', documentsBackendItrId],
    queryFn: () => documentsApi.getDocumentsByITR(documentsBackendItrId),
    enabled: !!currentItr && documentsBackendItrId > 0,
  });

  if (isLoading || personalDetailsLoading) {
    return (
      <DashboardLayout>
        <LoadingSpinner />
      </DashboardLayout>
    );
  }

  if (!currentItr) {
    return (
      <DashboardLayout>
        <Box>
          <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
            <Button
              startIcon={<ArrowBackIcon />}
              onClick={() => navigate(-1)}
              variant="outlined"
            >
              Back
            </Button>
          </Box>
          <Alert severity="error">
            <AlertTitle>ITR Not Found</AlertTitle>
            ITR with ID {itrId} could not be found. Please check the ID and try again.
            {(listError || detailError) && (
              <Typography variant="body2" sx={{ mt: 1 }}>
                Error: {(listError || detailError) instanceof Error ? (listError || detailError)?.message : 'Unknown error'}
              </Typography>
            )}
          </Alert>
        </Box>
      </DashboardLayout>
    );
  }

  if (isEditMode) {
    return (
      <DashboardLayout>
        <Box>
          <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
            <Button
              startIcon={<ArrowBackIcon />}
              onClick={() => navigate(`/itrs/${currentItr.id}`)}
              variant="outlined"
            >
              Back
            </Button>
            <Typography variant="h4">
              Edit ITR #{currentItr.id}
            </Typography>
          </Box>

          <Tabs value={activeTab} onChange={(_, newValue) => setActiveTab(newValue)} sx={{ mb: 3 }}>
            <Tab label="ITR Status" />
            <Tab label="Personal Details" />
            <Tab label="Mark ITR Complete" />
          </Tabs>

          {activeTab === 0 && <ITREditForm itr={currentItr} />}
          {activeTab === 1 && personalDetails && (
            <InfoCard title="Personal Details">
              <PersonalDetailsForm
                userId={currentItr.userId}
                panNumber={currentItr.panNumber}
                initialData={personalDetails}
                onCancel={() => navigate(`/itrs/${currentItr.id}`)}
              />
            </InfoCard>
          )}
          {activeTab === 2 && <MarkITRCompleteForm itr={currentItr} />}
        </Box>
      </DashboardLayout>
    );
  }

  return (
    <DashboardLayout>
      <Box>
        <Box sx={{ mb: 3, display: 'flex', alignItems: 'center', gap: 2 }}>
          <Button
            startIcon={<ArrowBackIcon />}
            onClick={() => navigate(-1)}
            variant="outlined"
          >
            Back
          </Button>
          <Typography variant="h4">
            ITR Details #{currentItr.id}
          </Typography>
        </Box>

        <Box sx={{ mt: 2 }}>
          <ITRDetails
            itr={currentItr}
            onAssign={() => setAssignModalOpen(true)}
            hasSuccessfulPayment={currentItr?.status === 'PAID' || currentItr?.status === 'SUCCESS'}
          />
        </Box>

        {personalDetails && (
          <Box sx={{ mt: 3 }}>
            <InfoCard title="Personal Details">
              <Box sx={{ display: 'grid', gridTemplateColumns: { xs: '1fr', md: 'repeat(2, 1fr)' }, gap: 2 }}>
                <Box>
                  <Typography variant="body2" color="text.secondary">Name</Typography>
                  <Typography variant="body1">
                    {[personalDetails.FirstName, personalDetails.MiddleName, personalDetails.LastName]
                      .filter(Boolean)
                      .join(' ') || 'N/A'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary">Email</Typography>
                  <Typography variant="body1">{personalDetails.Email || 'N/A'}</Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary">Mobile</Typography>
                  <Typography variant="body1">{personalDetails.MobileNumber || 'N/A'}</Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary">Date of Birth</Typography>
                  <Typography variant="body1">{personalDetails.DateOfBirth || 'N/A'}</Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary">Address</Typography>
                  <Typography variant="body1">
                    {[personalDetails.Address, personalDetails.City, personalDetails.State, personalDetails.PinCode]
                      .filter(Boolean)
                      .join(', ') || 'N/A'}
                  </Typography>
                </Box>
                <Box>
                  <Typography variant="body2" color="text.secondary">Occupation</Typography>
                  <Typography variant="body1">{personalDetails.Occupation || 'N/A'}</Typography>
                </Box>
              </Box>
            </InfoCard>
          </Box>
        )}

        {currentItr.comments && currentItr.comments.length > 0 && (
          <Box sx={{ mt: 3 }}>
            <ITRComments comments={currentItr.comments} />
          </Box>
        )}

        <Box sx={{ mt: 3 }}>
          <DocumentList
            documents={documents?.length ? documents : [DUMMY_DOCUMENT_PLACEHOLDER]}
            panNumber={currentItr.panNumber || personalDetails?.PanNumber || ''}
            onView={(doc) => {
              setSelectedDocument(doc);
              setViewerOpen(true);
            }}
          />
        </Box>

        {assignModalOpen && (
          <AssignProfessionalModal
            open={assignModalOpen}
            onClose={() => setAssignModalOpen(false)}
            itr={currentItr}
            currentAssignment={currentItr.assignment}
          />
        )}

        <DocumentViewer
          open={viewerOpen}
          document={selectedDocument}
          panNumber={currentItr.panNumber || personalDetails?.PanNumber || ''}
          onClose={() => {
            setViewerOpen(false);
            setSelectedDocument(null);
          }}
        />
      </Box>
    </DashboardLayout>
  );
};

export default ITRDetailPage;

