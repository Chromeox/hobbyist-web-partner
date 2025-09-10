'use client';

import React, { useState } from 'react';
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
  Plus,
  Heart,
  Send,
  Calendar,
  DollarSign,
  TrendingUp,
  Shield,
  Instagram,
  Globe,
  Youtube,
  BookOpen,
  Briefcase,
  Languages,
  X,
  ChevronRight,
  Badge,
  Sparkles,
  Loader2
} from 'lucide-react';

interface Instructor {
  id: string;
  displayName: string;
  slug: string;
  tagline: string;
  bio: string;
  profileImage: string;
  coverImage?: string;
  specialties: string[];
  certifications: {
    name: string;
    issuer: string;
    year: string;
  }[];
  yearsExperience: number;
  languages: string[];
  isVerified: boolean;
  isFeatured: boolean;
  rating: number;
  totalReviews: number;
  totalStudents: number;
  totalClasses: number;
  hourlyRate: number;
  travelRadius: number;
  availability: {
    monday: boolean;
    tuesday: boolean;
    wednesday: boolean;
    thursday: boolean;
    friday: boolean;
    saturday: boolean;
    sunday: boolean;
  };
  recentReviews: {
    id: string;
    studentName: string;
    rating: number;
    comment: string;
    date: string;
  }[];
  portfolio: {
    type: 'image' | 'video';
    url: string;
    caption: string;
  }[];
  social: {
    website?: string;
    instagram?: string;
    youtube?: string;
  };
  upcomingClasses: {
    id: string;
    name: string;
    date: string;
    studio: string;
    spotsLeft: number;
  }[];
}

