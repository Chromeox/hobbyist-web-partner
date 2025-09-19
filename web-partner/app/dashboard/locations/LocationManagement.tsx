'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import {
  MapPin,
  Plus,
  Edit,
  Trash2,
  Phone,
  Mail,
  Clock,
  Users,
  Settings,
  CheckCircle,
  AlertCircle,
  Building2,
  Navigation,
  Calendar,
  DollarSign,
  TrendingUp,
  Star,
  Copy,
  Globe
} from 'lucide-react';

interface StudioLocation {
  id: string;
  name: string;
  slug: string;
  address: string;
  city: string;
  state: string;
  postalCode: string;
  country: string;
  phone: string;
  email: string;
  isPrimary: boolean;
  isActive: boolean;
  timezone: string;
  currency: string;
  capacity: number;
  amenities: string[];
  manager: {
    id: string;
    name: string;
    email: string;
    avatar?: string;
  };
  stats: {
    activeClasses: number;
    totalStudents: number;
    monthlyRevenue: number;
    avgRating: number;
    fillRate: number;
  };
  operatingHours: {
    [key: string]: { open: string; close: string; closed?: boolean };
  };
}

export default function LocationManagement() {
  const [locations, setLocations] = useState<StudioLocation[]>([
    {
      id: '1',
      name: 'Downtown Creative Hub',
      slug: 'downtown',
      address: '123 Granville Street',
      city: 'Vancouver',
      state: 'BC',
      postalCode: 'V6B 1A1',
      country: 'Canada',
      phone: '+1 (604) 555-0123',
      email: 'downtown@hobbyist.ca',
      isPrimary: true,
      isActive: true,
      timezone: 'America/Vancouver',
      currency: 'CAD',
      capacity: 150,
      amenities: ['Parking', 'WiFi', 'Lockers', 'Cafe', 'Equipment Rental'],
      manager: {
        id: '1',
        name: 'Sarah Chen',
        email: 'sarah@hobbyist.ca'
      },
      stats: {
        activeClasses: 24,
        totalStudents: 487,
        monthlyRevenue: 28500,
        avgRating: 4.8,
        fillRate: 82
      },
      operatingHours: {
        monday: { open: '06:00', close: '22:00' },
        tuesday: { open: '06:00', close: '22:00' },
        wednesday: { open: '06:00', close: '22:00' },
        thursday: { open: '06:00', close: '22:00' },
        friday: { open: '06:00', close: '21:00' },
        saturday: { open: '08:00', close: '20:00' },
        sunday: { open: '08:00', close: '18:00' }
      }
    },
    {
      id: '2',
      name: 'Kitsilano Arts Space',
      slug: 'kitsilano',
      address: '2456 West 4th Avenue',
      city: 'Vancouver',
      state: 'BC',
      postalCode: 'V6K 1P5',
      country: 'Canada',
      phone: '+1 (604) 555-0456',
      email: 'kits@hobbyist.ca',
      isPrimary: false,
      isActive: true,
      timezone: 'America/Vancouver',
      currency: 'CAD',
      capacity: 80,
      amenities: ['Street Parking', 'WiFi', 'Natural Light', 'Tea Station'],
      manager: {
        id: '2',
        name: 'Marcus Johnson',
        email: 'marcus@hobbyist.ca'
      },
      stats: {
        activeClasses: 18,
        totalStudents: 312,
        monthlyRevenue: 19200,
        avgRating: 4.9,
        fillRate: 78
      },
      operatingHours: {
        monday: { open: '07:00', close: '21:00' },
        tuesday: { open: '07:00', close: '21:00' },
        wednesday: { open: '07:00', close: '21:00' },
        thursday: { open: '07:00', close: '21:00' },
        friday: { open: '07:00', close: '20:00' },
        saturday: { open: '09:00', close: '18:00' },
        sunday: { open: '10:00', close: '17:00' }
      }
    }
  ]);

  const [selectedLocation, setSelectedLocation] = useState<StudioLocation | null>(null);
  const [showAddModal, setShowAddModal] = useState(false);
  const [activeTab, setActiveTab] = useState('overview');

  const totalStats = {
    locations: locations.length,
    activeClasses: locations.reduce((sum, loc) => sum + loc.stats.activeClasses, 0),
    totalStudents: locations.reduce((sum, loc) => sum + loc.stats.totalStudents, 0),
    monthlyRevenue: locations.reduce((sum, loc) => sum + loc.stats.monthlyRevenue, 0),
    avgFillRate: Math.round(locations.reduce((sum, loc) => sum + loc.stats.fillRate, 0) / locations.length)
  };

  const renderLocationCard = (location: StudioLocation) => (
    <motion.div
      key={location.id}
      className="bg-white p-6 rounded-xl cursor-pointer hover:scale-[1.02] transition-transform shadow-lg border border-gray-200"
      onClick={() => setSelectedLocation(location)}
      whileHover={{ y: -4 }}
    >
      <div className="flex justify-between items-start mb-4">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="text-lg font-semibold text-gray-900">{location.name}</h3>
            {location.isPrimary && (
              <span className="px-2 py-0.5 bg-purple-500/20 text-purple-400 text-xs rounded-full">
                Primary
              </span>
            )}
          </div>
          <p className="text-sm text-gray-600 mt-1">{location.address}</p>
          <p className="text-sm text-gray-600">{location.city}, {location.state}</p>
        </div>
        <div className={`p-2 rounded-lg ${location.isActive ? 'bg-green-500/20' : 'bg-red-500/20'}`}>
          {location.isActive ? (
            <CheckCircle className="w-5 h-5 text-green-400" />
          ) : (
            <AlertCircle className="w-5 h-5 text-red-400" />
          )}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div>
          <p className="text-xs text-gray-500">Active Classes</p>
          <p className="text-xl font-semibold text-gray-900">{location.stats.activeClasses}</p>
        </div>
        <div>
          <p className="text-xs text-gray-500">Students</p>
          <p className="text-xl font-semibold text-gray-900">{location.stats.totalStudents}</p>
        </div>
        <div>
          <p className="text-xs text-gray-500">Monthly Revenue</p>
          <p className="text-xl font-semibold text-green-600">
            ${location.stats.monthlyRevenue.toLocaleString()}
          </p>
        </div>
        <div>
          <p className="text-xs text-gray-500">Fill Rate</p>
          <div className="flex items-center gap-2">
            <p className="text-xl font-semibold text-gray-900">{location.stats.fillRate}%</p>
            <div className="flex-1 bg-gray-200 rounded-full h-2">
              <div 
                className="h-2 bg-gradient-to-r from-purple-500 to-pink-500 rounded-full"
                style={{ width: `${location.stats.fillRate}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      <div className="flex items-center justify-between pt-4 border-t border-gray-200">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-full bg-gradient-to-r from-purple-500 to-pink-500 flex items-center justify-center text-white text-xs font-semibold">
            {location.manager.name.charAt(0)}
          </div>
          <div>
            <p className="text-sm text-gray-900">{location.manager.name}</p>
            <p className="text-xs text-gray-500">Manager</p>
          </div>
        </div>
        <div className="flex items-center gap-1">
          <Star className="w-4 h-4 text-yellow-400 fill-current" />
          <span className="text-sm text-gray-900 font-medium">{location.stats.avgRating}</span>
        </div>
      </div>
    </motion.div>
  );

  const renderLocationDetails = () => {
    if (!selectedLocation) return null;

    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.95 }}
        animate={{ opacity: 1, scale: 1 }}
        className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50"
        onClick={() => setSelectedLocation(null)}
      >
        <motion.div
          className="bg-white rounded-2xl max-w-4xl w-full max-h-[90vh] overflow-hidden shadow-2xl border border-gray-200"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="p-6 border-b border-gray-200">
            <div className="flex justify-between items-start">
              <div>
                <h2 className="text-2xl font-bold text-gray-900">{selectedLocation.name}</h2>
                <p className="text-gray-600 mt-1">{selectedLocation.address}, {selectedLocation.city}</p>
              </div>
              <button
                onClick={() => setSelectedLocation(null)}
                className="p-2 hover:bg-gray-100 rounded-lg"
              >
                <X className="w-5 h-5 text-gray-500" />
              </button>
            </div>

            <div className="flex gap-2 mt-4">
              {['overview', 'schedule', 'staff', 'settings'].map(tab => (
                <button
                  key={tab}
                  onClick={() => setActiveTab(tab)}
                  className={`px-4 py-2 rounded-lg capitalize ${
                    activeTab === tab
                      ? 'bg-purple-600 text-white'
                      : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {tab}
                </button>
              ))}
            </div>
          </div>

          <div className="p-6 overflow-y-auto max-h-[60vh]">
            {activeTab === 'overview' && (
              <div className="space-y-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">Contact Information</h3>
                    <div className="space-y-3">
                      <div className="flex items-center gap-3">
                        <Phone className="w-4 h-4 text-gray-500" />
                        <span className="text-gray-300">{selectedLocation.phone}</span>
                      </div>
                      <div className="flex items-center gap-3">
                        <Mail className="w-4 h-4 text-gray-500" />
                        <span className="text-gray-300">{selectedLocation.email}</span>
                      </div>
                      <div className="flex items-center gap-3">
                        <Globe className="w-4 h-4 text-gray-500" />
                        <span className="text-gray-300">{selectedLocation.timezone}</span>
                      </div>
                      <div className="flex items-center gap-3">
                        <Users className="w-4 h-4 text-gray-500" />
                        <span className="text-gray-300">Capacity: {selectedLocation.capacity} students</span>
                      </div>
                    </div>
                  </div>

                  <div>
                    <h3 className="text-lg font-semibold text-gray-900 mb-4">Amenities</h3>
                    <div className="flex flex-wrap gap-2">
                      {selectedLocation.amenities.map(amenity => (
                        <span
                          key={amenity}
                          className="px-3 py-1 bg-purple-500/20 text-purple-400 rounded-full text-sm"
                        >
                          {amenity}
                        </span>
                      ))}
                    </div>
                  </div>
                </div>

                <div>
                  <h3 className="text-lg font-semibold text-white mb-4">Operating Hours</h3>
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                    {Object.entries(selectedLocation.operatingHours).map(([day, hours]) => (
                      <div key={day} className="flex justify-between items-center p-3 bg-gray-100 rounded-lg">
                        <span className="text-gray-300 capitalize">{day}</span>
                        <span className="text-gray-900">
                          {hours.closed ? 'Closed' : `${hours.open} - ${hours.close}`}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <div>
                  <h3 className="text-lg font-semibold text-white mb-4">Performance Metrics</h3>
                  <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                    <div className="text-center">
                      <div className="text-2xl font-bold text-purple-400">
                        {selectedLocation.stats.activeClasses}
                      </div>
                      <div className="text-sm text-gray-600">Active Classes</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-blue-400">
                        {selectedLocation.stats.totalStudents}
                      </div>
                      <div className="text-sm text-gray-600">Total Students</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-green-400">
                        ${(selectedLocation.stats.monthlyRevenue / 1000).toFixed(1)}k
                      </div>
                      <div className="text-sm text-gray-600">Monthly Revenue</div>
                    </div>
                    <div className="text-center">
                      <div className="text-2xl font-bold text-yellow-400">
                        {selectedLocation.stats.avgRating}
                      </div>
                      <div className="text-sm text-gray-600">Avg Rating</div>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {activeTab === 'settings' && (
              <div className="space-y-6">
                <div>
                  <h3 className="text-lg font-semibold text-white mb-4">Location Settings</h3>
                  <div className="space-y-4">
                    <div className="flex items-center justify-between p-4 bg-gray-100 rounded-lg">
                      <div>
                        <p className="text-gray-900 font-medium">Primary Location</p>
                        <p className="text-sm text-gray-600">This location appears first in searches</p>
                      </div>
                      <button
                        className={`relative inline-flex h-6 w-11 items-center rounded-full ${
                          selectedLocation.isPrimary ? 'bg-purple-600' : 'bg-gray-600'
                        }`}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition ${
                            selectedLocation.isPrimary ? 'translate-x-6' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </div>

                    <div className="flex items-center justify-between p-4 bg-gray-100 rounded-lg">
                      <div>
                        <p className="text-gray-900 font-medium">Accept Online Bookings</p>
                        <p className="text-sm text-gray-600">Students can book classes at this location</p>
                      </div>
                      <button
                        className={`relative inline-flex h-6 w-11 items-center rounded-full ${
                          selectedLocation.isActive ? 'bg-purple-600' : 'bg-gray-600'
                        }`}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition ${
                            selectedLocation.isActive ? 'translate-x-6' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </div>

                    <button className="w-full py-3 bg-red-500/20 text-red-400 rounded-lg hover:bg-red-500/30">
                      Delete Location
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>
        </motion.div>
      </motion.div>
    );
  };

  return (
    <div className="p-6">
      <div className="mb-8">
        <div className="flex justify-between items-center">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 mb-2">Location Management</h1>
            <p className="text-gray-600">Manage your studio locations across the city</p>
          </div>
          <button
            onClick={() => setShowAddModal(true)}
            className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 flex items-center gap-2"
          >
            <Plus className="w-5 h-5" />
            Add Location
          </button>
        </div>
      </div>

      {/* Overview Stats */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4 mb-8">
        <div className="bg-white p-4 rounded-xl shadow-lg border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-purple-500/20 rounded-lg">
              <Building2 className="w-5 h-5 text-purple-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{totalStats.locations}</p>
              <p className="text-sm text-gray-600">Locations</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl shadow-lg border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-blue-500/20 rounded-lg">
              <Calendar className="w-5 h-5 text-blue-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{totalStats.activeClasses}</p>
              <p className="text-sm text-gray-600">Total Classes</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl shadow-lg border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-green-500/20 rounded-lg">
              <Users className="w-5 h-5 text-green-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{totalStats.totalStudents}</p>
              <p className="text-sm text-gray-600">Total Students</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl shadow-lg border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-yellow-500/20 rounded-lg">
              <DollarSign className="w-5 h-5 text-yellow-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">
                ${(totalStats.monthlyRevenue / 1000).toFixed(1)}k
              </p>
              <p className="text-sm text-gray-600">Monthly Revenue</p>
            </div>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl shadow-lg border border-gray-200">
          <div className="flex items-center gap-3">
            <div className="p-2 bg-pink-500/20 rounded-lg">
              <TrendingUp className="w-5 h-5 text-pink-400" />
            </div>
            <div>
              <p className="text-2xl font-bold text-gray-900">{totalStats.avgFillRate}%</p>
              <p className="text-sm text-gray-600">Avg Fill Rate</p>
            </div>
          </div>
        </div>
      </div>

      {/* Location Cards */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {locations.map(renderLocationCard)}
      </div>

      {/* Location Details Modal */}
      <AnimatePresence>
        {selectedLocation && renderLocationDetails()}
      </AnimatePresence>
    </div>
  );
}