'use client';

import { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  Search,
  Filter,
  Star,
  MapPin,
  Clock,
  Users,
  Award,
  CheckCircle,
  Sparkles,
  X,
  Calendar,
  MessageCircle
} from 'lucide-react';

interface Instructor {
  id: string;
  displayName: string;
  profileImage: string;
  coverImage?: string;
  bio: string;
  specialties: string[];
  hourlyRate: number;
  rating: number;
  totalReviews: number;
  totalStudents: number;
  yearsExperience: number;
  isVerified: boolean;
  isFeatured: boolean;
  tagline: string;
  location: string;
  languages: string[];
  travelRadius: number;
  certifications: Array<{
    name: string;
    issuer: string;
    year: string;
  }>;
  reviews: Array<{
    studentName: string;
    rating: number;
    comment: string;
    date: string;
  }>;
  upcomingClasses: Array<{
    id: string;
    name: string;
    date: string;
    studio: string;
    spotsLeft: number;
  }>;
}

const mockInstructors: Instructor[] = [
  {
    id: '1',
    displayName: 'Sarah Chen',
    profileImage: 'https://images.unsplash.com/photo-1494790108755-2616b612b647?w=400',
    coverImage: 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800',
    bio: 'Passionate pottery instructor with over 10 years of experience. Specializes in wheel throwing and glazing techniques.',
    specialties: ['Pottery', 'Ceramics', 'Glazing', 'Wheel Throwing'],
    hourlyRate: 85,
    rating: 4.9,
    totalReviews: 127,
    totalStudents: 450,
    yearsExperience: 10,
    isVerified: true,
    isFeatured: true,
    tagline: 'Creating beauty through clay',
    location: 'Kitsilano, Vancouver',
    languages: ['English', 'Mandarin'],
    travelRadius: 15,
    certifications: [
      { name: 'Advanced Ceramics', issuer: 'Emily Carr University', year: '2018' },
      { name: 'Teaching Certificate', issuer: 'Emily Carr University', year: '2015' }
    ],
    reviews: [
      {
        studentName: 'Jessica M.',
        rating: 5,
        comment: 'Best pottery instructor in Vancouver. Learned so much in just one session!',
        date: '1 week ago'
      }
    ],
    upcomingClasses: [
      { id: '1', name: 'Beginner Wheel Throwing', date: 'Tue 7pm', studio: 'Clay Studio Vancouver', spotsLeft: 3 },
      { id: '2', name: 'Glazing Workshop', date: 'Sat 10am', studio: 'Kitsilano Arts', spotsLeft: 5 }
    ]
  },
  {
    id: '2',
    displayName: 'Marcus Johnson',
    profileImage: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
    bio: 'Professional music producer and sound engineer with expertise in Ableton Live and mixing.',
    specialties: ['Music Production', 'Ableton Live', 'Sound Engineering', 'Mixing'],
    hourlyRate: 120,
    rating: 4.8,
    totalReviews: 89,
    totalStudents: 200,
    yearsExperience: 8,
    isVerified: true,
    isFeatured: false,
    tagline: 'Bringing your musical vision to life',
    location: 'Gastown, Vancouver',
    languages: ['English', 'French'],
    travelRadius: 20,
    certifications: [
      { name: 'Ableton Certified Trainer', issuer: 'Ableton', year: '2020' }
    ],
    reviews: [],
    upcomingClasses: []
  }
];

