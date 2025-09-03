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
  ChevronLeft
} from 'lucide-react';

interface Message {
  id: string;
  conversationId: string;
  senderId: string;
  senderName: string;
  senderAvatar?: string;
  content: string;
  timestamp: string;
  read: boolean;
  delivered: boolean;
  attachments?: Array<{
    type: 'image' | 'file';
    url: string;
    name: string;
  }>;
}

interface Conversation {
  id: string;
  type: 'individual' | 'group';
  name: string;
  avatar?: string;
  lastMessage: string;
  lastMessageTime: string;
  unreadCount: number;
  participants: Array<{
    id: string;
    name: string;
    avatar?: string;
  }>;
  muted: boolean;
  archived: boolean;
}

// Mock data
const mockConversations: Conversation[] = [
  {
    id: '1',
    type: 'individual',
    name: 'Emma Thompson',
    lastMessage: 'Thanks for the great class today!',
    lastMessageTime: '2 min ago',
    unreadCount: 2,
    participants: [
      { id: '1', name: 'Emma Thompson' }
    ],
    muted: false,
    archived: false
  },
  {
    id: '2',
    type: 'group',
    name: 'Morning Yoga Class',
    lastMessage: 'Sarah: See you all tomorrow at 7am!',
    lastMessageTime: '1 hour ago',
    unreadCount: 0,
    participants: [
      { id: '2', name: 'Sarah Johnson' },
      { id: '3', name: 'Michael Chen' },
      { id: '4', name: 'Lisa Wang' }
    ],
    muted: false,
    archived: false
  },
  {
    id: '3',
    type: 'individual',
    name: 'Michael Chen',
    lastMessage: 'Can I reschedule my session?',
    lastMessageTime: '3 hours ago',
    unreadCount: 1,
    participants: [
      { id: '3', name: 'Michael Chen' }
    ],
    muted: false,
    archived: false
  }
];

const mockMessages: Message[] = [
  {
    id: '1',
    conversationId: '1',
    senderId: '1',
    senderName: 'Emma Thompson',
    content: 'Hi! I really enjoyed the yoga class this morning.',
    timestamp: '10:30 AM',
    read: true,
    delivered: true
  },
  {
    id: '2',
    conversationId: '1',
    senderId: 'self',
    senderName: 'You',
    content: 'Thank you Emma! I\'m glad you enjoyed it. How are you feeling?',
    timestamp: '10:32 AM',
    read: true,
    delivered: true
  },
  {
    id: '3',
    conversationId: '1',
    senderId: '1',
    senderName: 'Emma Thompson',
    content: 'Much better! The stretches really helped with my back pain.',
    timestamp: '10:35 AM',
    read: true,
    delivered: true
  },
  {
    id: '4',
    conversationId: '1',
    senderId: '1',
    senderName: 'Emma Thompson',
    content: 'Thanks for the great class today!',
    timestamp: '10:38 AM',
    read: false,
    delivered: true
  }
];

