'use client'

import React from 'react'
import { Calendar, Crown, Zap, Clock, Users, TrendingUp } from 'lucide-react'

export default function ComingSoon() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-50 to-blue-50 p-6">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="inline-flex items-center justify-center w-20 h-20 bg-purple-100 rounded-full mb-6">
            <Crown className="w-10 h-10 text-purple-600" />
          </div>
          <h1 className="text-4xl font-bold text-gray-900 mb-4">
            Subscription Management
          </h1>
          <p className="text-xl text-gray-600 max-w-2xl mx-auto">
            Advanced subscription features are currently in development and will be available once our web directory is fully operational.
          </p>
        </div>

        {/* Coming Features */}
        <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-6 mb-12">
          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-purple-100 rounded-lg flex items-center justify-center mr-3">
                <Crown className="w-6 h-6 text-purple-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">Premium Memberships</h3>
            </div>
            <p className="text-gray-600">
              Offer tiered subscription plans with exclusive benefits and priority booking.
            </p>
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mr-3">
                <Calendar className="w-6 h-6 text-blue-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">Recurring Classes</h3>
            </div>
            <p className="text-gray-600">
              Automated recurring bookings and subscription-based class packages.
            </p>
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mr-3">
                <TrendingUp className="w-6 h-6 text-green-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">Revenue Analytics</h3>
            </div>
            <p className="text-gray-600">
              Track subscription metrics, churn rates, and lifetime customer value.
            </p>
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-orange-100 rounded-lg flex items-center justify-center mr-3">
                <Users className="w-6 h-6 text-orange-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">Member Portal</h3>
            </div>
            <p className="text-gray-600">
              Dedicated member dashboard with subscription management and benefits.
            </p>
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-yellow-100 rounded-lg flex items-center justify-center mr-3">
                <Zap className="w-6 h-6 text-yellow-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">Automated Billing</h3>
            </div>
            <p className="text-gray-600">
              Smart billing cycles with automatic payments and invoice generation.
            </p>
          </div>

          <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200">
            <div className="flex items-center mb-4">
              <div className="w-12 h-12 bg-red-100 rounded-lg flex items-center justify-center mr-3">
                <Clock className="w-6 h-6 text-red-600" />
              </div>
              <h3 className="text-lg font-semibold text-gray-900">Waitlist Management</h3>
            </div>
            <p className="text-gray-600">
              Priority waitlists for subscribers with automatic enrollment.
            </p>
          </div>
        </div>

        {/* Status Update */}
        <div className="bg-white rounded-xl p-8 shadow-sm border border-gray-200 text-center">
          <div className="inline-flex items-center px-4 py-2 bg-yellow-100 text-yellow-800 rounded-full text-sm font-medium mb-4">
            <Clock className="w-4 h-4 mr-2" />
            In Development
          </div>
          <h3 className="text-xl font-semibold text-gray-900 mb-3">
            We're Building Something Amazing
          </h3>
          <p className="text-gray-600 mb-6 max-w-2xl mx-auto">
            Our subscription management system is being developed alongside our comprehensive web directory platform. 
            This integration will provide seamless subscription experiences for both studios and students.
          </p>
          <div className="flex flex-col sm:flex-row gap-4 justify-center">
            <div className="text-sm text-gray-500">
              <strong>Expected Timeline:</strong> Q2 2024
            </div>
            <div className="text-sm text-gray-500">
              <strong>Dependencies:</strong> Web Directory Launch
            </div>
          </div>
        </div>

        {/* Alternative Solutions */}
        <div className="mt-12 bg-blue-50 rounded-xl p-6 border border-blue-200">
          <h4 className="text-lg font-semibold text-blue-900 mb-3">
            Need Subscription Features Now?
          </h4>
          <p className="text-blue-800 mb-4">
            While we're developing the full subscription system, you can use these temporary solutions:
          </p>
          <ul className="text-blue-700 space-y-2">
            <li>• Use <strong>Pricing & Credits</strong> for package-based offerings</li>
            <li>• Set up recurring classes through the <strong>Classes</strong> section</li>
            <li>• Manage member information in <strong>Students</strong></li>
            <li>• Track revenue through <strong>Revenue Reports</strong></li>
          </ul>
        </div>
      </div>
    </div>
  )
}