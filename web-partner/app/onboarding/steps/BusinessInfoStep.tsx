'use client';

import React, { useState } from 'react';
import { Building2, Mail, Phone, MapPin, Globe, FileText } from 'lucide-react';
import PrivacyPolicyBanner from '@/components/common/PrivacyPolicyBanner';

interface BusinessInfoStepProps {
  onNext: (data: any) => void;
  data: any;
}

export default function BusinessInfoStep({ onNext, data }: BusinessInfoStepProps) {
  const [formData, setFormData] = useState({
    businessName: data.businessName || '',
    legalBusinessName: data.legalBusinessName || '',
    businessType: data.businessType || 'llc',
    taxId: data.taxId || '',
    businessEmail: data.businessEmail || '',
    businessPhone: data.businessPhone || '',
    website: data.website || '',
    address: {
      street: data.address?.street || '',
      city: data.address?.city || '',
      state: data.address?.state || '',
      zipCode: data.address?.zipCode || '',
      country: data.address?.country || 'US'
    },
    yearEstablished: data.yearEstablished || '',
    numberOfEmployees: data.numberOfEmployees || ''
  });

  const [errors, setErrors] = useState<any>({});

  const validateForm = () => {
    const newErrors: any = {};
    
    if (!formData.businessName) newErrors.businessName = 'Business name is required';
    if (!formData.legalBusinessName) newErrors.legalBusinessName = 'Legal business name is required';
    if (!formData.taxId) newErrors.taxId = 'Tax ID is required';
    if (!formData.businessEmail) newErrors.businessEmail = 'Business email is required';
    if (!formData.businessPhone) newErrors.businessPhone = 'Business phone is required';
    if (!formData.address.street) newErrors.addressStreet = 'Street address is required';
    if (!formData.address.city) newErrors.addressCity = 'City is required';
    if (!formData.address.state) newErrors.addressState = 'State is required';
    if (!formData.address.zipCode) newErrors.addressZipCode = 'ZIP code is required';
    
    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (validateForm()) {
      onNext({ businessInfo: formData });
    }
  };

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    const { name, value } = e.target;
    
    if (name.startsWith('address.')) {
      const addressField = name.split('.')[1];
      setFormData(prev => ({
        ...prev,
        address: {
          ...prev.address,
          [addressField]: value
        }
      }));
    } else {
      setFormData(prev => ({ ...prev, [name]: value }));
    }
  };

  return (
    <div className="space-y-6">
      <div>
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Business Information</h2>
        <p className="text-gray-600">Tell us about your business</p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* Business Details */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <Building2 className="inline h-4 w-4 mr-1" />
              Business Name
            </label>
            <input
              type="text"
              name="businessName"
              value={formData.businessName}
              onChange={handleInputChange}
              className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.businessName ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="Your Studio Name"
            />
            {errors.businessName && (
              <p className="text-red-500 text-sm mt-1">{errors.businessName}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <FileText className="inline h-4 w-4 mr-1" />
              Legal Business Name
            </label>
            <input
              type="text"
              name="legalBusinessName"
              value={formData.legalBusinessName}
              onChange={handleInputChange}
              className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.legalBusinessName ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="Legal Entity Name"
            />
            {errors.legalBusinessName && (
              <p className="text-red-500 text-sm mt-1">{errors.legalBusinessName}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Business Type
            </label>
            <select
              name="businessType"
              value={formData.businessType}
              onChange={handleInputChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            >
              <option value="sole_proprietorship">Sole Proprietorship</option>
              <option value="llc">LLC</option>
              <option value="corporation">Corporation</option>
              <option value="partnership">Partnership</option>
              <option value="nonprofit">Non-Profit</option>
            </select>
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Tax ID / EIN
            </label>
            <input
              type="text"
              name="taxId"
              value={formData.taxId}
              onChange={handleInputChange}
              className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.taxId ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="XX-XXXXXXX"
            />
            {errors.taxId && (
              <p className="text-red-500 text-sm mt-1">{errors.taxId}</p>
            )}
          </div>
        </div>

        {/* Contact Information */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <Mail className="inline h-4 w-4 mr-1" />
              Business Email
            </label>
            <input
              type="email"
              name="businessEmail"
              value={formData.businessEmail}
              onChange={handleInputChange}
              className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.businessEmail ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="contact@yourstudio.com"
            />
            {errors.businessEmail && (
              <p className="text-red-500 text-sm mt-1">{errors.businessEmail}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <Phone className="inline h-4 w-4 mr-1" />
              Business Phone
            </label>
            <input
              type="tel"
              name="businessPhone"
              value={formData.businessPhone}
              onChange={handleInputChange}
              className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.businessPhone ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="(555) 123-4567"
            />
            {errors.businessPhone && (
              <p className="text-red-500 text-sm mt-1">{errors.businessPhone}</p>
            )}
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              <Globe className="inline h-4 w-4 mr-1" />
              Website (Optional)
            </label>
            <input
              type="url"
              name="website"
              value={formData.website}
              onChange={handleInputChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="https://yourstudio.com"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Year Established
            </label>
            <input
              type="number"
              name="yearEstablished"
              value={formData.yearEstablished}
              onChange={handleInputChange}
              min="1900"
              max={new Date().getFullYear()}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="2020"
            />
          </div>
        </div>

        {/* Address */}
        <div className="space-y-4">
          <h3 className="text-lg font-semibold text-gray-900">
            <MapPin className="inline h-4 w-4 mr-1" />
            Business Address
          </h3>
          
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Street Address
            </label>
            <input
              type="text"
              name="address.street"
              value={formData.address.street}
              onChange={handleInputChange}
              className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.addressStreet ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="123 Main Street"
            />
            {errors.addressStreet && (
              <p className="text-red-500 text-sm mt-1">{errors.addressStreet}</p>
            )}
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                City
              </label>
              <input
                type="text"
                name="address.city"
                value={formData.address.city}
                onChange={handleInputChange}
                className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                  errors.addressCity ? 'border-red-500' : 'border-gray-300'
                }`}
                placeholder="San Francisco"
              />
              {errors.addressCity && (
                <p className="text-red-500 text-sm mt-1">{errors.addressCity}</p>
              )}
            </div>

            <div className="col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                State
              </label>
              <input
                type="text"
                name="address.state"
                value={formData.address.state}
                onChange={handleInputChange}
                className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                  errors.addressState ? 'border-red-500' : 'border-gray-300'
                }`}
                placeholder="CA"
                maxLength={2}
              />
              {errors.addressState && (
                <p className="text-red-500 text-sm mt-1">{errors.addressState}</p>
              )}
            </div>

            <div className="col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                ZIP Code
              </label>
              <input
                type="text"
                name="address.zipCode"
                value={formData.address.zipCode}
                onChange={handleInputChange}
                className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                  errors.addressZipCode ? 'border-red-500' : 'border-gray-300'
                }`}
                placeholder="94102"
              />
              {errors.addressZipCode && (
                <p className="text-red-500 text-sm mt-1">{errors.addressZipCode}</p>
              )}
            </div>

            <div className="col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Country
              </label>
              <select
                name="address.country"
                value={formData.address.country}
                onChange={handleInputChange}
                className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              >
                <option value="US">United States</option>
                <option value="CA">Canada</option>
                <option value="GB">United Kingdom</option>
                <option value="AU">Australia</option>
              </select>
            </div>
          </div>
        </div>

        {/* Additional Info */}
        <div>
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Number of Employees
          </label>
          <select
            name="numberOfEmployees"
            value={formData.numberOfEmployees}
            onChange={handleInputChange}
            className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          >
            <option value="">Select range</option>
            <option value="1">Just me</option>
            <option value="2-5">2-5</option>
            <option value="6-10">6-10</option>
            <option value="11-25">11-25</option>
            <option value="26-50">26-50</option>
            <option value="50+">50+</option>
          </select>
        </div>

        {/* Privacy Policy Notice */}
        <div className="mt-8 pt-6 border-t border-gray-200">
          <PrivacyPolicyBanner
            variant="detailed"
            context="onboarding"
            showTrustIndicators={true}
          />
        </div>
      </form>
    </div>
  );
}