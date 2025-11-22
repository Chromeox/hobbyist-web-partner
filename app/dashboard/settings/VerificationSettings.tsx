'use client';

import React, { useState, useEffect } from 'react';
import { Upload, FileText, CheckCircle, AlertCircle, Shield, Clock } from 'lucide-react';
import { useAuth } from '@/lib/hooks/useAuth';
import { uploadFile } from '@/lib/storage';
import { supabase } from '@/lib/supabase';

interface VerificationData {
    businessLicense: string | null;
    insuranceCert: string | null;
    bankStatement: string | null;
    taxDocument: string | null;
    certifications: string[];
    status: 'pending' | 'verified' | 'rejected' | 'incomplete';
}

export default function VerificationSettings() {
    const { user } = useAuth();
    const [loading, setLoading] = useState(true);
    const [formData, setFormData] = useState<VerificationData>({
        businessLicense: null,
        insuranceCert: null,
        bankStatement: null,
        taxDocument: null,
        certifications: [],
        status: 'incomplete'
    });

    const [uploadStatus, setUploadStatus] = useState<{ [key: string]: 'pending' | 'uploading' | 'success' | 'error' }>({});
    const [uploadErrors, setUploadErrors] = useState<{ [key: string]: string }>({});

    useEffect(() => {
        if (user) {
            fetchVerificationData();
        }
    }, [user]);

    const fetchVerificationData = async () => {
        try {
            setLoading(true);
            // In a real app, this would fetch from a 'verification_documents' table or similar
            // For now, we'll try to get it from user metadata or a dedicated table
            // This is a placeholder for where you'd actually fetch the data

            // Simulating fetch
            const { data, error } = await supabase
                .from('partners')
                .select('verification_data, verification_status')
                .eq('user_id', user?.id)
                .single();

            if (data) {
                setFormData({
                    businessLicense: data.verification_data?.businessLicense || null,
                    insuranceCert: data.verification_data?.insuranceCert || null,
                    bankStatement: data.verification_data?.bankStatement || null,
                    taxDocument: data.verification_data?.taxDocument || null,
                    certifications: data.verification_data?.certifications || [],
                    status: data.verification_status || 'incomplete'
                });
            }
        } catch (error) {
            console.error('Error fetching verification data:', error);
        } finally {
            setLoading(false);
        }
    };

    const handleFileUpload = async (field: string, file: File) => {
        if (!user) {
            setUploadErrors(prev => ({ ...prev, [field]: 'Please sign in to upload files' }));
            setUploadStatus(prev => ({ ...prev, [field]: 'error' }));
            return;
        }

        setUploadStatus(prev => ({ ...prev, [field]: 'uploading' }));
        setUploadErrors(prev => ({ ...prev, [field]: '' }));

        try {
            const result = await uploadFile(file, user.id, {
                bucket: 'verification-documents',
                folder: 'settings',
                maxSizeMB: 10,
                allowedTypes: [
                    'application/pdf',
                    'image/jpeg',
                    'image/png',
                    'image/jpg'
                ]
            });

            if (result.error) {
                setUploadStatus(prev => ({ ...prev, [field]: 'error' }));
                setUploadErrors(prev => ({ ...prev, [field]: result.error! }));
                return;
            }

            // Update local state
            const newUrl = result.url;
            setFormData(prev => ({ ...prev, [field]: newUrl }));
            setUploadStatus(prev => ({ ...prev, [field]: 'success' }));

            // Persist to database
            await updateVerificationData(field, newUrl);

        } catch (error) {
            setUploadStatus(prev => ({ ...prev, [field]: 'error' }));
            setUploadErrors(prev => ({
                ...prev,
                [field]: error instanceof Error ? error.message : 'Upload failed'
            }));
        }
    };

    const updateVerificationData = async (field: string, value: any) => {
        if (!user) return;

        try {
            // This would update the JSONB column or specific columns in your database
            const updatedData = {
                ...formData,
                [field]: value
            };

            // Remove status from the data object we save to the json column
            const { status, ...dataToSave } = updatedData;

            await supabase
                .from('partners')
                .update({
                    verification_data: dataToSave,
                    // If all required fields are present, we could auto-update status to pending
                    verification_status: isComplete(updatedData) ? 'pending' : 'incomplete'
                })
                .eq('user_id', user.id);

        } catch (error) {
            console.error('Error updating verification data:', error);
        }
    };

    const isComplete = (data: VerificationData) => {
        return !!(data.businessLicense && data.insuranceCert && data.taxDocument);
    };

    const requirements = [
        {
            id: 'businessLicense',
            label: 'Business License',
            description: 'Valid business license or registration document',
            required: true,
        },
        {
            id: 'insuranceCert',
            label: 'Liability Insurance',
            description: 'General liability insurance certificate',
            required: true,
        },
        {
            id: 'taxDocument',
            label: 'Tax Document',
            description: 'W-9 form or tax registration document',
            required: true,
        },
    ];

    const FileUploadArea = ({ requirement }: { requirement: any }) => {
        const status = uploadStatus[requirement.id];
        const hasFile = formData[requirement.id as keyof typeof formData];

        return (
            <div className="border border-gray-200 rounded-lg p-6 hover:border-blue-300 transition-colors bg-white">
                <div className="flex items-start justify-between">
                    <div className="flex-1">
                        <div className="flex items-center gap-2 mb-1">
                            <h3 className="font-medium text-gray-900">
                                {requirement.label}
                            </h3>
                            {requirement.required && (
                                <span className="text-xs font-medium text-red-500 bg-red-50 px-2 py-0.5 rounded-full">
                                    Required
                                </span>
                            )}
                            {hasFile && (
                                <span className="text-xs font-medium text-green-600 bg-green-50 px-2 py-0.5 rounded-full flex items-center">
                                    <CheckCircle className="w-3 h-3 mr-1" />
                                    Uploaded
                                </span>
                            )}
                        </div>
                        <p className="text-sm text-gray-500 mb-4">{requirement.description}</p>

                        <div className="flex items-center gap-3">
                            <input
                                type="file"
                                id={`upload-${requirement.id}`}
                                accept=".pdf,.jpg,.jpeg,.png,.doc,.docx"
                                onChange={(e) => {
                                    const file = e.target.files?.[0];
                                    if (file) handleFileUpload(requirement.id, file);
                                }}
                                className="hidden"
                                disabled={status === 'uploading'}
                            />

                            <label
                                htmlFor={`upload-${requirement.id}`}
                                className={`inline-flex items-center px-4 py-2 text-sm font-medium rounded-lg transition-colors cursor-pointer ${status === 'uploading'
                                        ? 'bg-gray-100 text-gray-400 cursor-not-allowed'
                                        : 'bg-white border border-gray-300 text-gray-700 hover:bg-gray-50'
                                    }`}
                            >
                                {status === 'uploading' ? (
                                    <>
                                        <div className="w-4 h-4 border-2 border-gray-400 border-t-transparent rounded-full animate-spin mr-2" />
                                        Uploading...
                                    </>
                                ) : (
                                    <>
                                        <Upload className="h-4 w-4 mr-2" />
                                        {hasFile ? 'Replace File' : 'Upload Document'}
                                    </>
                                )}
                            </label>

                            {hasFile && (
                                <a
                                    href={hasFile as string}
                                    target="_blank"
                                    rel="noopener noreferrer"
                                    className="text-sm text-blue-600 hover:text-blue-800 hover:underline flex items-center"
                                >
                                    <FileText className="h-4 w-4 mr-1" />
                                    View
                                </a>
                            )}
                        </div>

                        {uploadErrors[requirement.id] && (
                            <p className="text-sm text-red-600 mt-2 flex items-center">
                                <AlertCircle className="w-4 h-4 mr-1" />
                                {uploadErrors[requirement.id]}
                            </p>
                        )}
                    </div>
                </div>
            </div>
        );
    };

    if (loading) {
        return (
            <div className="flex justify-center p-12">
                <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            </div>
        );
    }

    return (
        <div className="space-y-6">
            <div className="bg-blue-50 border border-blue-200 rounded-xl p-6">
                <div className="flex items-start gap-4">
                    <Shield className="h-6 w-6 text-blue-600 mt-1" />
                    <div>
                        <h2 className="text-lg font-semibold text-blue-900">Verification Status</h2>
                        <div className="flex items-center gap-2 mt-1">
                            <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium capitalize ${formData.status === 'verified'
                                    ? 'bg-green-100 text-green-800'
                                    : formData.status === 'pending'
                                        ? 'bg-yellow-100 text-yellow-800'
                                        : 'bg-gray-100 text-gray-800'
                                }`}>
                                {formData.status}
                            </span>
                            <span className="text-sm text-blue-700">
                                {formData.status === 'verified'
                                    ? 'Your studio is fully verified.'
                                    : formData.status === 'pending'
                                        ? 'We are reviewing your documents.'
                                        : 'Please upload the required documents to verify your studio.'}
                            </span>
                        </div>
                    </div>
                </div>
            </div>

            <div>
                <h3 className="text-lg font-medium text-gray-900 mb-4">Required Documents</h3>
                <div className="grid grid-cols-1 gap-4">
                    {requirements.map((requirement) => (
                        <FileUploadArea key={requirement.id} requirement={requirement} />
                    ))}
                </div>
            </div>

            <div className="bg-gray-50 rounded-xl p-6 border border-gray-200">
                <div className="flex items-start gap-4">
                    <Clock className="h-5 w-5 text-gray-500 mt-0.5" />
                    <div>
                        <h4 className="text-sm font-medium text-gray-900">Why do we need this?</h4>
                        <p className="text-sm text-gray-600 mt-1">
                            To ensure the safety and quality of our platform, we verify all partner studios.
                            This helps build trust with students and ensures compliance with local regulations.
                            Your documents are stored securely and only accessed by our verification team.
                        </p>
                    </div>
                </div>
            </div>
        </div>
    );
}
