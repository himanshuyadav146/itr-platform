import { useState, useEffect } from 'react';
import { useSearchParams, useNavigate } from 'react-router-dom';
import { useSelector } from 'react-redux';
import type { RootState } from '../store/index';
import { itrDocumentsApi, getErrorMessage } from '../services/api';

const DocumentUpload = () => {
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const panFromQuery = searchParams.get('PanNumber') || '';
  const { user, selectedPackage } = useSelector((state: RootState) => state.auth);
  const panNumber = panFromQuery || user?.PanNumber || user?.pan || '';

  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);
  const [documents, setDocuments] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  useEffect(() => {
    if (panNumber) {
      fetchDocuments();
    }
  }, [panNumber]);

  const fetchDocuments = async () => {
    try {
      setError(null);
      console.log('[DocumentUpload.fetchDocuments] Fetching documents for PAN:', panNumber);
      const res = await itrDocumentsApi.getDocuments(panNumber);
      console.log('[DocumentUpload.fetchDocuments] Raw response:', res);
      console.log('[DocumentUpload.fetchDocuments] Response type:', typeof res);
      console.log('[DocumentUpload.fetchDocuments] Is array:', Array.isArray(res));
      
      // Handle multiple response formats
      let docs = [];
      if (Array.isArray(res)) {
        docs = res;
      } else if (res?.data && Array.isArray(res.data)) {
        docs = res.data;
      } else if (res?.documents && Array.isArray(res.documents)) {
        docs = res.documents;
      } else if (res?.data?.documents && Array.isArray(res.data.documents)) {
        docs = res.data.documents;
      }
      
      console.log('[DocumentUpload.fetchDocuments] Extracted docs:', docs);
      setDocuments(Array.isArray(docs) ? docs : []);
    } catch (err) {
      console.error('[DocumentUpload.fetchDocuments] Error:', err);
      setError(getErrorMessage(err));
      setDocuments([]);
    }
  };

  const handleFileSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setSelectedFiles(Array.from(e.target.files));
    }
  };

  const handleUpload = async () => {
    if (!panNumber) {
      setError('PAN number not found');
      return;
    }
    if (selectedFiles.length === 0) {
      setError('Select files to upload');
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      console.log('[DocumentUpload.handleUpload] Selected files:', Array.from(selectedFiles).map(f => f.name));
      console.log('[DocumentUpload.handleUpload] Uploading for PAN:', panNumber);
      const res = await itrDocumentsApi.uploadDocuments(panNumber, selectedFiles);
      console.log('[DocumentUpload.handleUpload] Upload response:', res);
      
      const fileNames = Array.from(selectedFiles).map(f => f.name);
      
      // Build payload for save with uploaded file names
      const uploadedFiles = fileNames.map((fileName) => ({
        documentName: fileName.split('.')[0] || 'Document',
        fileType: fileName.split('.').pop() || 'pdf',
        filePassword: '',
        fileName: fileName,
      }));
      
      console.log('[DocumentUpload.handleUpload] Auto-saving uploaded files:', uploadedFiles);
      
      // Automatically save after upload
      const savePayload = {
        PanNumber: panNumber,
        journeyType: 'ITR',
        documents: uploadedFiles,
      };
      
      const saveRes = await itrDocumentsApi.saveDocuments(savePayload);
      console.log('[DocumentUpload.handleUpload] Auto-save response:', saveRes);
      
      setSuccess(`${selectedFiles.length} file(s) uploaded and saved successfully`);
      setSelectedFiles([]);
      
      // Refresh documents list after save
      setTimeout(() => fetchDocuments(), 500);
    } catch (err) {
      console.error('[DocumentUpload.handleUpload] Upload error:', err);
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  const handleSave = async () => {
    if (!panNumber) {
      setError('PAN number not found');
      return;
    }
    if (documents.length === 0) {
      setError('No documents to save');
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(null);

    try {
      console.log('[DocumentUpload.handleSave] Saving documents for PAN:', panNumber);
      const payload = {
        PanNumber: panNumber,
        journeyType: 'ITR',
        documents: documents.map((d) => ({
          documentName: d.documentName || d.fileName || 'Document',
          fileType: (d.fileName || '').split('.').pop() || 'pdf',
          filePassword: d.filePassword || '',
          fileName: d.fileName || d.file || '',
        })),
      };
      console.log('[DocumentUpload.handleSave] Save payload:', payload);
      
      const res = await itrDocumentsApi.saveDocuments(payload);
      console.log('[DocumentUpload.handleSave] Save response:', res);
      
      setSuccess('Documents saved successfully! Redirecting to payment...');
      // Auto-navigate to payment after 1 second
      setTimeout(() => {
        navigate(`/payment?PanNumber=${encodeURIComponent(panNumber)}`);
      }, 1000);
    } catch (err) {
      console.error('[DocumentUpload.handleSave] Save error:', err);
      setError(getErrorMessage(err));
      setLoading(false);
    }
  };

  const handleDelete = async (doc: any) => {
    if (!window.confirm('Delete this document?')) return;

    setLoading(true);
    setError(null);

    try {
      console.log('[DocumentUpload.handleDelete] Deleting document:', doc);
      const deletePayload = {
        id: doc.id || doc.docId,
        PanNumber: panNumber,
        fileName: doc.fileName || doc.file,
      };
      console.log('[DocumentUpload.handleDelete] Delete payload:', deletePayload);
      
      const res = await itrDocumentsApi.deleteDocument(deletePayload);
      console.log('[DocumentUpload.handleDelete] Delete response:', res);
      
      setSuccess('Document deleted');
      await fetchDocuments();
    } catch (err) {
      console.error('[DocumentUpload.handleDelete] Delete error:', err);
      setError(getErrorMessage(err));
    } finally {
      setLoading(false);
    }
  };

  return (
    // <main className="min-h-screen bg-gray-950">
    //   {/* Header */}
    //   <div className="border-b border-gray-800 bg-gray-900/50 sticky top-0 z-40">
    //     <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
    //       <div>
    //         <h1 className="text-2xl font-bold text-white">Upload Documents</h1>
    //         <p className="text-sm text-gray-400 mt-1">Step 2: Upload your required documents</p>
    //       </div>
    //       <button
    //         onClick={() => navigate('/dashboard')}
    //         className="text-gray-400 hover:text-white transition text-sm px-4 py-2"
    //       >
    //         ← Back
    //       </button>
    //     </div>
    //   </div>

    //   <div className="max-w-6xl mx-auto px-6 py-3">
    //     <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
    //       {/* Main Content - Left Side (2/3) */}
    //       <div className="lg:col-span-2 space-y-6">
    //         {/* Messages */}
    //         {error && (
    //           <div className="p-4 bg-red-900/20 border border-red-800/50 rounded-lg flex items-start gap-3">
    //             <span className="text-red-400 mt-0.5">⚠</span>
    //             <p className="text-sm text-red-300">{error}</p>
    //           </div>
    //         )}
    //         {success && (
    //           <div className="p-4 bg-green-900/20 border border-green-800/50 rounded-lg flex items-start gap-3">
    //             <span className="text-green-400 mt-0.5">✓</span>
    //             <p className="text-sm text-green-300">{success}</p>
    //           </div>
    //         )}

    //         {/* Upload Card */}
    //         <div className="bg-gray-900/80 border border-gray-800 rounded-lg p-8">
    //           <div className="mb-6">
    //             <h2 className="text-lg font-bold text-white mb-2">Upload Your Documents</h2>
    //             <p className="text-sm text-gray-400">Select files from your computer to upload</p>
    //           </div>

    //           {/* File Input */}
    //           <div className="mb-6">
    //             <label className="block">
    //               <div className="border-2 border-dashed border-gray-700 rounded-lg p-8 text-center hover:border-gray-600 hover:bg-gray-800/30 transition cursor-pointer">
    //                 <div className="flex flex-col items-center">
    //                   <svg className="w-12 h-12 text-gray-500 mb-3" fill="none" stroke="currentColor" viewBox="0 0 24 24">
    //                     <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M9 19l3 3m0 0l3-3m-3 3V10" />
    //                   </svg>
    //                   <p className="text-sm font-medium text-white mb-1">Click to upload or drag and drop</p>
    //                   <p className="text-xs text-gray-400">PDF, DOC, DOCX, JPG, PNG (Max 10MB)</p>
    //                 </div>
    //                 <input
    //                   type="file"
    //                   multiple
    //                   onChange={handleFileSelect}
    //                   disabled={loading}
    //                   className="hidden"
    //                 />
    //               </div>
    //             </label>
    //           </div>

    //           {/* Selected Files List */}
    //           {selectedFiles.length > 0 && (
    //             <div className="mb-6 p-4 bg-gray-800/30 border border-gray-800 rounded-lg">
    //               <p className="text-sm font-medium text-gray-300 mb-3">Selected Files ({selectedFiles.length})</p>
    //               <div className="space-y-2">
    //                 {Array.from(selectedFiles).map((f, i) => (
    //                   <div key={i} className="flex items-center gap-3 text-sm">
    //                     <svg className="w-4 h-4 text-green-400" fill="currentColor" viewBox="0 0 20 20">
    //                       <path fillRule="evenodd" d="M8 16.5a.5.5 0 01-.5-.5v-5H4a2 2 0 01-2-2V7a2 2 0 012-2h12a2 2 0 012 2v2a2 2 0 01-2 2h-3.5V16a.5.5 0 01-.5.5h-1zm5-7a1 1 0 11-2 0 1 1 0 012 0z" clipRule="evenodd" />
    //                     </svg>
    //                     <span className="text-gray-300">{f.name}</span>
    //                     <span className="text-xs text-gray-500 ml-auto">({(f.size / 1024).toFixed(2)} KB)</span>
    //                   </div>
    //                 ))}
    //               </div>
    //             </div>
    //           )}

    //           {/* Upload Button */}
    //           <button
    //             onClick={handleUpload}
    //             disabled={loading || selectedFiles.length === 0}
    //             className="w-full px-6 py-3 bg-white text-black text-sm font-semibold rounded-lg hover:bg-gray-100 disabled:bg-gray-600 disabled:cursor-not-allowed transition"
    //           >
    //             {loading ? 'Uploading...' : 'Upload Files'}
    //           </button>
    //         </div>

    //         {/* Documents List Card */}
    //         <div className="bg-gray-900/80 border border-gray-800 rounded-lg p-6">
    //           <div className="mb-6 flex items-center justify-between">
    //             <div>
    //               <h2 className="text-lg font-bold text-white mb-1">Your Documents</h2>
    //               <p className="text-sm text-gray-400">{documents.length} document(s) uploaded</p>
    //             </div>
    //             <button
    //               onClick={fetchDocuments}
    //               disabled={loading}
    //               className="px-4 py-2 text-sm bg-gray-800 text-gray-300 rounded-lg hover:bg-gray-700 disabled:opacity-50 transition"
    //             >
    //               Refresh
    //             </button>
    //           </div>

    //           {documents.length === 0 ? (
    //             <div className="py-8 text-center">
    //               <p className="text-gray-400 text-sm">No documents uploaded yet</p>
    //               <p className="text-gray-500 text-xs mt-1">Upload files above to get started</p>
    //             </div>
    //           ) : (
    //             <div className="space-y-2">
    //               {documents.map((doc, idx) => (
    //                 <div
    //                   key={idx}
    //                   className="flex items-center justify-between p-4 bg-gray-800/40 border border-gray-800 rounded-lg hover:bg-gray-800/60 transition"
    //                 >
    //                   <div className="flex items-center gap-3 flex-1 min-w-0">
    //                     <svg className="w-5 h-5 text-gray-500 flex-shrink-0" fill="currentColor" viewBox="0 0 20 20">
    //                       <path d="M8 16.5a.5.5 0 01-.5-.5v-5H4a2 2 0 01-2-2V7a2 2 0 012-2h12a2 2 0 012 2v2a2 2 0 01-2 2h-3.5V16a.5.5 0 01-.5.5h-1z" />
    //                     </svg>
    //                     <div className="min-w-0">
    //                       <p className="text-sm font-medium text-white truncate">
    //                         {doc.documentName || doc.fileName || 'Document'}
    //                       </p>
    //                       <p className="text-xs text-gray-500 truncate">{doc.fileName || doc.file}</p>
    //                     </div>
    //                   </div>
    //                   <div className="flex items-center gap-2 flex-shrink-0 ml-4">
    //                     {doc.url && (
    //                       <a
    //                         href={doc.url}
    //                         target="_blank"
    //                         rel="noreferrer"
    //                         className="px-3 py-1.5 text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 transition"
    //                       >
    //                         View
    //                       </a>
    //                     )}
    //                     <button
    //                       onClick={() => handleDelete(doc)}
    //                       disabled={loading}
    //                       className="px-3 py-1.5 text-xs bg-red-900/30 text-red-300 rounded hover:bg-red-900/50 disabled:opacity-50 transition"
    //                     >
    //                       Delete
    //                     </button>
    //                   </div>
    //                 </div>
    //               ))}
    //             </div>
    //           )}

    //           {/* Action Buttons */}
    //           <div className="mt-8 pt-6 border-t border-gray-800 flex gap-3">
    //             <button
    //               onClick={handleSave}
    //               disabled={loading || documents.length === 0}
    //               className="flex-1 px-6 py-3 bg-white text-black text-sm font-semibold rounded-lg hover:bg-gray-100 disabled:bg-gray-600 disabled:cursor-not-allowed transition"
    //             >
    //               {loading ? 'Processing...' : 'Save & Continue to Payment'}
    //             </button>
    //           </div>
    //         </div>

    //         {/* PAN Info */}
    //         <div className="bg-gray-800/30 border border-gray-800 rounded-lg px-6 py-4">
    //           <p className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-1">PAN Number</p>
    //           <p className="text-lg font-bold text-white">{panNumber || 'Not found'}</p>
    //         </div>
    //       </div>

    //       {/* Sidebar - Package Info (1/3) */}
    //       {selectedPackage && (
    //         <div className="lg:col-span-1">
    //           <div className="sticky top-24 bg-gradient-to-b from-gray-900 to-gray-900/50 border border-gray-800 rounded-lg p-6 space-y-6">
    //             <div>
    //               <p className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-2">Selected Package</p>
    //               <h3 className="text-lg font-bold text-white">{selectedPackage.packagename || selectedPackage.name || selectedPackage.packageName}</h3>
    //             </div>

    //             <div className="border-t border-gray-800 pt-6">
    //               <p className="text-xs font-medium text-gray-500 uppercase tracking-wide mb-2">Price</p>
    //               <p className="text-3xl font-bold text-white">₹{parseFloat(selectedPackage.price) || selectedPackage.cost || '0'}</p>
    //               <p className="text-xs text-gray-500 mt-2">All taxes included</p>
    //             </div>

    //             <div className="bg-gray-800/30 border border-gray-800 rounded-lg p-4">
    //               <p className="text-xs text-gray-400 text-center">
    //                 Upload your documents and proceed to payment
    //               </p>
    //             </div>

    //             <div className="border-t border-gray-800 pt-4">
    //               <p className="text-xs text-gray-500 mb-3">Steps</p>
    //               <div className="space-y-2">
    //                 <div className="flex items-center gap-3 opacity-50">
    //                   <span className="flex items-center justify-center w-6 h-6 rounded-full bg-gray-700 text-xs font-bold">1</span>
    //                   <span className="text-sm text-gray-400">Personal Details</span>
    //                 </div>
    //                 <div className="flex items-center gap-3">
    //                   <span className="flex items-center justify-center w-6 h-6 rounded-full bg-white text-black text-xs font-bold">2</span>
    //                   <span className="text-sm text-gray-300">Upload Documents</span>
    //                 </div>
    //                 <div className="flex items-center gap-3 opacity-50">
    //                   <span className="flex items-center justify-center w-6 h-6 rounded-full bg-gray-700 text-xs font-bold">3</span>
    //                   <span className="text-sm text-gray-400">Payment</span>
    //                 </div>
    //               </div>
    //             </div>
    //           </div>
    //         </div>
    //       )}
    //     </div>
    //   </div>
    // </main>
<main className="min-h-screen bg-gray-950">

  {/* Header */}
  <div className="border-b border-gray-800 bg-gray-900/50 sticky top-0 z-40">
    <div className="max-w-7xl mx-auto px-4 sm:px-6 py-3 flex items-center justify-between">
      <div>
        <h1 className="text-xl font-bold text-white">
          Upload Documents
        </h1>
        <p className="text-xs text-gray-400 mt-0.5">
          Step 2: Upload your required documents
        </p>
      </div>

      <button
        onClick={() => navigate('/dashboard')}
        className="text-gray-400 hover:text-white transition text-sm px-3 py-1.5"
      >
        ← Back
      </button>
    </div>
  </div>

  <div className="max-w-6xl mx-auto px-4 sm:px-6 py-4">

    <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

      {/* Main Content */}
      <div className="lg:col-span-2 space-y-4">

        {/* Messages */}
        {error && (
          <div className="p-3 bg-red-900/20 border border-red-800/50 rounded-md flex items-start gap-2">
            <span className="text-red-400 text-sm">⚠</span>
            <p className="text-sm text-red-300">{error}</p>
          </div>
        )}

        {success && (
          <div className="p-3 bg-green-900/20 border border-green-800/50 rounded-md flex items-start gap-2">
            <span className="text-green-400 text-sm">✓</span>
            <p className="text-sm text-green-300">{success}</p>
          </div>
        )}

        {/* Upload Card */}
        <div className="bg-gray-900/80 border border-gray-800 rounded-lg p-5">

          <div className="mb-4">
            <h2 className="text-base font-semibold text-white mb-1">
              Upload Your Documents
            </h2>

            <p className="text-xs text-gray-400">
              Select files from your computer to upload
            </p>
          </div>

          {/* File Input */}
          <div className="mb-4">
            <label className="block">
              <div className="border-2 border-dashed border-gray-700 rounded-lg p-5 text-center hover:border-gray-600 hover:bg-gray-800/30 transition cursor-pointer">

                <div className="flex flex-col items-center">

                  <svg
                    className="w-9 h-9 text-gray-500 mb-2"
                    fill="none"
                    stroke="currentColor"
                    viewBox="0 0 24 24"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M7 16a4 4 0 01-.88-7.903A5 5 0 0115.9 6L16 6a5 5 0 011 9.9M9 19l3 3m0 0l3-3m-3 3V10"
                    />
                  </svg>

                  <p className="text-sm font-medium text-white mb-0.5">
                    Click to upload or drag and drop
                  </p>

                  <p className="text-[11px] text-gray-400">
                    PDF, DOC, DOCX, JPG, PNG (Max 10MB)
                  </p>

                </div>

                <input
                  type="file"
                  multiple
                  onChange={handleFileSelect}
                  disabled={loading}
                  className="hidden"
                />

              </div>
            </label>
          </div>

          {/* Selected Files */}
          {selectedFiles.length > 0 && (
            <div className="mb-4 p-3 bg-gray-800/30 border border-gray-800 rounded-md">

              <p className="text-xs font-medium text-gray-300 mb-2">
                Selected Files ({selectedFiles.length})
              </p>

              <div className="space-y-1.5">
                {Array.from(selectedFiles).map((f, i) => (
                  <div
                    key={i}
                    className="flex items-center gap-2 text-xs"
                  >
                    <svg
                      className="w-4 h-4 text-green-400 flex-shrink-0"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path
                        fillRule="evenodd"
                        d="M8 16.5a.5.5 0 01-.5-.5v-5H4a2 2 0 01-2-2V7a2 2 0 012-2h12a2 2 0 012 2v2a2 2 0 01-2 2h-3.5V16a.5.5 0 01-.5.5h-1zm5-7a1 1 0 11-2 0 1 1 0 012 0z"
                        clipRule="evenodd"
                      />
                    </svg>

                    <span className="text-gray-300 truncate">
                      {f.name}
                    </span>

                    <span className="text-[11px] text-gray-500 ml-auto flex-shrink-0">
                      ({(f.size / 1024).toFixed(2)} KB)
                    </span>
                  </div>
                ))}
              </div>

            </div>
          )}

          {/* Upload Button */}
          <button
            onClick={handleUpload}
            disabled={loading || selectedFiles.length === 0}
            className="w-full h-9 px-5 bg-white text-black text-sm font-semibold rounded-md hover:bg-gray-100 disabled:bg-gray-600 disabled:cursor-not-allowed transition"
          >
            {loading ? 'Uploading...' : 'Upload Files'}
          </button>

        </div>

        {/* Documents List */}
        <div className="bg-gray-900/80 border border-gray-800 rounded-lg p-5">

          <div className="mb-4 flex items-center justify-between">

            <div>
              <h2 className="text-base font-semibold text-white mb-0.5">
                Your Documents
              </h2>

              <p className="text-xs text-gray-400">
                {documents.length} document(s) uploaded
              </p>
            </div>

            <button
              onClick={fetchDocuments}
              disabled={loading}
              className="h-8 px-3 text-xs bg-gray-800 text-gray-300 rounded-md hover:bg-gray-700 disabled:opacity-50 transition"
            >
              Refresh
            </button>

          </div>

          {documents.length === 0 ? (

            <div className="py-6 text-center">
              <p className="text-gray-400 text-sm">
                No documents uploaded yet
              </p>

              <p className="text-gray-500 text-xs mt-1">
                Upload files above to get started
              </p>
            </div>

          ) : (

            <div className="space-y-1.5">

              {documents.map((doc, idx) => (

                <div
                  key={idx}
                  className="flex items-center justify-between p-3 bg-gray-800/40 border border-gray-800 rounded-md hover:bg-gray-800/60 transition"
                >

                  <div className="flex items-center gap-2 flex-1 min-w-0">

                    <svg
                      className="w-4 h-4 text-gray-500 flex-shrink-0"
                      fill="currentColor"
                      viewBox="0 0 20 20"
                    >
                      <path d="M8 16.5a.5.5 0 01-.5-.5v-5H4a2 2 0 01-2-2V7a2 2 0 012-2h12a2 2 0 012 2v2a2 2 0 01-2 2h-3.5V16a.5.5 0 01-.5.5h-1z" />
                    </svg>

                    <div className="min-w-0">
                      <p className="text-sm font-medium text-white truncate">
                        {doc.documentName || doc.fileName || 'Document'}
                      </p>

                      <p className="text-[11px] text-gray-500 truncate">
                        {doc.fileName || doc.file}
                      </p>
                    </div>

                  </div>

                  <div className="flex items-center gap-1.5 flex-shrink-0 ml-3">

                    {doc.url && (
                      <a
                        href={doc.url}
                        target="_blank"
                        rel="noreferrer"
                        className="h-7 px-2.5 flex items-center text-xs bg-gray-700 text-gray-300 rounded hover:bg-gray-600 transition"
                      >
                        View
                      </a>
                    )}

                    <button
                      onClick={() => handleDelete(doc)}
                      disabled={loading}
                      className="h-7 px-2.5 text-xs bg-red-900/30 text-red-300 rounded hover:bg-red-900/50 disabled:opacity-50 transition"
                    >
                      Delete
                    </button>

                  </div>

                </div>

              ))}

            </div>

          )}

          {/* Action */}
          <div className="mt-5 pt-4 border-t border-gray-800">

            <button
              onClick={handleSave}
              disabled={loading || documents.length === 0}
              className="w-full h-9 px-5 bg-white text-black text-sm font-semibold rounded-md hover:bg-gray-100 disabled:bg-gray-600 disabled:cursor-not-allowed transition"
            >
              {loading
                ? 'Processing...'
                : 'Save & Continue to Payment'}
            </button>

          </div>

        </div>

        {/* PAN Info */}
        <div className="bg-gray-800/30 border border-gray-800 rounded-md px-4 py-3">
          <p className="text-[10px] font-medium text-gray-500 uppercase tracking-wide mb-0.5">
            PAN Number
          </p>

          <p className="text-base font-bold text-white">
            {panNumber || 'Not found'}
          </p>
        </div>

      </div>

      {/* Sidebar */}
      {selectedPackage && (
        <div className="lg:col-span-1">

          <div className="sticky top-20 bg-gradient-to-b from-gray-900 to-gray-900/50 border border-gray-800 rounded-lg p-4 space-y-4">

            <div>
              <p className="text-[10px] font-medium text-gray-500 uppercase tracking-wide mb-1">
                Selected Package
              </p>

              <h3 className="text-base font-semibold text-white">
                {selectedPackage.packagename ||
                  selectedPackage.name ||
                  selectedPackage.packageName}
              </h3>
            </div>

            <div className="border-t border-gray-800 pt-4">

              <p className="text-[10px] font-medium text-gray-500 uppercase tracking-wide mb-1">
                Price
              </p>

              <p className="text-2xl font-bold text-white">
                ₹
                {parseFloat(selectedPackage.price) ||
                  selectedPackage.cost ||
                  '0'}
              </p>

              <p className="text-[10px] text-gray-500 mt-1">
                All taxes included
              </p>

            </div>

            <div className="bg-gray-800/30 border border-gray-800 rounded-md p-3">
              <p className="text-xs text-gray-400 text-center leading-4">
                Upload your documents and proceed to payment
              </p>
            </div>

            <div className="border-t border-gray-800 pt-3">

              <p className="text-[10px] text-gray-500 mb-2">
                Steps
              </p>

              <div className="space-y-1.5">

                <div className="flex items-center gap-2">
                  <span className="flex items-center justify-center w-5 h-5 rounded-full bg-gray-700 text-xs font-bold">
                    1
                  </span>

                  <span className="text-xs text-gray-400">
                    Personal Details
                  </span>
                </div>

                <div className="flex items-center gap-2">
                  <span className="flex items-center justify-center w-5 h-5 rounded-full bg-white text-black text-xs font-bold">
                    2
                  </span>

                  <span className="text-xs text-gray-300">
                    Upload Documents
                  </span>
                </div>

                <div className="flex items-center gap-2">
                  <span className="flex items-center justify-center w-5 h-5 rounded-full bg-gray-700 text-xs font-bold">
                    3
                  </span>

                  <span className="text-xs text-gray-400">
                    Payment
                  </span>
                </div>

              </div>

            </div>

          </div>

        </div>
      )}

    </div>
  </div>

</main>
  );
};

export default DocumentUpload;
