'use client';

import React from 'react';
import Link from 'next/link';
import { Shield, Mail, Phone, MapPin } from 'lucide-react';

export default function Footer() {
  return (
    <footer className="bg-gray-900 text-white">
      <div className="container mx-auto px-4 py-12">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
          {/* Brand */}
          <div className="md:col-span-1">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-8 h-8 bg-blue-600 rounded-lg flex items-center justify-center">
                <span className="text-white font-bold text-sm">H</span>
              </div>
              <span className="font-bold text-lg">Hobbyist</span>
            </div>
            <p className="text-gray-400 text-sm">
              Empowering studios with intelligent management tools and AI-powered insights.
            </p>
          </div>

          {/* Product */}
          <div>
            <h3 className="font-semibold mb-4">Product</h3>
            <ul className="space-y-2 text-sm text-gray-400">
              <li><Link href="/dashboard" className="hover:text-white transition-colors">Dashboard</Link></li>
              <li><Link href="/onboarding" className="hover:text-white transition-colors">Onboarding</Link></li>
              <li><Link href="#" className="hover:text-white transition-colors">Analytics</Link></li>
              <li><Link href="#" className="hover:text-white transition-colors">Integrations</Link></li>
            </ul>
          </div>

          {/* Support */}
          <div>
            <h3 className="font-semibold mb-4">Support</h3>
            <ul className="space-y-2 text-sm text-gray-400">
              <li><Link href="#" className="hover:text-white transition-colors">Help Center</Link></li>
              <li><Link href="#" className="hover:text-white transition-colors">Contact Support</Link></li>
              <li><Link href="#" className="hover:text-white transition-colors">API Documentation</Link></li>
              <li><Link href="#" className="hover:text-white transition-colors">Status Page</Link></li>
            </ul>
          </div>

          {/* Legal & Privacy */}
          <div>
            <h3 className="font-semibold mb-4 flex items-center gap-2">
              <Shield className="h-4 w-4" />
              Privacy & Legal
            </h3>
            <ul className="space-y-2 text-sm text-gray-400">
              <li>
                <Link
                  href="/privacy"
                  className="hover:text-white transition-colors font-medium"
                >
                  Privacy Policy
                </Link>
              </li>
              <li><Link href="#" className="hover:text-white transition-colors">Terms of Service</Link></li>
              <li><Link href="#" className="hover:text-white transition-colors">Cookie Policy</Link></li>
              <li><Link href="#" className="hover:text-white transition-colors">Data Processing Agreement</Link></li>
            </ul>
          </div>
        </div>

        {/* Trust & Security Bar */}
        <div className="border-t border-gray-800 mt-8 pt-8">
          <div className="flex flex-col md:flex-row justify-between items-center gap-4">
            <div className="flex items-center gap-6 text-sm text-gray-400">
              <div className="flex items-center gap-2">
                <Shield className="h-4 w-4 text-green-500" />
                <span>SOC 2 Type II</span>
              </div>
              <div className="flex items-center gap-2">
                <Shield className="h-4 w-4 text-blue-500" />
                <span>GDPR Compliant</span>
              </div>
              <div className="flex items-center gap-2">
                <Shield className="h-4 w-4 text-purple-500" />
                <span>AES-256 Encrypted</span>
              </div>
            </div>

            <div className="flex items-center gap-4 text-sm text-gray-400">
              <Link href="mailto:privacy@hobbyist.app" className="flex items-center gap-1 hover:text-white transition-colors">
                <Mail className="h-4 w-4" />
                Privacy Team
              </Link>
              <Link href="tel:+1-555-HOBBYIST" className="flex items-center gap-1 hover:text-white transition-colors">
                <Phone className="h-4 w-4" />
                Support
              </Link>
            </div>
          </div>
        </div>

        {/* Copyright */}
        <div className="border-t border-gray-800 mt-6 pt-6 text-center text-sm text-gray-400">
          <p>© 2025 Hobbyist, Inc. All rights reserved. Your data is protected by industry-leading security.</p>
        </div>
      </div>
    </footer>
  );
}