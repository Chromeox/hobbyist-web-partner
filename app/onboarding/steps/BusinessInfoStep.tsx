'use client';

import React, { useState } from 'react';
import { Phone, MapPin, FileText } from 'lucide-react';
import PrivacyPolicyBanner from '@/components/common/PrivacyPolicyBanner';

interface BusinessInfoStepProps {
  onNext: (data: any) => void;
  onPrevious?: () => void;
  data: any;
}

export default function BusinessInfoStep({ onNext, onPrevious, data }: BusinessInfoStepProps) {
  const [formData, setFormData] = useState({
    legalBusinessName: data.legalBusinessName || '',
    businessType: data.businessType || 'llc',
    taxId: data.taxId || '',
    businessPhone: data.businessPhone || '',
    contactEmail: data.contactEmail || '',
    address: {
      street: data.address?.street || '',
      city: data.address?.city || '',
      state: data.address?.state || 'BC',
      zipCode: data.address?.zipCode || '',
      country: data.address?.country || 'CA'
    },
    yearEstablished: data.yearEstablished || ''
  });

  const [errors, setErrors] = useState<any>({});

  const validateForm = () => {
    const newErrors: any = {};
    let isValid = true;

    // Required: Studio/Business name
    if (!formData.legalBusinessName.trim()) {
      newErrors.legalBusinessName = 'Studio name is required';
      isValid = false;
    }

    // Tax ID is now OPTIONAL for MVP
    // (removed validation)

    // Required: Contact email OR phone (at least one)
    const hasEmail = formData.contactEmail.trim().length > 0;
    const hasPhone = formData.businessPhone.trim().length > 0;

    if (!hasEmail && !hasPhone) {
      newErrors.contactEmail = 'Please provide either an email or phone number';
      newErrors.businessPhone = 'Please provide either an email or phone number';
      isValid = false;
    } else if (hasEmail && !/\S+@\S+\.\S+/.test(formData.contactEmail)) {
      newErrors.contactEmail = 'Invalid email format';
      isValid = false;
    }

    // Required: Street address
    if (!formData.address.street.trim()) {
      newErrors.addressStreet = 'Street address is required';
      isValid = false;
    }

    // Required: City
    if (!formData.address.city.trim()) {
      newErrors.addressCity = 'City is required';
      isValid = false;
    }

    // Required: Province/State
    if (!formData.address.state.trim()) {
      newErrors.addressState = 'Province is required';
      isValid = false;
    }

    // Required: Postal Code
    if (!formData.address.zipCode.trim()) {
      newErrors.addressZipCode = 'Postal code is required';
      isValid = false;
    }

    setErrors(newErrors);
    return isValid;
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
              <FileText className="inline h-4 w-4 mr-1" />
              Legal Business Name
              <span className="text-gray-500 text-xs ml-2">(if different from Business Name)</span>
            </label>
            <input
              type="text"
              name="legalBusinessName"
              value={formData.legalBusinessName}
              onChange={handleInputChange}
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Legal Entity Name"
            />
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
              Contact Email
            </label>
            <input
              type="email"
              name="contactEmail"
              value={formData.contactEmail}
              onChange={handleInputChange}
              className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.contactEmail ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="hello@yourstudio.com"
              required
            />
            {errors.contactEmail && (
              <p className="text-red-500 text-sm mt-1">{errors.contactEmail}</p>
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
              className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="(555) 123-4567"
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
              Street Address <span className="text-red-500">*</span>
            </label>
            <input
              type="text"
              name="address.street"
              value={formData.address.street}
              onChange={handleInputChange}
              className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                errors.addressStreet ? 'border-red-500' : 'border-gray-300'
              }`}
              placeholder="1555 East 6th Ave"
            />
            {errors.addressStreet && (
              <p className="text-red-500 text-sm mt-1">{errors.addressStreet}</p>
            )}
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            <div className="col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                City <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                name="address.city"
                value={formData.address.city}
                onChange={handleInputChange}
                className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                  errors.addressCity ? 'border-red-500' : 'border-gray-300'
                }`}
                placeholder="Vancouver"
              />
              {errors.addressCity && (
                <p className="text-red-500 text-sm mt-1">{errors.addressCity}</p>
              )}
            </div>

            <div className="col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Province <span className="text-red-500">*</span>
              </label>
              <select
                name="address.state"
                value={formData.address.state}
                onChange={handleInputChange}
                className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                  errors.addressState ? 'border-red-500' : 'border-gray-300'
                }`}
              >
                <option value="">Select Province</option>
                <option value="BC">British Columbia</option>
                <option value="AB">Alberta</option>
                <option value="ON">Ontario</option>
                <option value="QC">Quebec</option>
                <option value="MB">Manitoba</option>
                <option value="SK">Saskatchewan</option>
                <option value="NS">Nova Scotia</option>
                <option value="NB">New Brunswick</option>
                <option value="NL">Newfoundland</option>
                <option value="PE">Prince Edward Island</option>
                <option value="NT">Northwest Territories</option>
                <option value="YT">Yukon</option>
                <option value="NU">Nunavut</option>
              </select>
              {errors.addressState && (
                <p className="text-red-500 text-sm mt-1">{errors.addressState}</p>
              )}
            </div>

            <div className="col-span-1">
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Postal Code <span className="text-red-500">*</span>
              </label>
              <input
                type="text"
                name="address.zipCode"
                value={formData.address.zipCode}
                onChange={handleInputChange}
                className={`w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent ${
                  errors.addressZipCode ? 'border-red-500' : 'border-gray-300'
                }`}
                placeholder="V5N 1P2"
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
                <option value="CA">Canada</option>
                <option value="US">United States</option>
              </select>
            </div>
          </div>
        </div>

        {/* Privacy Policy Notice */}
        <div className="mt-8 pt-6 border-t border-gray-200">
          <PrivacyPolicyBanner
            variant="detailed"
            context="onboarding"
            showTrustIndicators={true}
          />
        </div>

        {/* Navigation Buttons */}
        <div className="mt-8 flex justify-between">
          {onPrevious && (
            <button
              type="button"
              onClick={onPrevious}
              className="px-6 py-3 border border-gray-300 text-gray-700 rounded-lg font-medium hover:bg-gray-50 transition-all"
            >
              Back
            </button>
          )}
          <button
            type="submit"
            className="px-8 py-3 bg-gradient-to-r from-blue-600 to-indigo-600 text-white rounded-lg font-medium hover:from-blue-700 hover:to-indigo-700 transition-all shadow-md hover:shadow-lg ml-auto"
          >
            Continue
          </button>
        </div>
      </form>
    </div>
  );
}
