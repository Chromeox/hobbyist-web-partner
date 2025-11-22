'use client';

import React, { useState, useEffect } from 'react';
import { supabase } from '@/lib/supabase';

// Force dynamic rendering to prevent prerender errors with Supabase client
export const dynamic = 'force-dynamic';
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from '@/components/ui/table';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Check, X, Loader2, AlertCircle } from 'lucide-react';

interface InstructorApplication {
  id: string;
  user_id: string | null;
  experience: string;
  qualifications: string;
  categories: string[];
  status: string | null;
  admin_notes: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export default function InstructorApprovalsPage() {
  const [pendingApplications, setPendingApplications] = useState<InstructorApplication[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [processingId, setProcessingId] = useState<string | null>(null);

  useEffect(() => {
    fetchPendingInstructors();
  }, []);

  const fetchPendingInstructors = async () => {
    setLoading(true);
    setError(null);
    try {
      // Fetch instructor applications with 'pending' status
      const { data, error: supabaseError } = await supabase
        .from('instructor_applications')
        .select('id, user_id, experience, qualifications, categories, status, admin_notes, created_at, updated_at')
        .eq('status', 'pending');

      if (supabaseError) throw supabaseError;
      setPendingApplications(data || []);
    } catch (err: any) {
      console.error('Error fetching pending instructors:', err.message);
      setError('Failed to load pending instructors. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusUpdate = async (applicationId: string, newStatus: 'approved' | 'rejected') => {
    setProcessingId(applicationId);
    setError(null);
    try {
      // Update the application status directly via Supabase
      // @ts-ignore - Supabase type definitions don't include all tables
      const { error: updateError } = await supabase
        .from('instructor_applications')
        .update({
          status: newStatus,
          updated_at: new Date().toISOString()
        })
        .eq('id', applicationId);

      if (updateError) throw updateError;

      // Remove the application from the pending list
      setPendingApplications(prev => prev.filter(app => app.id !== applicationId));
      console.log(`Application ${newStatus} successfully`);
    } catch (err: any) {
      console.error('Error updating application status:', err.message);
      setError('An unexpected error occurred while updating status.');
    } finally {
      setProcessingId(null);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="h-8 w-8 animate-spin text-blue-500" />
        <p className="ml-2 text-gray-600">Loading pending instructors...</p>
      </div>
    );
  }

  if (error) {
    return (
      <div className="p-4 bg-red-100 border border-red-400 text-red-700 rounded-lg flex items-center gap-2">
        <AlertCircle className="h-5 w-5" />
        <p>{error}</p>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold text-gray-900">Instructor Approvals</h1>
      <p className="text-gray-600">Review and manage pending instructor registrations.</p>

      {pendingApplications.length === 0 ? (
        <div className="text-center py-12 border rounded-lg bg-gray-50">
          <Check className="h-12 w-12 text-green-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold">No Pending Applications</h3>
          <p className="text-gray-500">All instructor applications have been reviewed.</p>
        </div>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>User ID</TableHead>
              <TableHead>Experience</TableHead>
              <TableHead>Categories</TableHead>
              <TableHead>Applied On</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {pendingApplications.map((application) => (
              <TableRow key={application.id}>
                <TableCell className="font-medium">{application.user_id || 'N/A'}</TableCell>
                <TableCell>{application.experience.length > 50 ? `${application.experience.substring(0, 50)}...` : application.experience}</TableCell>
                <TableCell>{application.categories.join(', ')}</TableCell>
                <TableCell>{application.created_at ? new Date(application.created_at).toLocaleDateString() : 'N/A'}</TableCell>
                <TableCell>
                  <Badge variant="outline" className="capitalize">{application.status || 'pending'}</Badge>
                </TableCell>
                <TableCell className="text-right">
                  <div className="flex justify-end gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleStatusUpdate(application.id, 'approved')}
                      disabled={processingId === application.id}
                    >
                      {processingId === application.id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Check className="h-4 w-4" />
                      )}
                      <span className="ml-1">Approve</span>
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() => handleStatusUpdate(application.id, 'rejected')}
                      disabled={processingId === application.id}
                    >
                      {processingId === application.id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <X className="h-4 w-4" />
                      )}
                      <span className="ml-1">Reject</span>
                    </Button>
                  </div>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}
    </div>
  );
}
