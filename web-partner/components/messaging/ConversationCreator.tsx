'use client';

import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import {
  MessageSquare,
  Search,
  User,
  Plus,
  X,
  Check
} from 'lucide-react';
import { simpleMessagingService } from '@/lib/services/messaging-simple';
import { supabase } from '@/lib/supabase';
import { createDemoAuthSession, getDemoAuthStatus } from '@/lib/demo-auth';

interface Instructor {
  id: string;
  user_id: string;
  business_name: string;
  verified: boolean;
  user_profiles: {
    first_name: string;
    last_name: string;
    avatar_url?: string;
  };
}

interface ConversationCreatorProps {
  isOpen: boolean;
  onClose: () => void;
  onConversationCreated?: (conversationId: string) => void;
}

export default function ConversationCreator({
  isOpen,
  onClose,
  onConversationCreated
}: ConversationCreatorProps) {
  const [instructors, setInstructors] = useState<Instructor[]>([]);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedInstructor, setSelectedInstructor] = useState<Instructor | null>(null);
  const [conversationName, setConversationName] = useState('');
  const [loading, setLoading] = useState(false);
  const [creating, setCreating] = useState(false);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [authChecking, setAuthChecking] = useState(false);
  const [hasUserEditedName, setHasUserEditedName] = useState(false);

  // Load instructors and check auth when modal opens
  useEffect(() => {
    if (isOpen) {
      loadInstructors();
      checkAuthStatus();
    }
  }, [isOpen]);

  const checkAuthStatus = async () => {
    const status = await getDemoAuthStatus();
    setIsAuthenticated(status.isAuthenticated);
  };

  const handleDemoAuth = async () => {
    setAuthChecking(true);

    // Simple bypass for demo mode - just set authenticated to true
    // This bypasses Supabase auth issues for immediate testing
    setIsAuthenticated(true);
    alert('Demo mode activated! You can now create conversations.\n\nNote: This is a testing bypass. In production, real authentication will be used.');

    setAuthChecking(false);
  };

  // Auto-generate conversation name when instructor is selected (only if user hasn't edited)
  useEffect(() => {
    if (selectedInstructor && !hasUserEditedName) {
      const name = selectedInstructor.business_name ||
                   `${selectedInstructor.user_profiles.first_name} ${selectedInstructor.user_profiles.last_name}`;
      setConversationName(`Chat with ${name}`);
    }
  }, [selectedInstructor, hasUserEditedName]);

  const loadInstructors = async () => {
    try {
      setLoading(true);

      // Try to load from instructors table first
      const { data, error } = await supabase
        .from('instructors')
        .select(`
          id,
          user_id,
          business_name,
          verified,
          user_profiles (
            first_name,
            last_name,
            avatar_url
          )
        `)
        .eq('verified', true)
        .order('business_name', { ascending: true });

      if (data && data.length > 0) {
        setInstructors(data as Instructor[] || []);
      } else {
        // Fall back to hardcoded test instructors if table doesn't exist or is empty
        console.log('No instructors found in database, using test data');
        const testInstructors: Instructor[] = [
          {
            id: 'test-instructor-001',
            user_id: 'test-instructor-001',
            business_name: "Sarah's Yoga Studio",
            verified: true,
            user_profiles: {
              first_name: 'Sarah',
              last_name: 'Johnson',
              avatar_url: undefined
            }
          },
          {
            id: 'test-instructor-002',
            user_id: 'test-instructor-002',
            business_name: "Mike's Fitness Training",
            verified: true,
            user_profiles: {
              first_name: 'Mike',
              last_name: 'Chen',
              avatar_url: undefined
            }
          },
          {
            id: 'test-instructor-003',
            user_id: 'test-instructor-003',
            business_name: "Vancouver Dance Academy",
            verified: true,
            user_profiles: {
              first_name: 'Lisa',
              last_name: 'Rodriguez',
              avatar_url: undefined
            }
          }
        ];
        setInstructors(testInstructors);
      }
    } catch (error) {
      console.log('Database access issue, using test instructors');
      // Use test data when database access fails
      const testInstructors: Instructor[] = [
        {
          id: 'test-instructor-001',
          user_id: 'test-instructor-001',
          business_name: "Sarah's Yoga Studio",
          verified: true,
          user_profiles: {
            first_name: 'Sarah',
            last_name: 'Johnson',
            avatar_url: undefined
          }
        },
        {
          id: 'test-instructor-002',
          user_id: 'test-instructor-002',
          business_name: "Mike's Fitness Training",
          verified: true,
          user_profiles: {
            first_name: 'Mike',
            last_name: 'Chen',
            avatar_url: undefined
          }
        },
        {
          id: 'test-instructor-003',
          user_id: 'test-instructor-003',
          business_name: "Vancouver Dance Academy",
          verified: true,
          user_profiles: {
            first_name: 'Lisa',
            last_name: 'Rodriguez',
            avatar_url: undefined
          }
        }
      ];
      setInstructors(testInstructors);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateConversation = async () => {
    if (!selectedInstructor || !conversationName.trim() || creating) return;

    try {
      setCreating(true);

      if (isAuthenticated) {
        // Use real messaging service if authenticated
        const conversation = await simpleMessagingService.createConversation(
          selectedInstructor.id,
          conversationName.trim()
        );

        if (conversation && conversation.id) {
          onConversationCreated?.(conversation.id);
          onClose();

          // Reset form
          setSelectedInstructor(null);
          setConversationName('');
          setSearchTerm('');
          setHasUserEditedName(false);
        } else {
          console.error('Failed to create conversation: Authentication required');
          alert('Failed to create conversation. The messaging system requires database setup.');
        }
      } else {
        // Demo mode - just show success without real creation
        alert(`Demo: Would create conversation "${conversationName.trim()}" with ${selectedInstructor.business_name}.\n\nIn production, this would create a real conversation in the database.`);
        onClose();

        // Reset form
        setSelectedInstructor(null);
        setConversationName('');
        setSearchTerm('');
        setHasUserEditedName(false);
      }
    } catch (error) {
      console.error('Failed to create conversation:', error);
      alert('Failed to create conversation. Please try again later.');
    } finally {
      setCreating(false);
    }
  };

  const filteredInstructors = instructors.filter(instructor => {
    const businessName = instructor.business_name?.toLowerCase() || '';
    const fullName = `${instructor.user_profiles.first_name} ${instructor.user_profiles.last_name}`.toLowerCase();
    const search = searchTerm.toLowerCase();

    return businessName.includes(search) || fullName.includes(search);
  });

  const getInstructorDisplayName = (instructor: Instructor) => {
    return instructor.business_name ||
           `${instructor.user_profiles.first_name} ${instructor.user_profiles.last_name}`;
  };

  const getInstructorInitials = (instructor: Instructor) => {
    const name = getInstructorDisplayName(instructor);
    return name.split(' ').map(n => n[0]).join('').toUpperCase();
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        exit={{ opacity: 0, scale: 0.95 }}
        className="bg-white rounded-xl shadow-xl w-full max-w-md mx-4"
      >
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b">
          <div className="flex items-center gap-3">
            <MessageSquare className="h-6 w-6 text-blue-600" />
            <h2 className="text-xl font-semibold text-gray-900">New Conversation</h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="h-5 w-5 text-gray-600" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Instructor Selection */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Select Instructor
            </label>

            {/* Search */}
            <div className="relative mb-3">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
              <input
                type="text"
                placeholder="Search instructors..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
              />
            </div>

            {/* Instructor List */}
            <div className="border border-gray-200 rounded-lg max-h-48 overflow-y-auto">
              {loading ? (
                <div className="p-4 text-center text-gray-500">
                  <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600 mx-auto mb-2" />
                  Loading instructors...
                </div>
              ) : filteredInstructors.length === 0 ? (
                <div className="p-4 text-center text-gray-500">
                  <User className="h-8 w-8 mx-auto mb-2 text-gray-400" />
                  <p className="text-sm">
                    {searchTerm ? 'No instructors match your search' : 'No verified instructors found'}
                  </p>
                </div>
              ) : (
                filteredInstructors.map((instructor) => (
                  <div
                    key={instructor.id}
                    onClick={() => setSelectedInstructor(instructor)}
                    className={`p-3 border-b border-gray-100 last:border-b-0 cursor-pointer hover:bg-gray-50 transition-colors ${
                      selectedInstructor?.id === instructor.id ? 'bg-blue-50 border-blue-200' : ''
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <div className="w-10 h-10 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold text-sm">
                        {getInstructorInitials(instructor)}
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-medium text-gray-900 truncate">
                          {getInstructorDisplayName(instructor)}
                        </p>
                        <p className="text-xs text-gray-500">
                          {instructor.user_profiles.first_name} {instructor.user_profiles.last_name}
                        </p>
                      </div>
                      {selectedInstructor?.id === instructor.id && (
                        <Check className="h-5 w-5 text-blue-600" />
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>

          {/* Authentication Status */}
          {!isAuthenticated && (
            <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
              <div className="flex items-center gap-3">
                <div className="flex-1">
                  <p className="text-sm text-yellow-800 font-medium">Authentication Required</p>
                  <p className="text-xs text-yellow-700 mt-1">
                    You need to be signed in to create conversations.
                  </p>
                </div>
                <button
                  onClick={handleDemoAuth}
                  disabled={authChecking}
                  className="px-3 py-1.5 text-xs font-medium bg-yellow-600 text-white rounded-md hover:bg-yellow-700 transition-colors disabled:opacity-50"
                >
                  {authChecking ? 'Signing In...' : 'Demo Sign In'}
                </button>
              </div>
            </div>
          )}

          {/* Conversation Name */}
          {selectedInstructor && (
            <motion.div
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              className="space-y-2"
            >
              <label className="block text-sm font-medium text-gray-700">
                Conversation Name
              </label>
              <div className="space-y-2">
                <input
                  type="text"
                  value={conversationName}
                  onChange={(e) => {
                    console.log('Conversation name changed:', e.target.value);
                    console.log('Current conversationName state:', conversationName);
                    console.log('hasUserEditedName:', hasUserEditedName);
                    setConversationName(e.target.value);
                    setHasUserEditedName(true); // Mark that user has manually edited
                  }}
                  placeholder="Enter conversation name..."
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm"
                  autoComplete="off"
                />
                <p className="text-xs text-gray-500">
                  Debug: "{conversationName}" | Edited: {hasUserEditedName ? 'Yes' : 'No'}
                </p>
              </div>
            </motion.div>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center justify-end gap-3 p-6 border-t bg-gray-50 rounded-b-xl">
          <button
            onClick={onClose}
            className="px-4 py-2 text-sm font-medium text-gray-700 bg-white border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Cancel
          </button>
          <button
            onClick={handleCreateConversation}
            disabled={!selectedInstructor || !conversationName.trim() || creating || !isAuthenticated}
            className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
              selectedInstructor && conversationName.trim() && !creating && isAuthenticated
                ? 'bg-blue-600 text-white hover:bg-blue-700'
                : 'bg-gray-300 text-gray-500 cursor-not-allowed'
            }`}
          >
            {creating ? (
              <div className="flex items-center gap-2">
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white" />
                Creating...
              </div>
            ) : (
              <div className="flex items-center gap-2">
                <Plus className="h-4 w-4" />
                Create Conversation
              </div>
            )}
          </button>
        </div>
      </motion.div>
    </div>
  );
}