export default function MessagesCenter() {
  const [conversations, setConversations] = useState<Conversation[]>(mockConversations);
  const [selectedConversation, setSelectedConversation] = useState<Conversation | null>(mockConversations[0]);
  const [messages, setMessages] = useState<Message[]>(mockMessages);
  const [newMessage, setNewMessage] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [showMobileConversation, setShowMobileConversation] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Auto-scroll to bottom of messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

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
    conv.lastMessage.toLowerCase().includes(searchTerm.toLowerCase())
  );

  // Send message handler
  const handleSendMessage = () => {
    if (!newMessage.trim() || !selectedConversation) return;

    const message: Message = {
      id: Date.now().toString(),
      conversationId: selectedConversation.id,
      senderId: 'self',
      senderName: 'You',
      content: newMessage,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
      read: false,
      delivered: true
    };

    setMessages([...messages, message]);
    setNewMessage('');

    // Update conversation last message
    setConversations(prev => prev.map(conv => 
      conv.id === selectedConversation.id
        ? { ...conv, lastMessage: newMessage, lastMessageTime: 'Just now' }
        : conv
    ));
  };

  return (
    <div className="flex h-[calc(100vh-8rem)] bg-white rounded-xl border overflow-hidden">
      {/* Conversations List */}
      <div className={`w-full md:w-1/3 lg:w-1/4 border-r bg-gray-50 flex flex-col ${
        showMobileConversation ? 'hidden md:flex' : 'flex'
      }`}>
        {/* Search Header */}
        <div className="p-4 border-b bg-white">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
            <input
              type="text"
              placeholder="Search conversations..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-10 pr-4 py-2.5 bg-gray-100 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
            />
          </div>
          <div className="flex gap-2 mt-3">
            <button className="flex-1 px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border rounded-lg hover:bg-gray-50">
              All
            </button>
            <button className="flex-1 px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border rounded-lg hover:bg-gray-50">
              Unread
            </button>
            <button className="flex-1 px-3 py-1.5 text-sm font-medium text-gray-700 bg-white border rounded-lg hover:bg-gray-50">
              Groups
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
                      {conversation.type === 'group' ? (
                        <Users className="h-6 w-6" />
                      ) : (
                        conversation.name.split(' ').map(n => n[0]).join('')
                      )}
                    </div>
                    {conversation.unreadCount > 0 && (
                      <div className="absolute -top-1 -right-1 w-5 h-5 bg-red-500 text-white text-xs rounded-full flex items-center justify-center">
                        {conversation.unreadCount}
                      </div>
                    )}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between mb-1">
                      <h3 className="text-sm font-semibold text-gray-900 truncate">
                        {conversation.name}
                      </h3>
                      <span className="text-xs text-gray-500">
                        {conversation.lastMessageTime}
                      </span>
                    </div>
                    <p className="text-sm text-gray-600 truncate">
                      {conversation.lastMessage}
                    </p>
                  </div>
                </div>
              </motion.div>
            ))}
          </AnimatePresence>
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
                  {selectedConversation.type === 'group' ? (
                    <Users className="h-5 w-5" />
                  ) : (
                    selectedConversation.name.split(' ').map(n => n[0]).join('')
                  )}
                </div>
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    {selectedConversation.name}
                  </h3>
                  <p className="text-xs text-gray-500">
                    {selectedConversation.type === 'group' 
                      ? `${selectedConversation.participants.length} members`
                      : 'Active now'
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
              {messages
                .filter(msg => msg.conversationId === selectedConversation.id)
                .map((message, index) => (
                  <motion.div
                    key={message.id}
                    initial={{ opacity: 0, y: 10 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: index * 0.05 }}
                    className={`flex ${message.senderId === 'self' ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`flex gap-3 max-w-[70%] ${
                      message.senderId === 'self' ? 'flex-row-reverse' : ''
                    }`}>
                      {message.senderId !== 'self' && (
                        <div className="w-8 h-8 rounded-full bg-gradient-to-r from-blue-500 to-indigo-600 flex items-center justify-center text-white text-xs font-semibold flex-shrink-0">
                          {message.senderName.split(' ').map(n => n[0]).join('')}
                        </div>
                      )}
                      <div>
                        {message.senderId !== 'self' && (
                          <p className="text-xs text-gray-500 mb-1">{message.senderName}</p>
                        )}
                        <div className={`px-4 py-2.5 rounded-2xl ${
                          message.senderId === 'self'
                            ? 'bg-blue-600 text-white'
                            : 'bg-white border'
                        }`}>
                          <p className="text-sm">{message.content}</p>
                        </div>
                        <div className="flex items-center gap-2 mt-1">
                          <span className="text-xs text-gray-500">{message.timestamp}</span>
                          {message.senderId === 'self' && (
                            <span className="text-gray-500">
                              {message.read ? (
                                <CheckCheck className="h-3 w-3 text-blue-500" />
                              ) : message.delivered ? (
                                <CheckCheck className="h-3 w-3" />
                              ) : (
                                <Check className="h-3 w-3" />
                              )}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </motion.div>
                ))}
              {isTyping && (
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
                    onChange={(e) => setNewMessage(e.target.value)}
                    onKeyPress={(e) => {
                      if (e.key === 'Enter' && !e.shiftKey) {
                        e.preventDefault();
                        handleSendMessage();
                      }
                    }}
                    placeholder="Type a message..."
                    className="w-full px-4 py-2.5 bg-gray-100 rounded-lg resize-none focus:outline-none focus:ring-2 focus:ring-blue-500 text-sm"
                    rows={1}
                  />
                  <button className="absolute right-2 bottom-2">
                    <Smile className="h-5 w-5 text-gray-400" />
                  </button>
                </div>
                <button
                  onClick={handleSendMessage}
                  disabled={!newMessage.trim()}
                  className={`p-2.5 rounded-lg transition-colors ${
                    newMessage.trim()
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
    </div>
  );
}