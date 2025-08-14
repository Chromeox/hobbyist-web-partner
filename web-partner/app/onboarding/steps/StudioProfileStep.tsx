'use client';

import React, { useState } from 'react';
import { Camera, MapPin, Clock, Star, Plus, X } from 'lucide-react';

interface StudioProfileStepProps {
  onNext: (data: any) => void;
  onPrevious: () => void;
  data: any;
}

export default function StudioProfileStep({ onNext, onPrevious, data }: StudioProfileStepProps) {
  const [formData, setFormData] = useState({
    studioName: data.studioProfile?.studioName || '',
    tagline: data.studioProfile?.tagline || '',
    description: data.studioProfile?.description || '',
    specialties: data.studioProfile?.specialties || [],
    amenities: data.studioProfile?.amenities || [],
    photos: data.studioProfile?.photos || [],
    socialMedia: data.studioProfile?.socialMedia || {
      instagram: '',
      facebook: '',
      twitter: '',
      website: ''
    }
  });

  const [newSpecialty, setNewSpecialty] = useState('');
  const [newAmenity, setNewAmenity] = useState('');

  const commonSpecialties = [
    'Yoga', 'Pilates', 'Barre', 'HIIT', 'Strength Training', 'Cardio',
    'Dance', 'Meditation', 'Stretching', 'Functional Fitness'
  ];

  const commonAmenities = [
    'Parking', 'Changing Rooms', 'Showers', 'Lockers', 'Water Station',
    'Equipment Rental', 'Retail Shop', 'Childcare', 'WiFi', 'Air Conditioning'
  ];

  const addSpecialty = (specialty: string) => {
    if (specialty && !formData.specialties.includes(specialty)) {
      setFormData(prev => ({
        ...prev,
        specialties: [...prev.specialties, specialty]
      }));
    }
    setNewSpecialty('');
  };

  const removeSpecialty = (specialty: string) => {
    setFormData(prev => ({
      ...prev,
      specialties: prev.specialties.filter((s: string) => s !== specialty)
    }));
  };

  const addAmenity = (amenity: string) => {
    if (amenity && !formData.amenities.includes(amenity)) {
      setFormData(prev => ({
        ...prev,
        amenities: [...prev.amenities, amenity]
      }));
    }
    setNewAmenity('');
  };

  const removeAmenity = (amenity: string) => {
    setFormData(prev => ({
      ...prev,
      amenities: prev.amenities.filter((a: string) => a !== amenity)
    }));
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onNext({ studioProfile: formData });
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Studio Profile</h2>
        <p className="text-gray-600">Create your studio profile to attract students</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Basic Information */}
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Studio Display Name
            </label>
            <input
              type="text"
              value={formData.studioName}
              onChange={(e) => setFormData(prev => ({ ...prev, studioName: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="How your studio appears to students"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tagline
            </label>
            <input
              type="text"
              value={formData.tagline}
              onChange={(e) => setFormData(prev => ({ ...prev, tagline: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="e.g., Your wellness journey starts here"
              maxLength={100}
            />
            <p className="text-sm text-gray-500 mt-1">{formData.tagline.length}/100 characters</p>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Description
            </label>
            <textarea
              rows={4}
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Tell students about your studio's mission, philosophy, and what makes you unique..."
              maxLength={500}
            />
            <p className="text-sm text-gray-500 mt-1">{formData.description.length}/500 characters</p>
          </div>
        </div>

        {/* Specialties */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Class Specialties
          </label>
          
          {/* Selected Specialties */}
          <div className="flex flex-wrap gap-2 mb-3">
            {formData.specialties.map((specialty: string) => (
              <span
                key={specialty}
                className="inline-flex items-center px-3 py-1 bg-blue-100 text-blue-800 text-sm rounded-full"
              >
                {specialty}
                <button
                  type="button"
                  onClick={() => removeSpecialty(specialty)}
                  className="ml-2 text-blue-600 hover:text-blue-800"
                >
                  <X className="h-3 w-3" />
                </button>
              </span>
            ))}
          </div>

          {/* Add Specialty */}
          <div className="flex gap-2 mb-3">
            <input
              type="text"
              value={newSpecialty}
              onChange={(e) => setNewSpecialty(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addSpecialty(newSpecialty))}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Add a specialty..."
            />
            <button
              type="button"
              onClick={() => addSpecialty(newSpecialty)}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              <Plus className="h-4 w-4" />
            </button>
          </div>

          {/* Common Specialties */}
          <div className="flex flex-wrap gap-2">
            {commonSpecialties
              .filter(s => !formData.specialties.includes(s))
              .map((specialty) => (
                <button
                  key={specialty}
                  type="button"
                  onClick={() => addSpecialty(specialty)}
                  className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded-full hover:bg-gray-50 transition-colors"
                >
                  + {specialty}
                </button>
              ))}
          </div>
        </div>

        {/* Amenities */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Amenities
          </label>
          
          {/* Selected Amenities */}
          <div className="flex flex-wrap gap-2 mb-3">
            {formData.amenities.map((amenity: string) => (
              <span
                key={amenity}
                className="inline-flex items-center px-3 py-1 bg-green-100 text-green-800 text-sm rounded-full"
              >
                {amenity}
                <button
                  type="button"
                  onClick={() => removeAmenity(amenity)}
                  className="ml-2 text-green-600 hover:text-green-800"
                >
                  <X className="h-3 w-3" />
                </button>
              </span>
            ))}
          </div>

          {/* Add Amenity */}
          <div className="flex gap-2 mb-3">
            <input
              type="text"
              value={newAmenity}
              onChange={(e) => setNewAmenity(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addAmenity(newAmenity))}
              className="flex-1 px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Add an amenity..."
            />
            <button
              type="button"
              onClick={() => addAmenity(newAmenity)}
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
            >
              <Plus className="h-4 w-4" />
            </button>
          </div>

          {/* Common Amenities */}
          <div className="flex flex-wrap gap-2">
            {commonAmenities
              .filter(a => !formData.amenities.includes(a))
              .map((amenity) => (
                <button
                  key={amenity}
                  type="button"
                  onClick={() => addAmenity(amenity)}
                  className="px-3 py-1 text-sm border border-gray-300 text-gray-700 rounded-full hover:bg-gray-50 transition-colors"
                >
                  + {amenity}
                </button>
              ))}
          </div>
        </div>

        {/* Photos */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Studio Photos
          </label>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[...Array(6)].map((_, index) => (
              <div
                key={index}
                className="aspect-square bg-gray-100 rounded-lg flex items-center justify-center border-2 border-dashed border-gray-300 hover:border-gray-400 transition-colors cursor-pointer"
              >
                <div className="text-center">
                  <Camera className="h-8 w-8 text-gray-400 mx-auto mb-2" />
                  <p className="text-xs text-gray-500">Add Photo</p>
                </div>
              </div>
            ))}
          </div>
          <p className="text-sm text-gray-500 mt-2">
            Upload high-quality photos of your studio, classes, and facilities. First photo will be your main image.
          </p>
        </div>

        {/* Social Media */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-3">
            Social Media & Website (Optional)
          </label>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Website</label>
              <input
                type="url"
                value={formData.socialMedia.website}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  socialMedia: { ...prev.socialMedia, website: e.target.value }
                }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="https://yourstudio.com"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Instagram</label>
              <input
                type="text"
                value={formData.socialMedia.instagram}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  socialMedia: { ...prev.socialMedia, instagram: e.target.value }
                }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="@yourstudio"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Facebook</label>
              <input
                type="text"
                value={formData.socialMedia.facebook}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  socialMedia: { ...prev.socialMedia, facebook: e.target.value }
                }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="facebook.com/yourstudio"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-gray-600 mb-1">Twitter</label>
              <input
                type="text"
                value={formData.socialMedia.twitter}
                onChange={(e) => setFormData(prev => ({
                  ...prev,
                  socialMedia: { ...prev.socialMedia, twitter: e.target.value }
                }))}
                className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                placeholder="@yourstudio"
              />
            </div>
          </div>
        </div>
      </form>
    </div>
  );
}