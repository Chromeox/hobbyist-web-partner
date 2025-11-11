'use client';

import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  TrendingUp, 
  Clock, 
  Calendar, 
  DollarSign,
  Zap,
  Users,
  AlertTriangle,
  Settings,
  BarChart,
  Target,
  Percent,
  Activity
} from 'lucide-react';

interface PricingRule {
  id: string;
  name: string;
  type: 'surge' | 'discount' | 'time-based' | 'demand-based';
  conditions: {
    timeSlots?: string[];
    daysOfWeek?: string[];
    minAttendance?: number;
    maxAttendance?: number;
    bookingWindow?: number; // hours before class
    seasonalDates?: { start: string; end: string }[];
  };
  adjustment: {
    type: 'percentage' | 'fixed';
    value: number;
    maxPrice?: number;
    minPrice?: number;
  };
  priority: number;
  isActive: boolean;
  appliesTo: 'all' | 'categories' | 'specific';
  categories?: string[];
  classes?: string[];
}

interface DemandMetrics {
  timeSlot: string;
  avgBookingRate: number;
  peakDays: string[];
  avgLeadTime: number;
  priceElasticity: number;
}

export default function DynamicPricing() {
  const [activeTab, setActiveTab] = useState('rules');
  const [pricingRules, setPricingRules] = useState<PricingRule[]>([
    {
      id: '1',
      name: 'Weekend Surge',
      type: 'surge',
      conditions: {
        daysOfWeek: ['Saturday', 'Sunday'],
        timeSlots: ['10:00-14:00']
      },
      adjustment: {
        type: 'percentage',
        value: 20,
        maxPrice: 45
      },
      priority: 1,
      isActive: true,
      appliesTo: 'all'
    },
    {
      id: '2',
      name: 'Last Minute Discount',
      type: 'discount',
      conditions: {
        bookingWindow: 2 // Within 2 hours of class
      },
      adjustment: {
        type: 'percentage',
        value: -30,
        minPrice: 15
      },
      priority: 2,
      isActive: true,
      appliesTo: 'categories',
      categories: ['pottery', 'painting']
    },
    {
      id: '3',
      name: 'High Demand Premium',
      type: 'demand-based',
      conditions: {
        minAttendance: 80 // 80% booked
      },
      adjustment: {
        type: 'percentage',
        value: 15
      },
      priority: 3,
      isActive: true,
      appliesTo: 'all'
    }
  ]);

  const [showRuleModal, setShowRuleModal] = useState(false);
  const [editingRule, setEditingRule] = useState<PricingRule | null>(null);

  const demandData: DemandMetrics[] = [
    { timeSlot: 'Morning (6-9am)', avgBookingRate: 45, peakDays: ['Mon', 'Wed'], avgLeadTime: 48, priceElasticity: 0.7 },
    { timeSlot: 'Mid-Morning (9-12pm)', avgBookingRate: 65, peakDays: ['Sat', 'Sun'], avgLeadTime: 36, priceElasticity: 0.5 },
    { timeSlot: 'Afternoon (12-5pm)', avgBookingRate: 70, peakDays: ['Sat', 'Sun'], avgLeadTime: 24, priceElasticity: 0.4 },
    { timeSlot: 'Evening (5-9pm)', avgBookingRate: 85, peakDays: ['Tue', 'Thu'], avgLeadTime: 12, priceElasticity: 0.3 },
    { timeSlot: 'Night (9pm+)', avgBookingRate: 30, peakDays: ['Fri'], avgLeadTime: 6, priceElasticity: 0.9 }
  ];

  const tabs = [
    { id: 'rules', label: 'Pricing Rules', icon: Settings },
    { id: 'analytics', label: 'Demand Analytics', icon: BarChart },
    { id: 'simulator', label: 'Price Simulator', icon: Activity },
    { id: 'schedule', label: 'Schedule View', icon: Calendar }
  ];

  const renderRules = () => (
    <div className="space-y-4">
      <div className="flex justify-between items-center mb-6">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Active Pricing Rules</h3>
          <p className="text-sm text-gray-600 mt-1">Automatically adjust prices based on demand and timing</p>
        </div>
        <button
          onClick={() => {
            setEditingRule(null);
            setShowRuleModal(true);
          }}
          className="px-4 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 flex items-center gap-2"
        >
          <Zap className="w-4 h-4" />
          New Rule
        </button>
      </div>

      <div className="grid gap-4">
        {pricingRules.map((rule) => (
          <motion.div
            key={rule.id}
            className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl"
            whileHover={{ scale: 1.01 }}
          >
            <div className="flex justify-between items-start">
              <div className="flex-1">
                <div className="flex items-center gap-3">
                  <div className={`p-2 rounded-lg ${
                    rule.type === 'surge' ? 'bg-red-500/20' :
                    rule.type === 'discount' ? 'bg-green-500/20' :
                    rule.type === 'demand-based' ? 'bg-purple-500/20' :
                    'bg-blue-500/20'
                  }`}>
                    {rule.type === 'surge' ? <TrendingUp className="w-4 h-4 text-red-400" /> :
                     rule.type === 'discount' ? <Percent className="w-4 h-4 text-green-400" /> :
                     rule.type === 'demand-based' ? <Users className="w-4 h-4 text-purple-400" /> :
                     <Clock className="w-4 h-4 text-blue-400" />}
                  </div>
                  <div>
                    <h4 className="font-semibold text-gray-900">{rule.name}</h4>
                    <p className="text-sm text-gray-600 capitalize">{rule.type.replace('-', ' ')}</p>
                  </div>
                </div>

                <div className="mt-4 space-y-2">
                  <div className="flex items-center gap-2 text-sm">
                    <span className="text-gray-600">Adjustment:</span>
                    <span className={`font-semibold ${
                      rule.adjustment.value > 0 ? 'text-red-400' : 'text-green-400'
                    }`}>
                      {rule.adjustment.value > 0 ? '+' : ''}{rule.adjustment.value}%
                    </span>
                    {rule.adjustment.maxPrice && (
                      <span className="text-gray-700">
                        (max ${rule.adjustment.maxPrice})
                      </span>
                    )}
                    {rule.adjustment.minPrice && (
                      <span className="text-gray-700">
                        (min ${rule.adjustment.minPrice})
                      </span>
                    )}
                  </div>

                  {rule.conditions.daysOfWeek && (
                    <div className="flex items-center gap-2 text-sm">
                      <Calendar className="w-3 h-3 text-gray-600" />
                      <span className="text-gray-700">{rule.conditions.daysOfWeek.join(', ')}</span>
                    </div>
                  )}

                  {rule.conditions.timeSlots && (
                    <div className="flex items-center gap-2 text-sm">
                      <Clock className="w-3 h-3 text-gray-400" />
                      <span className="text-gray-900">{rule.conditions.timeSlots.join(', ')}</span>
                    </div>
                  )}

                  {rule.conditions.minAttendance && (
                    <div className="flex items-center gap-2 text-sm">
                      <Users className="w-3 h-3 text-gray-400" />
                      <span className="text-gray-900">When {rule.conditions.minAttendance}% booked</span>
                    </div>
                  )}

                  {rule.conditions.bookingWindow && (
                    <div className="flex items-center gap-2 text-sm">
                      <AlertTriangle className="w-3 h-3 text-gray-400" />
                      <span className="text-gray-900">Within {rule.conditions.bookingWindow} hours of class</span>
                    </div>
                  )}
                </div>

                <div className="flex items-center gap-4 mt-4">
                  <span className="text-xs text-gray-500">Priority: {rule.priority}</span>
                  <span className="text-xs text-gray-500">
                    Applies to: {rule.appliesTo === 'all' ? 'All Classes' : 
                               rule.appliesTo === 'categories' ? `${rule.categories?.length} Categories` :
                               `${rule.classes?.length} Classes`}
                  </span>
                </div>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => {
                    setPricingRules(rules => 
                      rules.map(r => r.id === rule.id ? { ...r, isActive: !r.isActive } : r)
                    );
                  }}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full ${
                    rule.isActive ? 'bg-purple-600' : 'bg-gray-600'
                  }`}
                >
                  <span
                    className={`inline-block h-4 w-4 transform rounded-full bg-white transition ${
                      rule.isActive ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>
                <button
                  onClick={() => {
                    setEditingRule(rule);
                    setShowRuleModal(true);
                  }}
                  className="p-2 hover:bg-white/10 rounded-lg"
                >
                  <Settings className="w-4 h-4 text-gray-400" />
                </button>
              </div>
            </div>
          </motion.div>
        ))}
      </div>
    </div>
  );

  const renderAnalytics = () => (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Demand Patterns & Price Optimization</h3>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
            <h4 className="font-medium text-gray-900 mb-4">Time Slot Performance</h4>
            <div className="space-y-3">
              {demandData.map((slot) => (
                <div key={slot.timeSlot} className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-gray-900">{slot.timeSlot}</span>
                    <span className="text-gray-900 font-medium">{slot.avgBookingRate}%</span>
                  </div>
                  <div className="w-full bg-gray-700 rounded-full h-2">
                    <div 
                      className={`h-2 rounded-full ${
                        slot.avgBookingRate > 70 ? 'bg-red-500' :
                        slot.avgBookingRate > 50 ? 'bg-yellow-500' :
                        'bg-green-500'
                      }`}
                      style={{ width: `${slot.avgBookingRate}%` }}
                    />
                  </div>
                  <div className="flex justify-between text-xs text-gray-400">
                    <span>Peak: {slot.peakDays.join(', ')}</span>
                    <span>Elasticity: {slot.priceElasticity}</span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
            <h4 className="font-medium text-gray-900 mb-4">Revenue Impact This Week</h4>
            <div className="space-y-4">
              <div className="flex justify-between items-center">
                <span className="text-gray-700">Base Revenue</span>
                <span className="text-gray-900 font-medium">$12,450</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-700">Surge Pricing</span>
                <span className="text-green-400 font-medium">+$1,890</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-gray-700">Discounts Applied</span>
                <span className="text-red-400 font-medium">-$420</span>
              </div>
              <div className="border-t border-gray-700 pt-4">
                <div className="flex justify-between items-center">
                  <span className="text-gray-900 font-semibold">Total Revenue</span>
                  <span className="text-gray-900 font-bold text-xl">$13,920</span>
                </div>
                <div className="flex items-center gap-2 mt-2">
                  <TrendingUp className="w-4 h-4 text-green-400" />
                  <span className="text-green-400 text-sm">+11.8% vs last week</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
        <h4 className="font-medium text-gray-900 mb-4">Category Price Sensitivity</h4>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {['Pottery', 'Painting', 'DJ Workshops', 'Fencing'].map((category) => (
            <div key={category} className="text-center">
              <div className="text-2xl font-bold text-purple-400">
                {category === 'Pottery' ? '0.3' :
                 category === 'Painting' ? '0.5' :
                 category === 'DJ Workshops' ? '0.2' : '0.7'}
              </div>
              <div className="text-sm text-gray-900 mt-1">{category}</div>
              <div className="text-xs text-gray-500 mt-1">
                {category === 'Pottery' ? 'Low sensitivity' :
                 category === 'Painting' ? 'Medium sensitivity' :
                 category === 'DJ Workshops' ? 'Very low' : 'High sensitivity'}
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );

  const renderSimulator = () => (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Price Impact Simulator</h3>
        <p className="text-sm text-gray-600 mb-6">Test how price changes affect bookings and revenue</p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
          <h4 className="font-medium text-gray-900 mb-4">Simulation Parameters</h4>
          <div className="space-y-4">
            <div>
              <label className="text-sm text-gray-700">Base Price</label>
              <input
                type="number"
                defaultValue={30}
                className="w-full mt-1 px-3 py-2 border border-gray-300 rounded-lg text-gray-900 bg-white"
              />
            </div>
            <div>
              <label className="text-sm text-gray-700">Price Change (%)</label>
              <input
                type="range"
                min="-50"
                max="50"
                defaultValue={0}
                className="w-full mt-1"
              />
              <div className="flex justify-between text-xs text-gray-500 mt-1">
                <span>-50%</span>
                <span>0%</span>
                <span>+50%</span>
              </div>
            </div>
            <div>
              <label className="text-sm text-gray-700">Time Slot</label>
              <select
                className="w-full mt-1 px-3 py-2 border border-gray-300 rounded-lg text-gray-900 bg-white appearance-none pr-10 cursor-pointer"
                style={{
                  backgroundImage: `url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 20 20'%3e%3cpath stroke='%236b7280' stroke-linecap='round' stroke-linejoin='round' stroke-width='1.5' d='M6 8l4 4 4-4'/%3e%3c/svg%3e")`,
                  backgroundPosition: 'right 0.5rem center',
                  backgroundRepeat: 'no-repeat',
                  backgroundSize: '1.5em 1.5em'
                }}
              >
                <option>Morning (6-9am)</option>
                <option>Evening (5-9pm)</option>
                <option>Weekend</option>
              </select>
            </div>
            <button className="w-full py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700">
              Run Simulation
            </button>
          </div>
        </div>

        <div className="bg-white shadow-lg border border-gray-200 p-6 rounded-xl">
          <h4 className="font-medium text-gray-900 mb-4">Projected Impact</h4>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <div className="text-2xl font-bold text-gray-900">75%</div>
                <div className="text-sm text-gray-400">Expected Fill Rate</div>
              </div>
              <div>
                <div className="text-2xl font-bold text-green-400">+$450</div>
                <div className="text-sm text-gray-400">Revenue Change</div>
              </div>
            </div>
            <div className="border-t border-gray-700 pt-4">
              <div className="text-sm text-gray-700 mb-2">Booking Probability by Customer Segment</div>
              <div className="space-y-2">
                <div className="flex justify-between">
                  <span className="text-xs text-gray-400">Price Sensitive</span>
                  <span className="text-xs text-gray-900">45%</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-xs text-gray-400">Regular</span>
                  <span className="text-xs text-gray-900">70%</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-xs text-gray-400">Premium</span>
                  <span className="text-xs text-gray-900">85%</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );

  const renderSchedule = () => (
    <div className="space-y-6">
      <div>
        <h3 className="text-lg font-semibold text-gray-900 mb-4">Weekly Price Schedule</h3>
        <p className="text-sm text-gray-600 mb-6">View how prices change throughout the week</p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full">
          <thead>
            <tr className="border-b border-gray-700">
              <th className="text-left py-3 px-4 text-sm text-gray-400">Time</th>
              {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => (
                <th key={day} className="text-center py-3 px-4 text-sm text-gray-400">{day}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {['6:00 AM', '9:00 AM', '12:00 PM', '3:00 PM', '6:00 PM', '9:00 PM'].map(time => (
              <tr key={time} className="border-b border-gray-700/50">
                <td className="py-3 px-4 text-sm text-gray-900">{time}</td>
                {['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map(day => {
                  const isWeekend = day === 'Sat' || day === 'Sun';
                  const isEvening = time === '6:00 PM';
                  const basePrice = 30;
                  const price = isWeekend && time === '9:00 AM' ? basePrice * 1.2 :
                               isEvening ? basePrice * 1.15 :
                               time === '9:00 PM' ? basePrice * 0.7 :
                               basePrice;
                  
                  return (
                    <td key={day} className="text-center py-3 px-4">
                      <div className={`inline-flex items-center justify-center px-2 py-1 rounded text-xs font-medium ${
                        price > basePrice ? 'bg-red-500/20 text-red-400' :
                        price < basePrice ? 'bg-green-500/20 text-green-400' :
                        'bg-gray-700 text-gray-300'
                      }`}>
                        ${price.toFixed(0)}
                      </div>
                    </td>
                  );
                })}
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="flex gap-4 justify-center">
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 bg-red-500/20 rounded" />
          <span className="text-xs text-gray-400">Surge pricing</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 bg-gray-700 rounded" />
          <span className="text-xs text-gray-400">Base price</span>
        </div>
        <div className="flex items-center gap-2">
          <div className="w-3 h-3 bg-green-500/20 rounded" />
          <span className="text-xs text-gray-400">Discounted</span>
        </div>
      </div>
    </div>
  );

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Dynamic Pricing</h1>
        <p className="text-gray-600">Optimize revenue with intelligent price adjustments</p>
      </div>

      <div className="flex gap-2 mb-6 overflow-x-auto">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg whitespace-nowrap transition-colors ${
              activeTab === tab.id
                ? 'bg-purple-600 text-white'
                : 'bg-gray-800 text-gray-400 hover:bg-gray-700'
            }`}
          >
            <tab.icon className="w-4 h-4" />
            {tab.label}
          </button>
        ))}
      </div>

      <AnimatePresence mode="wait">
        <motion.div
          key={activeTab}
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -20 }}
          transition={{ duration: 0.2 }}
        >
          {activeTab === 'rules' && renderRules()}
          {activeTab === 'analytics' && renderAnalytics()}
          {activeTab === 'simulator' && renderSimulator()}
          {activeTab === 'schedule' && renderSchedule()}
        </motion.div>
      </AnimatePresence>
    </div>
  );
}