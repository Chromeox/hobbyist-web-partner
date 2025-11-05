'use client';

import React, { useState, useEffect } from 'react';
import { createClientComponentClient } from '@supabase/auth-helpers-nextjs';
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

interface InstructorProfile {
  id: string;
  first_name: string;
  last_name: string;
  email: string;
  status: 'pending' | 'approved' | 'rejected';
  created_at: string;
  // Add other relevant instructor profile fields here
}

export default function InstructorApprovalsPage() {
  const supabase = createClientComponentClient();
  const [pendingInstructors, setPendingInstructors] = useState<InstructorProfile[]>([]);
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
      // Fetch instructors with 'pending' status
      // Assuming an 'instructors' table with 'id' and 'status' columns
      const { data, error: supabaseError } = await supabase
        .from('instructors')
        .select('id, first_name, last_name, email, status, created_at')
        .eq('status', 'pending');

      if (supabaseError) throw supabaseError;
      setPendingInstructors(data || []);
    } catch (err: any) {
      console.error('Error fetching pending instructors:', err.message);
      setError('Failed to load pending instructors. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleStatusUpdate = async (instructorId: string, newStatus: 'approved' | 'rejected') => {
    setProcessingId(instructorId);
    setError(null);
    try {
      const response = await fetch('/api/instructors/approve', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ instructorId, status: newStatus }),
      });

      const result = await response.json();

      if (response.ok) {
        // Remove the instructor from the pending list
        setPendingInstructors(prev => prev.filter(inst => inst.id !== instructorId));
        // Optionally, show a success toast/notification
        console.log(result.message);
      } else {
        setError(result.error || 'Failed to update instructor status.');
      }
    } catch (err: any) {
      console.error('Error updating instructor status:', err.message);
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

      {pendingInstructors.length === 0 ? (
        <div className="text-center py-12 border rounded-lg bg-gray-50">
          <Check className="h-12 w-12 text-green-500 mx-auto mb-4" />
          <h3 className="text-lg font-semibold">No Pending Instructors</h3>
          <p className="text-gray-500">All instructor registrations have been reviewed.</p>
        </div>
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Registered On</TableHead>
              <TableHead>Status</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {pendingInstructors.map((instructor) => (
              <TableRow key={instructor.id}>
                <TableCell className="font-medium">{instructor.first_name} {instructor.last_name}</TableCell>
                <TableCell>{instructor.email}</TableCell>
                <TableCell>{new Date(instructor.created_at).toLocaleDateString()}</TableCell>
                <TableCell>
                  <Badge variant="outline" className="capitalize">{instructor.status}</Badge>
                </TableCell>
                <TableCell className="text-right">
                  <div className="flex justify-end gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={() => handleStatusUpdate(instructor.id, 'approved')}
                      disabled={processingId === instructor.id}
                    >
                      {processingId === instructor.id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Check className="h-4 w-4" />
                      )}
                      <span className="ml-1">Approve</span>
                    </Button>
                    <Button
                      variant="destructive"
                      size="sm"
                      onClick={() => handleStatusUpdate(instructor.id, 'rejected')}
                      disabled={processingId === instructor.id}
                    >
                      {processingId === instructor.id ? (
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