export default function InstructorMarketplace() {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedSpecialty, setSelectedSpecialty] = useState('all');
  const [selectedInstructor, setSelectedInstructor] = useState<Instructor | null>(null);
  const [showInviteModal, setShowInviteModal] = useState(false);
  const [activeTab, setActiveTab] = useState('discover');
  const [invitingInstructorId, setInvitingInstructorId] = useState<string | null>(null);
  const [inviteStatus, setInviteStatus] = useState<'idle' | 'sending' | 'sent' | 'error'>('idle');

  const specialties = [
    'All Specialties',
    'Pottery & Ceramics',
    'Painting & Drawing',
    'Music & DJ',
    'Fencing & Archery',
    'Jewelry Making',
    'Flower Arranging',
    'Culinary Arts',
    'Glass Blowing'
  ];

  const instructors: Instructor[] = [
    {
      id: '1',
      displayName: 'Emma Rodriguez',
      slug: 'emma-rodriguez',
      tagline: 'Master Potter & Ceramic Artist',
      bio: 'With 15 years of experience in ceramics, I specialize in wheel throwing and Japanese pottery techniques. My classes focus on mindfulness through clay.',
      profileImage: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
      coverImage: 'https://images.unsplash.com/photo-1565193566173-7a0ee3dbe261?w=800',
      specialties: ['Pottery Wheel', 'Hand Building', 'Raku Firing', 'Glazing'],
      certifications: [
        { name: 'Master Ceramist', issuer: 'Canadian Craft Council', year: '2019' },
        { name: 'Teaching Certificate', issuer: 'Emily Carr University', year: '2015' }
      ],
      yearsExperience: 15,
      languages: ['English', 'Spanish'],
      isVerified: true,
      isFeatured: true,
      rating: 4.9,
      totalReviews: 127,
      totalStudents: 890,
      totalClasses: 245,
      hourlyRate: 85,
      travelRadius: 20,
      availability: {
        monday: true,
        tuesday: true,
        wednesday: false,
        thursday: true,
        friday: true,
        saturday: true,
        sunday: false
      },
      recentReviews: [
        {
          id: '1',
          studentName: 'Sarah M.',
          rating: 5,
          comment: 'Emma is an incredible teacher! Her patience and expertise made my first pottery class amazing.',
          date: '2 days ago'
        },
        {
          id: '2',
          studentName: 'John K.',
          rating: 5,
          comment: 'Best pottery instructor in Vancouver. Learned so much in just one session!',
          date: '1 week ago'
        }
      ],
      portfolio: [
        { type: 'image', url: '/pottery1.jpg', caption: 'Student work from beginners class' },
        { type: 'video', url: '/demo.mp4', caption: 'Wheel throwing demonstration' }
      ],
      social: {
        website: 'emmapottery.com',
        instagram: '@emmapottery',
        youtube: 'EmmaCeramics'
      },
      upcomingClasses: [
        { id: '1', name: 'Beginner Wheel Throwing', date: 'Tomorrow 2pm', studio: 'Downtown Hub', spotsLeft: 3 },
        { id: '2', name: 'Glazing Workshop', date: 'Sat 10am', studio: 'Kitsilano Arts', spotsLeft: 5 }
      ]
    },
    {
      id: '2',
      displayName: 'Marcus Chen',
      slug: 'marcus-chen',
      tagline: 'DJ & Electronic Music Producer',
      bio: 'Professional DJ with 10+ years touring experience. I teach mixing, beat matching, and music production using industry-standard equipment.',
      profileImage: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
      specialties: ['DJ Mixing', 'Music Production', 'Beat Making', 'Live Performance'],
      certifications: [
        { name: 'Ableton Certified Trainer', issuer: 'Ableton', year: '2020' }
      ],
      yearsExperience: 10,
      languages: ['English', 'Mandarin'],
      isVerified: true,
      isFeatured: false,
      rating: 4.8,
      totalReviews: 89,
      totalStudents: 456,
      totalClasses: 178,
      hourlyRate: 95,
      travelRadius: 30,
      availability: {
        monday: false,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: false,
        saturday: true,
        sunday: true
      },
      recentReviews: [],
      portfolio: [],
      social: {
        instagram: '@djmarcuschen'
      },
      upcomingClasses: []
    },
    {
      id: '3',
      displayName: 'Sophie Laurent',
      slug: 'sophie-laurent',
      tagline: 'Classical Fencing Instructor',
      bio: 'Olympic-trained fencer specializing in épée and foil. Teaching classical technique with modern training methods.',
      profileImage: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400',
      specialties: ['Épée', 'Foil', 'Classical Fencing', 'Competition Training'],
      certifications: [
        { name: 'Level 3 Coach', issuer: 'Canadian Fencing Federation', year: '2018' }
      ],
      yearsExperience: 12,
      languages: ['English', 'French'],
      isVerified: true,
      isFeatured: false,
      rating: 4.7,
      totalReviews: 64,
      totalStudents: 234,
      totalClasses: 156,
      hourlyRate: 75,
      travelRadius: 25,
      availability: {
        monday: true,
        tuesday: false,
        wednesday: true,
        thursday: false,
        friday: true,
        saturday: true,
        sunday: true
      },
      recentReviews: [],
      portfolio: [],
      social: {},
      upcomingClasses: []
    }
  ];

  const filteredInstructors = instructors.filter(instructor => {
    const matchesSearch = instructor.displayName.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         instructor.specialties.some(s => s.toLowerCase().includes(searchQuery.toLowerCase()));
    const matchesSpecialty = selectedSpecialty === 'all' || 
                            instructor.specialties.some(s => s.toLowerCase().includes(selectedSpecialty.toLowerCase()));
    return matchesSearch && matchesSpecialty;
  });

  const handleInviteInstructor = async (instructorId: string) => {
    setInvitingInstructorId(instructorId);
    setInviteStatus('sending');
    try {
      // In a real app, you'd get the studioId from the authenticated user's session
      const studioId = 'current_studio_id'; // Placeholder

      const response = await fetch('/api/instructors/invite', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ studioId, instructorId }),
      });

      if (response.ok) {
        setInviteStatus('sent');
      } else {
        const errorData = await response.json();
        console.error('Failed to send invite:', errorData.error);
        setInviteStatus('error');
      }
    } catch (error) {
      console.error('Error sending invite:', error);
      setInviteStatus('error');
    } finally {
      setInvitingInstructorId(null);
      // Reset status after a short delay to show feedback
      setTimeout(() => setInviteStatus('idle'), 2000);
    }
  };

  const renderInstructorCard = (instructor: Instructor) => (
    <motion.div
      key={instructor.id}
      className="glass-morphism rounded-xl overflow-hidden cursor-pointer hover:scale-[1.02] transition-transform"
      onClick={() => setSelectedInstructor(instructor)}
      whileHover={{ y: -4 }}
    >
      <div className="relative h-48">
        <img 
          src={instructor.coverImage || 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800'} 
          alt={instructor.displayName}
          className="w-full h-full object-cover"
        />
        <div className="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent" />
        
        {instructor.isFeatured && (
          <div className="absolute top-4 right-4 px-3 py-1 bg-yellow-500/90 text-black text-xs font-semibold rounded-full flex items-center gap-1">
            <Sparkles className="w-3 h-3" />
            Featured
          </div>
        )}
        
        <div className="absolute bottom-4 left-4 flex items-end gap-3">
          <img 
            src={instructor.profileImage} 
            alt={instructor.displayName}
            className="w-16 h-16 rounded-full border-3 border-white"
          />
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-lg font-semibold text-white">{instructor.displayName}</h3>
              {instructor.isVerified && (
                <CheckCircle className="w-4 h-4 text-blue-400" />
              )}
            </div>
            <p className="text-sm text-gray-200">{instructor.tagline}</p>
          </div>
        </div>
      </div>

      <div className="p-5">
        <div className="flex items-center gap-4 mb-3">
          <div className="flex items-center gap-1">
            <Star className="w-4 h-4 text-yellow-400 fill-current" />
            <span className="text-sm font-medium text-white">{instructor.rating}</span>
            <span className="text-xs text-gray-400">({instructor.totalReviews})</span>
          </div>
          <div className="flex items-center gap-1 text-sm text-gray-400">
            <Users className="w-4 h-4" />
            <span>{instructor.totalStudents} students</span>
          </div>
          <div className="flex items-center gap-1 text-sm text-gray-400">
            <BookOpen className="w-4 h-4" />
            <span>{instructor.totalClasses} classes</span>
          </div>
        </div>

        <div className="flex flex-wrap gap-2 mb-4">
          {instructor.specialties.slice(0, 3).map(specialty => (
            <span
              key={specialty}
              className="px-2 py-1 bg-purple-500/20 text-purple-400 text-xs rounded-full"
            >
              {specialty}
            </span>
          ))}
          {instructor.specialties.length > 3 && (
            <span className="px-2 py-1 bg-gray-700 text-gray-400 text-xs rounded-full">
              +{instructor.specialties.length - 3} more
            </span>
          )}
        </div>

        <div className="flex items-center justify-between pt-3 border-t border-gray-700">
          <div>
            <span className="text-lg font-semibold text-white">${instructor.hourlyRate}</span>
            <span className="text-sm text-gray-400">/hour</span>
          </div>
          <div className="flex gap-2">
            <button
              onClick={(e) => {
                e.stopPropagation();
                // Handle favorite
              }}
              className="p-2 hover:bg-white/10 rounded-lg"
            >
              <Heart className="w-4 h-4 text-gray-400" />
            </button>
            <button
              onClick={(e) => {
                e.stopPropagation();
                handleInviteInstructor(instructor.id);
              }}
              disabled={invitingInstructorId === instructor.id || inviteStatus === 'sent'}
              className="px-3 py-1.5 bg-purple-600 text-white text-sm rounded-lg hover:bg-purple-700 flex items-center gap-1 disabled:opacity-50"
            >
              {invitingInstructorId === instructor.id ? (
                <Loader2 className="w-3 h-3 animate-spin" />
              ) : inviteStatus === 'sent' ? (
                <Check className="w-3 h-3" />
              ) : (
                <Send className="w-3 h-3" />
              )}
              {invitingInstructorId === instructor.id ? 'Sending...' : inviteStatus === 'sent' ? 'Sent!' : 'Invite'}
            </button>
          </div>
        </div>
      </div>
    </motion.div>
  );

  const renderInstructorProfile = () => {
    if (!selectedInstructor) return null;

    return (
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        exit={{ opacity: 0 }}
        className="fixed inset-0 z-50 bg-black/80 overflow-y-auto"
      >
        <div className="min-h-screen py-8 px-4">
          <motion.div
            initial={{ scale: 0.95, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="max-w-4xl mx-auto glass-morphism rounded-2xl overflow-hidden"
          >
            {/* Header */}
            <div className="relative h-64">
              <img 
                src={selectedInstructor.coverImage || 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=1200'} 
                alt={selectedInstructor.displayName}
                className="w-full h-full object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-black/80 to-transparent" />
              
              <button
                onClick={() => setSelectedInstructor(null)}
                className="absolute top-4 right-4 p-2 bg-black/50 rounded-lg hover:bg-black/70"
              >
                <X className="w-5 h-5 text-white" />
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
                        }
                      </div>
                    }
                    <p className="text-gray-200 mt-1">{selectedInstructor.tagline}</p>
                  </div>
                }
              </div>
            }

            {/* Content */}
            <div className="p-6">
              {/* Stats */}
              <div className="grid grid-cols-4 gap-4 mb-6">
                <div className="text-center">
                  <div className="flex items-center justify-center gap-1 text-2xl font-bold text-white">
                    <Star className="w-5 h-5 text-yellow-400 fill-current" />
                    {selectedInstructor.rating}
                  </div>
                  <p className="text-sm text-gray-400">{selectedInstructor.totalReviews} reviews</p>
                }
                <div className="text-center">
                  <div className="text-2xl font-bold text-white">{selectedInstructor.totalStudents}</div>
                  <p className="text-sm text-gray-400">Students taught</p>
                }
                <div className="text-center">
                  <div className="text-2xl font-bold text-white">{selectedInstructor.yearsExperience}</div>
                  <p className="text-sm text-gray-400">Years experience</p>
                }
                <div className="text-center">
                  <div className="text-2xl font-bold text-white">${selectedInstructor.hourlyRate}</div>
                  <p className="text-sm text-gray-400">Per hour</p>
                }
              </div>

              {/* Tabs */}
              <div className="flex gap-2 mb-6 border-b border-gray-700">
                {['about', 'reviews', 'schedule', 'portfolio'].map(tab => (
                  <button
                    key={tab}
                    onClick={() => setActiveTab(tab)}
                    className={`px-4 py-2 capitalize ${
                      activeTab === tab
                        ? 'text-purple-400 border-b-2 border-purple-400'
                        : 'text-gray-400 hover:text-white'
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
                  }

                  <div>
                    <h3 className="text-lg font-semibold text-white mb-3">Specialties</h3>
                    <div className="flex flex-wrap gap-2">
                      {selectedInstructor.specialties.map(specialty => (
                        <span
                          key={specialty}
                          className="px-3 py-1 bg-purple-500/20 text-purple-400 rounded-full"
                        >
                          {specialty}
                        </span>
                      ))}
                    }
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-white mb-3">Certifications</h3>
                    <div className="space-y-3">
                      {selectedInstructor.certifications.map((cert, i) => (
                        <div key={i} className="flex items-center gap-3">
                          <Award className="w-5 h-5 text-purple-400" />
                          <div>
                            <p className="text-white">{cert.name}</p>
                            <p className="text-sm text-gray-400">{cert.issuer} • {cert.year}</p>
                          }
                        }
                      </div>
                    }

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <h3 className="text-lg font-semibold text-white mb-3">Languages</h3>
                      <div className="flex gap-2">
                        {selectedInstructor.languages.map(lang => (
                          <span key={lang} className="text-gray-300">{lang}</span>
                        ))}
                      </div>
                    }
                    <div>
                      <h3 className="text-lg font-semibold text-white mb-3">Travel Radius</h3>
                      <p className="text-gray-300">{selectedInstructor.travelRadius} km</p>
                    }
                  </div>
                }

              {activeTab === 'reviews' && (
                <div className="space-y-4">
                  {selectedInstructor.recentReviews.length > 0 ? (
                    selectedInstructor.recentReviews.map(review => (
                      <div key={review.id} className="p-4 bg-gray-800 rounded-lg">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center gap-2">
                            <div className="flex">
                              {[...Array(5)].map((_, i) => (
                                <Star
                                  key={i}
                                  className={`w-4 h-4 ${
                                    i < review.rating ? 'text-yellow-400 fill-current' : 'text-gray-600'
                                  }`}
                                />
                              ))}
                            </div>
                            <span className="text-white font-medium">{review.studentName}</span>
                          }
                          <span className="text-sm text-gray-400">{review.date}</span>
                        }
                        <p className="text-gray-300">{review.comment}</p>
                      }
                    ))
                  ) : (
                    <p className="text-gray-400 text-center py-8">No reviews yet</p>
                  }
                }
              )}

              {/* Action Buttons */}
              <div className="flex gap-3 mt-6 pt-6 border-t border-gray-700">
                <button className="flex-1 py-3 bg-purple-600 text-white rounded-lg hover:bg-purple-700 flex items-center justify-center gap-2">
                  <Send className="w-4 h-4" />
                  Send Invitation
                </button>
                <button className="flex-1 py-3 bg-gray-800 text-white rounded-lg hover:bg-gray-700 flex items-center justify-center gap-2">
                  <Calendar className="w-4 h-4" />
                  View Schedule
                </button>
                <button className="px-4 py-3 bg-gray-800 text-white rounded-lg hover:bg-gray-700">
                  <Heart className="w-4 h-4" />
                </button>
              </div>
            }
          </motion.div>
        }
      </motion.div>
    );
  };

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-white mb-2">Instructor Marketplace</h1>
        <p className="text-gray-400">Discover and invite talented instructors to teach at your studio</p>
      }

      {/* Search and Filters */}
      <div className="flex flex-col lg:flex-row gap-4 mb-8">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" />
          <input
            type="text"
            placeholder="Search instructors by name or specialty..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-3 bg-gray-800 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
          />
        }
        
        <select
          value={selectedSpecialty}
          onChange={(e) => setSelectedSpecialty(e.target.value)}
          className="px-4 py-3 bg-gray-800 text-white rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500"
        >
          <option value="all">All Specialties</option>
          {specialties.slice(1).map(specialty => (
            <option key={specialty} value={specialty}>{specialty}</option>
          ))}
        </select>

        <button className="px-4 py-3 bg-gray-800 text-white rounded-lg hover:bg-gray-700 flex items-center gap-2">
          <Filter className="w-5 h-5" />
          More Filters
        </button>
      }

      {/* Featured Badge */}
      <div className="mb-6 p-4 bg-gradient-to-r from-purple-500/20 to-pink-500/20 rounded-lg border border-purple-500/30">
        <div className="flex items-center gap-3">
          <Sparkles className="w-5 h-5 text-purple-400" />
          <div>
            <p className="text-white font-medium">Featured Instructors</p>
            <p className="text-sm text-gray-400">Top-rated professionals verified by our team</p>
          }
        }
      </div>

      {/* Instructor Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {filteredInstructors.map(renderInstructorCard)}
      </div>

      {/* Instructor Profile Modal */}
      <AnimatePresence>
        {selectedInstructor && renderInstructorProfile()}
      </AnimatePresence>
    }
  );
}
