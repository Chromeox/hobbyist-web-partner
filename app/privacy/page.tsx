'use client';

import React from 'react';
import { motion } from 'framer-motion';
import { Shield, Lock, Eye, Database, Users, Calendar, CreditCard, Phone } from 'lucide-react';

export default function PrivacyPolicyPage() {
  return (
    <div className="min-h-screen bg-white">
      <div className="container mx-auto px-4 py-12 max-w-4xl">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          className="text-center mb-12"
        >
          <div className="w-16 h-16 bg-blue-100 rounded-full flex items-center justify-center mx-auto mb-6">
            <Shield className="h-8 w-8 text-blue-600" />
          </div>
          <h1 className="text-4xl font-bold text-gray-900 mb-4">Privacy Policy</h1>
          <p className="text-xl text-gray-600">
            Your privacy and data security are our top priorities
          </p>
          <p className="text-sm text-gray-500 mt-2">
            Last updated: September 19, 2025
          </p>
        </motion.div>

        {/* Trust Indicators */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12"
        >
          <div className="bg-green-50 border border-green-200 rounded-lg p-6 text-center">
            <Lock className="h-8 w-8 text-green-600 mx-auto mb-3" />
            <h3 className="font-semibold text-green-800">Encrypted Data</h3>
            <p className="text-sm text-green-700">All data encrypted in transit and at rest</p>
          </div>
          <div className="bg-blue-50 border border-blue-200 rounded-lg p-6 text-center">
            <Eye className="h-8 w-8 text-blue-600 mx-auto mb-3" />
            <h3 className="font-semibold text-blue-800">No Data Selling</h3>
            <p className="text-sm text-blue-700">We never sell your data to third parties</p>
          </div>
          <div className="bg-purple-50 border border-purple-200 rounded-lg p-6 text-center">
            <Users className="h-8 w-8 text-purple-600 mx-auto mb-3" />
            <h3 className="font-semibold text-purple-800">GDPR Compliant</h3>
            <p className="text-sm text-purple-700">Full compliance with privacy regulations</p>
          </div>
        </motion.div>

        {/* Content Sections */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="prose prose-lg max-w-none"
        >
          {/* Data We Collect */}
          <section className="mb-12">
            <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-3">
              <Database className="h-6 w-6 text-blue-600" />
              What Data We Collect
            </h2>
            <div className="bg-gray-50 rounded-lg p-6 mb-6">
              <h3 className="font-semibold text-gray-900 mb-4">Business Information</h3>
              <ul className="space-y-2 text-gray-700">
                <li>• Studio name, address, and contact information</li>
                <li>• Business registration and tax information</li>
                <li>• Owner and staff contact details</li>
                <li>• Business hours and service offerings</li>
              </ul>
            </div>
            <div className="bg-gray-50 rounded-lg p-6 mb-6">
              <h3 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <Calendar className="h-5 w-5" />
                Calendar & Booking Data
              </h3>
              <ul className="space-y-2 text-gray-700">
                <li>• Class schedules and availability</li>
                <li>• Customer booking information</li>
                <li>• Instructor schedules and assignments</li>
                <li>• Calendar integration data (Google, Outlook, MindBody)</li>
              </ul>
            </div>
            <div className="bg-gray-50 rounded-lg p-6">
              <h3 className="font-semibold text-gray-900 mb-4 flex items-center gap-2">
                <CreditCard className="h-5 w-5" />
                Payment Information
              </h3>
              <ul className="space-y-2 text-gray-700">
                <li>• Payment processing data (handled by Stripe)</li>
                <li>• Revenue and transaction history</li>
                <li>• Commission and payout information</li>
                <li>• Bank account details for payouts</li>
              </ul>
            </div>
          </section>

          {/* How We Use Data */}
          <section className="mb-12">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">How We Use Your Data</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
                <h3 className="font-semibold text-blue-800 mb-3">Service Delivery</h3>
                <ul className="space-y-2 text-blue-700 text-sm">
                  <li>• Manage your studio operations</li>
                  <li>• Process bookings and payments</li>
                  <li>• Sync calendar integrations</li>
                  <li>• Provide customer support</li>
                </ul>
              </div>
              <div className="bg-green-50 border border-green-200 rounded-lg p-6">
                <h3 className="font-semibold text-green-800 mb-3">Analytics & Insights</h3>
                <ul className="space-y-2 text-green-700 text-sm">
                  <li>• Generate performance reports</li>
                  <li>• Provide AI-powered recommendations</li>
                  <li>• Track revenue and growth metrics</li>
                  <li>• Optimize class scheduling</li>
                </ul>
              </div>
            </div>
          </section>

          {/* Data Security */}
          <section className="mb-12">
            <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-3">
              <Lock className="h-6 w-6 text-green-600" />
              Data Security & Protection
            </h2>
            <div className="bg-gradient-to-r from-green-50 to-blue-50 border border-green-200 rounded-lg p-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <h3 className="font-semibold text-gray-900 mb-3">Technical Safeguards</h3>
                  <ul className="space-y-2 text-gray-700 text-sm">
                    <li>• AES-256 encryption at rest</li>
                    <li>• TLS 1.3 encryption in transit</li>
                    <li>• Regular security audits</li>
                    <li>• SOC 2 Type II compliance</li>
                  </ul>
                </div>
                <div>
                  <h3 className="font-semibold text-gray-900 mb-3">Access Controls</h3>
                  <ul className="space-y-2 text-gray-700 text-sm">
                    <li>• Role-based access permissions</li>
                    <li>• Multi-factor authentication</li>
                    <li>• Regular access reviews</li>
                    <li>• Audit logging and monitoring</li>
                  </ul>
                </div>
              </div>
            </div>
          </section>

          {/* Your Rights */}
          <section className="mb-12">
            <h2 className="text-2xl font-bold text-gray-900 mb-6">Your Privacy Rights</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="border border-gray-200 rounded-lg p-6">
                <h3 className="font-semibold text-gray-900 mb-3">Data Access & Control</h3>
                <ul className="space-y-2 text-gray-700 text-sm">
                  <li>• View all data we have about you</li>
                  <li>• Export your data in standard formats</li>
                  <li>• Correct inaccurate information</li>
                  <li>• Delete your account and data</li>
                </ul>
              </div>
              <div className="border border-gray-200 rounded-lg p-6">
                <h3 className="font-semibold text-gray-900 mb-3">Communication Preferences</h3>
                <ul className="space-y-2 text-gray-700 text-sm">
                  <li>• Opt out of marketing emails</li>
                  <li>• Control notification settings</li>
                  <li>• Manage data sharing preferences</li>
                  <li>• Set privacy preferences</li>
                </ul>
              </div>
            </div>
          </section>

          {/* Contact */}
          <section className="mb-12">
            <h2 className="text-2xl font-bold text-gray-900 mb-6 flex items-center gap-3">
              <Phone className="h-6 w-6 text-blue-600" />
              Contact Our Privacy Team
            </h2>
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
              <p className="text-blue-700 mb-4">
                Have questions about your privacy or data? We're here to help.
              </p>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <h3 className="font-semibold text-blue-800 mb-2">Privacy Officer</h3>
                  <p className="text-blue-700 text-sm">privacy@hobbyist.app</p>
                  <p className="text-blue-700 text-sm">Response within 48 hours</p>
                </div>
                <div>
                  <h3 className="font-semibold text-blue-800 mb-2">Data Protection</h3>
                  <p className="text-blue-700 text-sm">dpo@hobbyist.app</p>
                  <p className="text-blue-700 text-sm">GDPR & compliance inquiries</p>
                </div>
              </div>
            </div>
          </section>
        </motion.div>

        {/* Footer CTA */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="text-center border-t border-gray-200 pt-8"
        >
          <p className="text-gray-600 mb-4">
            Questions about this privacy policy? We're here to help.
          </p>
          <button className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors">
            Contact Privacy Team
          </button>
        </motion.div>
      </div>
    </div>
  );
}