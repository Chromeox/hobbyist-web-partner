'use client';

import React, { useState, useEffect, useRef } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search,
  Send,
  Paperclip,
  MoreVertical,
  Star,
  Archive,
  Trash2,
  Clock,
  Check,
  CheckCheck,
  Bell,
  BellOff,
  Filter,
  Users,
  User,
  MessageSquare,
  Phone,
  Video,
  Info,
  Smile,
  Image as ImageIcon,
  File,
  X,
  ChevronLeft,
  Plus
} from 'lucide-react';

import { simpleMessagingService, SimpleConversation, SimpleMessage } from '@/lib/services/messaging-simple';
import ConversationCreator from '@/components/messaging/ConversationCreator';
import { useSearchParams } from 'next/navigation';

export default function MessagesCenter() {
  const searchParams = useSearchParams();
  const [conversations, setConversations] = useState<SimpleConversation[]>([]);
  const [selectedConversation, setSelectedConversation] = useState<SimpleConversation | null>(null);
  const [messages, setMessages] = useState<SimpleMessage[]>([]);
  const [newMessage, setNewMessage] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [typingUsers, setTypingUsers] = useState<Set<string>>(new Set());
  const [showMobileConversation, setShowMobileConversation] = useState(false);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [showConversationCreator, setShowConversationCreator] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom of messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  // Load conversations on component mount
  useEffect(() => {
    loadConversations();

    // Subscribe to real-time conversation updates
    const unsubscribe = simpleMessagingService.subscribeToConversations((updatedConversations) => {
      setConversations(updatedConversations);
    });

    return () => {
      unsubscribe();
      simpleMessagingService.cleanup();
    };
  }, []);

  // Load messages when conversation changes
  useEffect(() => {
    if (selectedConversation) {
      loadMessages(selectedConversation.id);
      markAsRead(selectedConversation.id);

      // Subscribe to real-time message updates
      const unsubscribe = simpleMessagingService.subscribeToMessages(selectedConversation.id, (updatedMessages) => {
        setMessages(updatedMessages);
      });

      // Subscribe to typing indicators
      const unsubscribeTyping = simpleMessagingService.subscribeToTyping(selectedConversation.id, (data) => {
        setTypingUsers(prev => {
          const newSet = new Set(prev);
          if (data.is_typing) {
            newSet.add(data.user_id);
          } else {
            newSet.delete(data.user_id);
          }
          return newSet;
        });
      });

      return () => {
        unsubscribe();
        unsubscribeTyping();
      };
    }
  }, [selectedConversation]);

  const loadConversations = async () => {
    try {
      setLoading(true);
      const data = await simpleMessagingService.getConversations();
      setConversations(data);

      // Check if we should select a specific conversation from URL params
      const conversationId = searchParams.get('conversation');
      if (conversationId && data.length > 0) {
        const targetConversation = data.find(c => c.id === conversationId);
        if (targetConversation) {
          setSelectedConversation(targetConversation);
          setShowMobileConversation(true);
        }
      } else if (data.length > 0 && !selectedConversation) {
        setSelectedConversation(data[0]);
      }
    } catch (error) {
      console.error('Failed to load conversations:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadMessages = async (conversationId: string) => {
    try {
      const data = await simpleMessagingService.getMessages(conversationId);
      setMessages(data);
    } catch (error) {
      console.error('Failed to load messages:', error);
    }
  };

  const markAsRead = async (conversationId: string) => {
    try {
      await simpleMessagingService.markMessagesAsRead(conversationId);
    } catch (error) {
      console.error('Failed to mark messages as read:', error);
    }
  };

  // Message skeleton loader
  const MessageSkeleton = () => (
    <div className="animate-pulse">
      <div className="flex gap-3 mb-4">
        <div className="w-10 h-10 bg-gray-200 rounded-full"></div>
        <div className="flex-1">
          <div className="h-4 bg-gray-200 rounded w-24 mb-2"></div>
          <div className="h-16 bg-gray-200 rounded-lg"></div>
        </div>
      </div>
    </div>
  );

  // Filter conversations based on search
  const filteredConversations = conversations.filter(conv =>
    conv.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (conv.last_message && conv.last_message.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  // Send message handler
  const handleSendMessage = async () => {
    if (!newMessage.trim() || !selectedConversation || sending) return;

    try {
      setSending(true);
      const sentMessage = await simpleMessagingService.sendMessage(selectedConversation.id, newMessage);

      // For demo conversations, add the message to local state immediately
      if (selectedConversation.id.startsWith('demo-conversation-') && sentMessage) {
        setMessages(prev => [...prev, sentMessage]);
        console.log('Added demo message to local state:', sentMessage);
      }

      setNewMessage('');

      // Stop typing indicator
      if (isTyping) {
        setIsTyping(false);
        await simpleMessagingService.sendTypingIndicator(selectedConversation.id, false);
      }
    } catch (error) {
      console.error('Failed to send message:', error);
    } finally {
      setSending(false);
    }
  };

  // Handle typing indicators
  const handleTyping = async (value: string) => {
    setNewMessage(value);

    if (!selectedConversation) return;

    const wasTyping = isTyping;
    const nowTyping = value.length > 0;

    if (wasTyping !== nowTyping) {
      setIsTyping(nowTyping);
      await simpleMessagingService.sendTypingIndicator(selectedConversation.id, nowTyping);
    }
  };

  // Format timestamp
  const formatTimestamp = (timestamp: string) => {
    const date = new Date(timestamp);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMs / 3600000);
    const diffDays = Math.floor(diffMs / 86400000);

    if (diffMins < 1) return 'Just now';
    if (diffMins < 60) return `${diffMins} min ago`;
    if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
    if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
    return date.toLocaleDateString();
  };

  // Get display name for conversation
  const getConversationDisplayName = (conv: SimpleConversation) => {
    return conv.name;
  };

  // Get avatar initials
  const getAvatarInitials = (conv: SimpleConversation) => {
    if (conv.type === 'group') {
      return <Users className="h-6 w-6" />;
    }
    const name = getConversationDisplayName(conv);
    return name
      .split(' ')
      .map((part) => part[0])
      .join('')
      .toUpperCase();
  };

  // Get sender display name
  const getSenderDisplayName = (message: SimpleMessage) => {
    if (message.sender_id) {
      return message.sender_id === selectedConversation?.instructor_id
        ? 'Instructor'
        : message.sender_id;
    }
    return 'Unknown';
  };

  if (loading) {
    return (
      <div className="flex h-[calc(100vh-8rem)] bg-white rounded-xl border">
        <div className="flex-1 flex items-center justify-center">
          <div className="text-center">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-4" />
            <p className="text-gray-600">Loading conversations...</p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-[calc(100vh-8rem)] bg-white rounded-xl border overflow-hidden">
      {/* Conversations List */}
      <div className={`w-full md:w-1/3 lg:w-1/4 border-r bg-gray-50 flex flex-col ${
        showMobileConversation ? 'hidden md:flex' : 'flex'
      }`}>
        {/* Search Header */}
        <div className="p-4 border-b bg-white">
          <div className="flex items-center gap-2 mb-3">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
              <input
                type="text"
                placeholder="Search conversations..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 bg-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
              />
            </div>
            <button
              onClick={() => setShowConversationCreator(true)}
              className="p-2.5 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
              title="Start new conversation"
            >
              <Plus className="h-5 w-5" />
            </button>
          </div>
          <div className="flex gap-2">
            <button className="flex-1 px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border rounded-lg hover:bg-gray-50">
              All
            </button>
            <button className="flex-1 px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border rounded-lg hover:bg-gray-50">
              Unread
            </button>
            <button className="flex-1 px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border rounded-lg hover:bg-gray-50">
              Instructors
            </button>
          </div>
        </div>

        {/* Conversations */}
        <div className="flex-1 overflow-y-auto">
          <AnimatePresence>
            {filteredConversations.map((conversation, index) => (
              <motion.div
                key={conversation.id}
                initial={{ opacity: 0, x: -20 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: index * 0.05 }}
                onClick={() => {
                  setSelectedConversation(conversation);
                  setShowMobileConversation(true);
                }}
                className={`p-4 border-b hover:bg-white cursor-pointer transition-colors ${
                  selectedConversation?.id === conversation.id ? 'bg-white border-l-4 border-l-blue-500' : ''
                }`}
              >
                <div className="flex items-start gap-3">
                  <div className="relative">
                    <div className="w-12 h-12 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold">
                      {getAvatarInitials(conversation)}
                    </div>
                    {(conversation.unreadCount ?? 0) > 0 && (
                      <div className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
                        {(conversation.unreadCount ?? 0) > 9 ? '9+' : conversation.unreadCount}
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <h3 className="text-sm font-semibold text-gray-900 truncate">
                        {getConversationDisplayName(conversation)}
                      </h3>
                      <span className="text-xs text-gray-500">
                        {conversation.last_message_at ? formatTimestamp(conversation.last_message_at) : ''}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 truncate">
                      {conversation.last_message || 'No messages yet'}
                    </p>
                  </div>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>

          {filteredConversations.length === 0 && (
            <div className="p-8 text-center text-gray-500">
              <MessageSquare className="h-12 w-12 mx-auto mb-3 text-gray-400" />
              <p className="text-base font-medium">No conversations</p>
              <p className="text-sm text-gray-400 mt-1">
                {searchTerm ? 'No conversations match your search' : 'Start by inviting instructors'}
              </p>
            </div>
          )}
        </div>
      </div>

      {/* Message Thread */}
      <div className={`flex-1 flex flex-col ${
        !showMobileConversation ? 'hidden md:flex' : 'flex'
      }`}>
        {selectedConversation ? (
          <>
            {/* Conversation Header */}
            <div className="p-4 border-b bg-white flex items-center justify-between">
              <div className="flex items-center gap-3">
                <button
                  onClick={() => setShowMobileConversation(false)}
                  className="md:hidden"
                >
                  <ChevronLeft className="h-5 w-5" />
                </button>
                <div className="w-10 h-10 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white font-semibold text-sm">
                  {getAvatarInitials(selectedConversation)}
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    {getConversationDisplayName(selectedConversation)}
                  </h3>
                  <p className="text-xs text-gray-500">
                    {selectedConversation.type === 'group'
                      ? `${selectedConversation.participants.length} members`
                      : 'Instructor'
                    }
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-2">
                <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                  <Phone className="h-5 w-5 text-gray-600" />
                </button>
                <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                  <Video className="h-5 w-5 text-gray-600" />
                </button>
                <button className="p-2 hover:bg-gray-100 rounded-lg transition-colors">
                  <Info className="h-5 w-5 text-gray-600" />
                </button>
              </div>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-4 bg-gray-50">
              {messages.map((message, index) => {
                const currentStudioId = selectedConversation?.studio_id ?? null;
                const isOwnMessage = currentStudioId ? message.sender_id === currentStudioId : false;
                const senderName = getSenderDisplayName(message);
                return (
                  <motion.div
                    key={message.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.05 }}
                    className={`flex ${isOwnMessage ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`flex gap-3 max-w-[70%] ${
                      isOwnMessage ? 'flex-row-reverse' : ''
                    }`}>
                      {!isOwnMessage && (
                        <div className="w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white text-xs font-semibold flex-shrink-0">
                          {senderName
                            .split(' ')
                            .map((part) => part[0])
                            .join('')}
                        </div>
                      )}
                      <div>
                        {!isOwnMessage && (
                          <p className="text-xs text-gray-500 mb-1">{senderName}</p>
                        )}
                        <div className={`px-4 py-2.5 rounded-2xl ${
                          isOwnMessage
                            ? 'bg-blue-600 text-white'
                            : 'bg-white border'
                        }`}>
                          <p className="text-sm">{message.content}</p>
                        </div>
                        <div className="flex items-center gap-2 mt-1">
                          <span className="text-xs text-gray-500">
                            {new Date(message.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                          </span>
                          {isOwnMessage && (
                            <span className="text-gray-500">
                              {message.read_at ? (
                                <CheckCheck className="h-3 w-3 text-blue-500" />
                              ) : (
                                <Check className="h-3 w-3" />
                              )}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </motion.div>
                );
              })}

              {typingUsers.size > 0 && (
                <div className="flex items-center gap-2 text-gray-500">
                  <div className="flex gap-1">
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }}></div>
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }}></div>
                    <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }}></div>
                  </div>
                  <span className="text-sm">typing...</span>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Message Input */}
            <div className="p-4 border-t bg-white">
              <div className="flex items-end gap-2">
                <button className="p-2.5 hover:bg-gray-100 rounded-lg transition-colors">
                  <Paperclip className="h-5 w-5 text-gray-600" />
                </button>
                <button className="p-2.5 hover:bg-gray-100 rounded-lg transition-colors">
                  <ImageIcon className="h-5 w-5 text-gray-600" />
                </button>
                <div className="flex-1 relative">
                  <textarea
                    value={newMessage}
                    onChange={(e) => handleTyping(e.target.value)}
                    onKeyPress={(e) => {
                      if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        handleSendMessage();
                      }
                    }}
                    placeholder="Type a message..."
                    className="w-full px-4 py-2.5 bg-gray-100 rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm text-gray-900 placeholder-gray-500"
                    rows={1}
                  />
                  <button className="absolute right-2 bottom-2">
                    <Smile className="h-5 w-5 text-gray-400" />
                  </button>
                </div>
                <button
                  onClick={handleSendMessage}
                  disabled={!newMessage.trim() || sending}
                  className={`p-2.5 rounded-lg transition-colors ${
                    newMessage.trim() && !sending
                      ? 'bg-blue-600 hover:bg-blue-700 text-white'
                      : 'bg-gray-100 text-gray-400 cursor-not-allowed'
                  }`}
                >
                  <Send className="h-5 w-5" />
                </button>
              </div>
            </div>
          </>
        ) : (
          <div className="flex-1 flex items-center justify-center text-gray-500">
            <div className="text-center">
              <MessageSquare className="h-12 w-12 mx-auto mb-3 text-gray-400" />
              <p className="text-base font-medium">Select a conversation</p>
              <p className="text-sm text-gray-400 mt-1">Choose a conversation to start messaging</p>
            </div>
          </div>
        )}
      </div>

      {/* Conversation Creator Modal */}
      <ConversationCreator
        isOpen={showConversationCreator}
        onClose={() => setShowConversationCreator(false)}
        onConversationCreated={(conversationId, conversationData) => {
          // Check if it's a demo conversation
          if (conversationId.startsWith('demo-conversation-')) {
            console.log('Demo conversation created, adding to UI state:', conversationId, conversationData);

            // Create a mock conversation for the UI using the provided data
            const mockConversation: SimpleConversation = {
              id: conversationId,
              instructor_id: conversationData?.instructorId || 'test-instructor-001',
              type: 'individual',
              name: conversationData?.name || 'Demo Conversation',
              participants: [conversationData?.instructorId || 'test-instructor-001'],
              last_message: `Welcome to your conversation with ${conversationData?.instructorName || 'the instructor'}! This is a demo conversation for testing the messaging UI.`,
              last_message_at: new Date().toISOString(),
              created_at: new Date().toISOString(),
              updated_at: new Date().toISOString(),
              unreadCount: 0
            };

            // Add to conversations state
            setConversations(prev => [mockConversation, ...prev]);
            setSelectedConversation(mockConversation);
            setShowMobileConversation(true);

            console.log('Demo conversation added to UI and selected');
          } else {
            // Real conversation - reload from database
            loadConversations().then(() => {
              const newConversation = conversations.find(c => c.id === conversationId);
              if (newConversation) {
                setSelectedConversation(newConversation);
                setShowMobileConversation(true);
              }
            });
          }
        }}
      />
    </div>
  );
}