export default function InstructorMarketplace() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSpecialty, setSelectedSpecialty] = useState('');
  const [selectedInstructor, setSelectedInstructor] = useState<Instructor | null>(null);
  const [activeTab, setActiveTab] = useState<'about' | 'reviews' | 'schedule'>('about');
  const [invitingInstructorId, setInvitingInstructorId] = useState<string | null>(null);
  const [inviteStatus, setInviteStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const specialties = ['All', 'Pottery', 'Music Production', 'Photography', 'Fitness', 'Cooking'];

  const filteredInstructors = mockInstructors.filter(instructor => {
    const matchesSearch = instructor.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         instructor.specialties.some(s => s.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesSpecialty = selectedSpecialty === '' || selectedSpecialty === 'All' ||
                            instructor.specialties.includes(selectedSpecialty);
    return matchesSearch && matchesSpecialty;
  });

  const handleInviteInstructor = async (instructorId: string) => {
    setInvitingInstructorId(instructorId);
    setInviteStatus('sending');

    try {
      // Simulate API call
      await new Promise(resolve => setTimeout(resolve, 1500));
      setInviteStatus('sent');
    } catch (error) {
      setInviteStatus('error');
    } finally {
      setInvitingInstructorId(null);
      setTimeout(() => setInviteStatus('idle'), 2000);
    }
  };

  const renderInstructorCard = (instructor: Instructor) => (
    <motion.div
      key={instructor.id}
      className="bg-gray-800 rounded-xl overflow-hidden cursor-pointer"
      onClick={() => setSelectedInstructor(instructor)}
      whileHover={{ y: -4 }}
      transition={{ duration: 0.2 }}
    >
      <div className="relative h-48">
        <img
          src={instructor.coverImage || 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800'}
          alt={instructor.displayName}
          className="w-full h-full object-cover"
        />
        {instructor.isFeatured && (
          <div className="absolute top-3 right-3 flex items-center gap-1 px-2 py-1 bg-yellow-500/20 backdrop-blur-sm rounded-full">
            <Sparkles className="w-4 h-4 text-yellow-400" />
            <span className="text-xs text-yellow-400">Featured</span>
          </div>
        )}
        <div className="absolute bottom-3 left-3">
          <img
            src={instructor.profileImage}
            alt={instructor.displayName}
            className="w-12 h-12 rounded-full border-2 border-white"
          />
        </div>
      </div>

      <div className="p-4">
        <div className="flex items-center justify-between mb-2">
          <h3 className="font-semibold text-white">{instructor.displayName}</h3>
          {instructor.isVerified && (
            <CheckCircle className="w-4 h-4 text-blue-400" />
          )}
        </div>

        <p className="text-sm text-gray-400 mb-3">{instructor.tagline}</p>

        <div className="flex items-center gap-4 text-sm text-gray-400 mb-3">
          <div className="flex items-center gap-1">
            <Star className="w-4 h-4 text-yellow-400 fill-current" />
            <span>{instructor.rating}</span>
          </div>
          <div className="flex items-center gap-1">
            <MapPin className="w-4 h-4" />
            <span>{instructor.location}</span>
          </div>
        </div>

        <div className="flex flex-wrap gap-1 mb-4">
          {instructor.specialties.slice(0, 3).map((specialty, index) => (
            <span
              key={index}
              className="px-2 py-1 bg-purple-500/20 text-purple-300 text-xs rounded-full"
            >
              {specialty}
            </span>
          ))}
        </div>

        <div className="flex items-center justify-between">
          <span className="text-white font-semibold">${instructor.hourlyRate}/hr</span>
          <button
            onClick={(e) => {
              e.stopPropagation();
              handleInviteInstructor(instructor.id);
            }}
            className="px-4 py-2 bg-purple-600 hover:bg-purple-700 text-white text-sm rounded-lg transition-colors"
            disabled={invitingInstructorId === instructor.id || inviteStatus === 'sent'}
          >
            {invitingInstructorId === instructor.id && (
              <div className="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin mr-2 inline-block" />
            )}
            {invitingInstructorId === instructor.id ? 'Sending...' : inviteStatus === 'sent' ? 'Sent!' : 'Invite'}
          </button>
        </div>
      </div>
    </motion.div>
  );

  const renderInstructorProfile = () => (
    <motion.div
      className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <motion.div
        className="bg-gray-800 rounded-xl max-w-4xl w-full max-h-[90vh] overflow-hidden"
        initial={{ scale: 0.95, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        exit={{ scale: 0.95, opacity: 0 }}
      >
        {selectedInstructor && (
          <>
            {/* Header */}
            <div className="relative h-64">
              <img
                src={selectedInstructor.coverImage || 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=1200'}
                alt={selectedInstructor.displayName}
                className="w-full h-full object-cover"
              />
              <button
                className="absolute top-4 right-4 w-10 h-10 bg-black/50 backdrop-blur-sm rounded-full flex items-center justify-center text-white hover:bg-black/70 transition-colors"
                onClick={() => setSelectedInstructor(null)}
              >
                <X className="w-5 h-5" />
              </button>

              <div className="absolute bottom-6 left-6 right-6">
                <div className="flex items-end gap-4">
                  <img
                    src={selectedInstructor.profileImage}
                    alt={selectedInstructor.displayName}
                    className="w-24 h-24 rounded-full border-4 border-white"
                  />
                  <div className="flex-1">
                    <div className="flex items-center gap-3">
                      <h2 className="text-2xl font-bold text-white">{selectedInstructor.displayName}</h2>
                      {selectedInstructor.isVerified && (
                        <div className="flex items-center gap-1 px-2 py-1 bg-blue-500/20 rounded-full">
                          <CheckCircle className="w-4 h-4 text-blue-400" />
                          <span className="text-xs text-blue-400">Verified</span>
                        </div>
                      )}
                      {selectedInstructor.isFeatured && (
                        <div className="flex items-center gap-1 px-2 py-1 bg-yellow-500/20 rounded-full">
                          <Sparkles className="w-4 h-4 text-yellow-400" />
                          <span className="text-xs text-yellow-400">Featured</span>
                        </div>
                      )}
                    </div>
                    <p className="text-gray-200 mt-1">{selectedInstructor.tagline}</p>
                  </div>
                </div>
              </div>
            </div>

            {/* Content */}
            <div className="p-6 max-h-96 overflow-y-auto">
              {/* Stats */}
              <div className="grid grid-cols-4 gap-4 mb-6">
                <div className="text-center">
                  <div className="flex items-center justify-center gap-1 text-2xl font-bold text-white">
                    <Star className="w-5 h-5 text-yellow-400 fill-current" />
                    {selectedInstructor.rating}
                  </div>
                  <p className="text-sm text-gray-400">{selectedInstructor.totalReviews} reviews</p>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-white">{selectedInstructor.totalStudents}</div>
                  <p className="text-sm text-gray-400">Students taught</p>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-white">{selectedInstructor.yearsExperience}</div>
                  <p className="text-sm text-gray-400">Years experience</p>
                </div>
                <div className="text-center">
                  <div className="text-2xl font-bold text-white">${selectedInstructor.hourlyRate}</div>
                  <p className="text-sm text-gray-400">Per hour</p>
                </div>
              </div>

              {/* Tabs */}
              <div className="flex gap-1 mb-6 bg-gray-700 rounded-lg p-1">
                {(['about', 'reviews', 'schedule'] as const).map((tab) => (
                  <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`flex-1 py-2 px-4 rounded-md text-sm font-medium transition-colors capitalize ${
                      activeTab === tab ? 'bg-purple-600 text-white' : 'text-gray-300 hover:text-white'
                    }`}
                  >
                    {tab}
                  </button>
                ))}
              </div>

              {/* Tab Content */}
              {activeTab === 'about' && (
                <div className="space-y-6">
                  <div>
                    <h3 className="text-lg font-semibold text-white mb-3">About</h3>
                    <p className="text-gray-300">{selectedInstructor.bio}</p>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-white mb-3">Specialties</h3>
                    <div className="flex flex-wrap gap-2">
                      {selectedInstructor.specialties.map((specialty, index) => (
                        <span
                          key={index}
                          className="px-3 py-1 bg-purple-500/20 text-purple-300 rounded-full text-sm"
                        >
                          {specialty}
                        </span>
                      ))}
                    </div>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-white mb-3">Certifications</h3>
                    <div className="space-y-3">
                      {selectedInstructor.certifications.map((cert, i) => (
                        <div key={i} className="flex items-center gap-3">
                          <Award className="w-5 h-5 text-purple-400" />
                          <div>
                            <p className="text-white">{cert.name}</p>
                            <p className="text-sm text-gray-400">{cert.issuer} - {cert.year}</p>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {activeTab === 'reviews' && (
                <div>
                  {selectedInstructor.reviews.length > 0 ? (
                    selectedInstructor.reviews.map((review, i) => (
                      <div key={i} className="border-b border-gray-700 pb-4 mb-4 last:border-b-0">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center gap-2">
                            <div className="flex">
                              {[...Array(5)].map((_, i) => (
                                <Star
                                  key={i}
                                  className={`w-4 h-4 ${i < review.rating ? 'text-yellow-400 fill-current' : 'text-gray-500'}`}
                                />
                              ))}
                            </div>
                            <span className="text-white font-medium">{review.studentName}</span>
                          </div>
                          <span className="text-sm text-gray-400">{review.date}</span>
                        </div>
                        <p className="text-gray-300">{review.comment}</p>
                      </div>
                    ))
                  ) : (
                    <p className="text-gray-400 text-center py-8">No reviews yet</p>
                  )}
                </div>
              )}

              {/* Action Buttons */}
              <div className="flex gap-3 mt-6 pt-6 border-t border-gray-700">
                <button className="flex-1 px-6 py-3 bg-purple-600 hover:bg-purple-700 text-white rounded-lg font-medium transition-colors">
                  Send Message
                </button>
                <button className="flex-1 px-6 py-3 bg-gray-700 hover:bg-gray-600 text-white rounded-lg font-medium transition-colors">
                  Schedule Meeting
                </button>
              </div>
            </div>
          </>
        )}
      </motion.div>
    </motion.div>
  );

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 to-gray-800 p-6">
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Instructor Marketplace</h1>
        <p className="text-gray-400">Discover and invite talented instructors to teach at your studio</p>
      </div>

      {/* Search and Filters */}
      <div className="flex gap-4 mb-8">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="Search instructors or specialties..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 bg-gray-800 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
          />
        </div>

        <select
          value={selectedSpecialty}
          onChange={(e) => setSelectedSpecialty(e.target.value)}
          className="px-4 py-3 bg-gray-800 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
        >
          {specialties.map(specialty => (
            <option key={specialty} value={specialty === 'All' ? '' : specialty}>
              {specialty}
            </option>
          ))}
        </select>

        <button className="px-4 py-3 bg-gray-800 text-white rounded-lg hover:bg-gray-700 transition-colors flex items-center gap-2">
          <Filter className="w-5 h-5" />
          More Filters
        </button>
      </div>

      {/* Featured Badge */}
      <div className="bg-gradient-to-r from-yellow-500/20 to-orange-500/20 rounded-xl p-4 mb-8 border border-yellow-500/30">
        <div className="flex items-center gap-3">
          <Sparkles className="w-6 h-6 text-yellow-400" />
          <div>
            <p className="text-white font-medium">Featured Instructors</p>
            <p className="text-sm text-gray-400">Top-rated professionals verified by our team</p>
          </div>
        </div>
      </div>

      {/* Instructor Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {filteredInstructors.map(renderInstructorCard)}
      </div>

      {/* Instructor Profile Modal */}
      <AnimatePresence>
        {selectedInstructor && renderInstructorProfile()}
      </AnimatePresence>
    </div>
  );
}