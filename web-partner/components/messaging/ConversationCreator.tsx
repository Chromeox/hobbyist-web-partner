'use client';

import React, { useState, useEffect, useRef } from 'react';
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
  const [isDemoMode, setIsDemoMode] = useState(false);
  const inputRef = useRef<HTMLInputElement>(null);

  // Debug logging for state changes
  useEffect(() => {
    console.log('🔍 ConversationCreator State Update:', {
      isOpen,
      conversationName,
      selectedInstructor: selectedInstructor?.id,
      hasUserEditedName,
      isAuthenticated,
      isDemoMode,
      creating
    });
  }, [isOpen, conversationName, selectedInstructor, hasUserEditedName, isAuthenticated, isDemoMode, creating]);

  // Load instructors and check auth when modal opens
  useEffect(() => {
    if (isOpen) {
      console.log('🔄 Modal opened - resetting form state');
      // Reset all form state when modal opens
      setSelectedInstructor(null);
      setConversationName('');
      setSearchTerm('');
      setHasUserEditedName(false);
      setIsDemoMode(false);
      setCreating(false);
      setAuthChecking(false);

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

    try {
      // Wait a moment to simulate authentication
      await new Promise(resolve => setTimeout(resolve, 500));

      // Simple bypass for demo mode - set both flags
      setIsAuthenticated(true);
      setIsDemoMode(true);

      alert('✅ Demo mode activated! You can now create conversations.\n\nNote: This is a testing bypass. In production, real authentication will be used.');

      console.log('Demo mode flags set:', { isAuthenticated: true, isDemoMode: true });
    } catch (error) {
      console.error('Demo auth error:', error);
      alert('Demo authentication failed. Please try again.');
    } finally {
      setAuthChecking(false);
    }
  };

  // Auto-generate conversation name when instructor is selected (only if user hasn't edited)
  useEffect(() => {
    if (selectedInstructor && !hasUserEditedName) {
      const name = selectedInstructor.business_name ||
                   `${selectedInstructor.user_profiles.first_name} ${selectedInstructor.user_profiles.last_name}`;
      const generatedName = `Chat with ${name}`;
      setConversationName(generatedName);
    }
  }, [selectedInstructor, hasUserEditedName]);

  const loadInstructors = async () => {
    try {
      setLoading(true);
      console.log('🔄 Loading instructors...');

      // Always use test data for now since Supabase isn't properly configured
      console.log('Using test instructors (Supabase instructors table not available)');
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
        console.log('✅ Test instructors loaded:', testInstructors.length);
    } catch (error) {
      console.error('Error loading instructors:', error);
      setInstructors([]);
    } finally {
      setLoading(false);
    }
  };

  const handleCreateConversation = async () => {
    // Get value from both state and DOM as backup
    const stateValue = conversationName.trim();
    const domValue = inputRef.current?.value?.trim() || '';
    const currentConversationName = stateValue || domValue;

    console.log('🎯 Create conversation - values:', {stateValue, domValue, currentConversationName});

    if (!selectedInstructor || !currentConversationName || creating) {
      console.log('🎯 Create conversation blocked:', {
        hasInstructor: !!selectedInstructor,
        hasName: !!currentConversationName,
        creating
      });
      return;
    }

    try {
      setCreating(true);

      console.log('handleCreateConversation - Current state:', {
        isDemoMode,
        isAuthenticated,
        selectedInstructor: selectedInstructor?.id,
        currentConversationName,
        creating
      });

      if (isDemoMode) {
        console.log('Executing demo mode conversation creation...');

        // Demo mode - just show success without real creation
        const successMessage = `✅ Demo Success!\n\nConversation created: "${currentConversationName}"\nWith instructor: ${selectedInstructor.business_name || `${selectedInstructor.user_profiles.first_name} ${selectedInstructor.user_profiles.last_name}`}\n\nIn production, this would create a real conversation in the database.`;

        alert(successMessage);
        console.log('Demo success alert shown');

        // Reset form
        setSelectedInstructor(null);
        setConversationName('');
        setSearchTerm('');
        setHasUserEditedName(false);
        setIsDemoMode(false);

        onClose();
        console.log('Demo mode: Form reset and modal closed');
        return;
      } else if (isAuthenticated) {
        // Use real messaging service if authenticated
        const conversation = await simpleMessagingService.createConversation(
          selectedInstructor.id,
          currentConversationName
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
        // Not authenticated and not demo mode
        alert('Please sign in to create conversations.');
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
        key={`conversation-creator-${isOpen ? 'open' : 'closed'}`}
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
                  ref={inputRef}
                  type="text"
                  value={conversationName}
                  onChange={(e) => {
                    const newValue = e.target.value;
                    console.log('🎯 Input onChange:', {
                      newValue,
                      currentState: conversationName,
                      target: e.target.value,
                      hasUserEditedName
                    });
                    setConversationName(newValue);
                    setHasUserEditedName(true); // Mark that user has manually edited
                  }}
                  onFocus={() => {
                    console.log('🎯 Input focused, current value:', conversationName);
                    console.log('🎯 Input DOM value:', inputRef.current?.value);
                  }}
                  onBlur={() => {
                    console.log('🎯 Input blurred, current value:', conversationName);
                    console.log('🎯 Input DOM value:', inputRef.current?.value);
                  }}
                  onKeyDown={(e) => {
                    console.log('🎯 Key pressed:', e.key);
                    // Force update with DOM value as fallback
                    setTimeout(() => {
                      const domValue = inputRef.current?.value || '';
                      if (domValue !== conversationName) {
                        console.log('🎯 DOM/State mismatch detected, syncing:', {domValue, conversationName});
                        setConversationName(domValue);
                      }
                    }, 0);
                  }}
                  onInput={(e) => {
                    const inputValue = (e.target as HTMLInputElement).value;
                    console.log('🎯 Input event:', inputValue);
                    // Force sync with state
                    if (inputValue !== conversationName) {
                      setConversationName(inputValue);
                    }
                  }}
                  placeholder="Enter conversation name..."
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent text-sm relative z-10"
                  autoComplete="off"
                  style={{ position: 'relative', zIndex: 10 }}
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
            disabled={!selectedInstructor || !conversationName.trim() || creating || (!isAuthenticated && !isDemoMode)}
            className={`px-4 py-2 text-sm font-medium rounded-lg transition-colors ${
              selectedInstructor && conversationName.trim() && !creating && (isAuthenticated || isDemoMode)
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