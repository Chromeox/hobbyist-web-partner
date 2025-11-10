'use client'

import React, { useState, useEffect } from 'react'
import { motion } from 'framer-motion'
import {
  Building2,
  MapPin,
  Phone,
  Mail,
  Calendar,
  Users,
  Star,
  Check,
  X,
  Clock,
  Eye,
  ExternalLink,
  AlertTriangle,
  Loader2
} from 'lucide-react'
import { toast } from 'react-hot-toast'

interface StudioApplication {
  id: string
  studioName: string
  ownerName: string
  email: string
  phone: string
  address: string
  city: string
  province: string
  postalCode: string
  website?: string
  description: string
  categories: string[]
  capacity: number
  socialMedia?: {
    instagram?: string
    facebook?: string
    twitter?: string
  }
  businessLicense: string
  insuranceNumber: string
  submittedAt: string
  status: 'pending' | 'approved' | 'rejected' | 'review'
  reviewNotes?: string
  expectedStartDate: string
  monthlyRevenue?: number
}

export default function StudioApprovalDashboard() {
  const [activeTab, setActiveTab] = useState<'pending' | 'reviewed'>('pending')
  const [selectedApplication, setSelectedApplication] = useState<StudioApplication | null>(null)
  const [applications, setApplications] = useState<StudioApplication[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [isApproving, setIsApproving] = useState<string | null>(null)
  const [isRejecting, setIsRejecting] = useState<string | null>(null)

  // Fetch pending studios from API
  useEffect(() => {
    fetchPendingStudios()
  }, [])

  const fetchPendingStudios = async () => {
    try {
      setIsLoading(true)
      const response = await fetch('/api/admin/studios/pending')

      if (!response.ok) {
        throw new Error('Failed to fetch pending studios')
      }

      const data = await response.json()

      // Transform API data to match component interface
      const transformedStudios = data.studios.map((studio: any) => ({
        id: studio.id,
        studioName: studio.name,
        ownerName: studio.submission?.business_name || studio.name,
        email: studio.email,
        phone: studio.phone || 'N/A',
        address: studio.address || 'N/A',
        city: studio.city,
        province: studio.province,
        postalCode: studio.postal_code || 'N/A',
        website: studio.submission?.website || '',
        description: studio.profile?.description || 'No description provided',
        categories: studio.profile?.categories || [],
        capacity: studio.profile?.capacity || 0,
        socialMedia: studio.profile?.social_media || {},
        businessLicense: studio.submission?.business_license_url || 'Pending',
        insuranceNumber: studio.submission?.insurance_certificate_url || 'Pending',
        submittedAt: studio.created_at,
        status: studio.approval_status === 'under_review' ? 'review' : studio.approval_status,
        reviewNotes: studio.admin_notes || '',
        expectedStartDate: studio.submission?.submitted_data?.expected_start_date || 'TBD',
        monthlyRevenue: studio.submission?.submitted_data?.monthly_revenue || 0
      }))

      setApplications(transformedStudios)
    } catch (error) {
      console.error('Error fetching pending studios:', error)
      toast.error('Failed to load pending studios')
    } finally {
      setIsLoading(false)
    }
  }

  const pendingApplications = applications.filter(app => app.status === 'pending' || app.status === 'review')
  const reviewedApplications = applications.filter(app => app.status === 'approved' || app.status === 'rejected')

  const handleApprove = async (applicationId: string) => {
    try {
      setIsApproving(applicationId)
      const response = await fetch(`/api/admin/studios/${applicationId}/approve`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          admin_notes: 'Application approved - meets all requirements'
        })
      })

      if (!response.ok) {
        throw new Error('Failed to approve studio')
      }

      toast.success('Studio approved successfully!')

      // Update local state
      setApplications(prev => prev.map(app =>
        app.id === applicationId
          ? { ...app, status: 'approved', reviewNotes: 'Application approved - meets all requirements' }
          : app
      ))
    } catch (error) {
      console.error('Error approving studio:', error)
      toast.error('Failed to approve studio')
    } finally {
      setIsApproving(null)
    }
  }

  const handleReject = async (applicationId: string, reason: string) => {
    try {
      setIsRejecting(applicationId)
      const response = await fetch(`/api/admin/studios/${applicationId}/reject`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          rejection_reason: reason || 'Application requires additional documentation',
          admin_notes: reason
        })
      })

      if (!response.ok) {
        throw new Error('Failed to reject studio')
      }

      toast.success('Studio rejected')

      // Update local state
      setApplications(prev => prev.map(app =>
        app.id === applicationId
          ? { ...app, status: 'rejected', reviewNotes: reason }
          : app
      ))
    } catch (error) {
      console.error('Error rejecting studio:', error)
      toast.error('Failed to reject studio')
    } finally {
      setIsRejecting(null)
    }
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'bg-yellow-100 text-yellow-800'
      case 'review': return 'bg-blue-100 text-blue-800'
      case 'approved': return 'bg-green-100 text-green-800'
      case 'rejected': return 'bg-red-100 text-red-800'
      default: return 'bg-gray-100 text-gray-800'
    }
  }

  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString('en-CA', {
      year: 'numeric',
      month: 'short',
      day: 'numeric'
    })
  }

  const ApplicationCard = ({ application }: { application: StudioApplication }) => (
    <motion.div
      className="bg-white rounded-lg border border-gray-200 p-6 hover:shadow-md transition-shadow"
      whileHover={{ scale: 1.01 }}
    >
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-lg font-semibold text-gray-900 mb-1">{application.studioName}</h3>
          <p className="text-gray-600">{application.ownerName}</p>
          <div className="flex items-center mt-2 text-sm text-gray-500">
            <MapPin className="w-4 h-4 mr-1" />
            {application.city}, {application.province}
          </div>
        </div>
        <div className="flex flex-col items-end">
          <span className={`px-2 py-1 rounded-full text-xs font-medium ${getStatusColor(application.status)}`}>
            {application.status.charAt(0).toUpperCase() + application.status.slice(1)}
          </span>
          <div className="text-sm text-gray-500 mt-2">
            {formatDate(application.submittedAt)}
          </div>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-4">
        <div className="text-sm">
          <span className="text-gray-500">Categories:</span>
          <div className="flex flex-wrap gap-1 mt-1">
            {application.categories.map(category => (
              <span key={category} className="px-2 py-1 bg-blue-50 text-blue-700 rounded text-xs">
                {category}
              </span>
            ))}
          </div>
        </div>
        <div className="text-sm">
          <span className="text-gray-500">Capacity:</span>
          <div className="font-medium">{application.capacity} people</div>
        </div>
      </div>

      <div className="flex items-center gap-2 mb-4 text-sm text-gray-600">
        <Mail className="w-4 h-4" />
        {application.email}
        <Phone className="w-4 h-4 ml-4" />
        {application.phone}
      </div>

      <p className="text-gray-700 text-sm mb-4 line-clamp-2">
        {application.description}
      </p>

      <div className="flex justify-between items-center">
        <button
          onClick={() => setSelectedApplication(application)}
          className="flex items-center text-blue-600 hover:text-blue-700 text-sm"
        >
          <Eye className="w-4 h-4 mr-1" />
          View Details
        </button>
        
        {application.status === 'pending' || application.status === 'review' ? (
          <div className="flex gap-2">
            <button
              onClick={() => handleReject(application.id, 'Application requires additional documentation')}
              disabled={isRejecting === application.id || isApproving === application.id}
              className="flex items-center px-3 py-1 bg-red-100 text-red-700 hover:bg-red-200 rounded text-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isRejecting === application.id ? (
                <Loader2 className="w-4 h-4 mr-1 animate-spin" />
              ) : (
                <X className="w-4 h-4 mr-1" />
              )}
              Reject
            </button>
            <button
              onClick={() => handleApprove(application.id)}
              disabled={isApproving === application.id || isRejecting === application.id}
              className="flex items-center px-3 py-1 bg-green-100 text-green-700 hover:bg-green-200 rounded text-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isApproving === application.id ? (
                <Loader2 className="w-4 h-4 mr-1 animate-spin" />
              ) : (
                <Check className="w-4 h-4 mr-1" />
              )}
              Approve
            </button>
          </div>
        ) : (
          <div className="text-sm text-gray-500">
            {application.status === 'approved' ? 'Approved' : 'Rejected'}
          </div>
        )}
      </div>
    </motion.div>
  )

  // Loading state
  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <Loader2 className="w-8 h-8 animate-spin text-blue-600 mx-auto mb-4" />
          <p className="text-gray-600">Loading studio applications...</p>
        </div>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Stats Overview */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="flex items-center">
            <div className="p-2 bg-yellow-100 rounded-lg">
              <Clock className="w-5 h-5 text-yellow-600" />
            </div>
            <div className="ml-4">
              <div className="text-2xl font-bold text-gray-900">
                {pendingApplications.length}
              </div>
              <div className="text-sm text-gray-600">Pending Review</div>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="flex items-center">
            <div className="p-2 bg-green-100 rounded-lg">
              <Check className="w-5 h-5 text-green-600" />
            </div>
            <div className="ml-4">
              <div className="text-2xl font-bold text-gray-900">
                {applications.filter(app => app.status === 'approved').length}
              </div>
              <div className="text-sm text-gray-600">Approved</div>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="flex items-center">
            <div className="p-2 bg-blue-100 rounded-lg">
              <Building2 className="w-5 h-5 text-blue-600" />
            </div>
            <div className="ml-4">
              <div className="text-2xl font-bold text-gray-900">
                {applications.length}
              </div>
              <div className="text-sm text-gray-600">Total Applications</div>
            </div>
          </div>
        </div>

        <div className="bg-white p-6 rounded-lg border border-gray-200">
          <div className="flex items-center">
            <div className="p-2 bg-purple-100 rounded-lg">
              <Star className="w-5 h-5 text-purple-600" />
            </div>
            <div className="ml-4">
              <div className="text-2xl font-bold text-gray-900">
                {Math.round((applications.filter(app => app.status === 'approved').length / applications.length) * 100)}%
              </div>
              <div className="text-sm text-gray-600">Approval Rate</div>
            </div>
          </div>
        </div>
      </div>

      {/* Tabs */}
      <div className="flex gap-4">
        <button
          onClick={() => setActiveTab('pending')}
          className={`px-4 py-2 rounded-lg transition-colors ${ 
            activeTab === 'pending' 
              ? 'bg-blue-600 text-white' 
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Pending ({pendingApplications.length})
        </button>
        <button
          onClick={() => setActiveTab('reviewed')}
          className={`px-4 py-2 rounded-lg transition-colors ${ 
            activeTab === 'reviewed' 
              ? 'bg-blue-600 text-white' 
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          Reviewed ({reviewedApplications.length})
        </button>
      </div>

      {/* Applications List */}
      <div className="grid gap-4">
        {(activeTab === 'pending' ? pendingApplications : reviewedApplications).map(application => (
          <ApplicationCard key={application.id} application={application} />
        ))}
      </div>

      {/* Application Detail Modal */}
      {selectedApplication && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="p-6">
              <div className="flex justify-between items-start mb-6">
                <div>
                  <h2 className="text-2xl font-bold text-gray-900 mb-2">
                    {selectedApplication.studioName}
                  </h2>
                  <div className="flex items-center gap-4">
                    <span className={`px-3 py-1 rounded-full text-sm font-medium ${getStatusColor(selectedApplication.status)}`}>
                      {selectedApplication.status.charAt(0).toUpperCase() + selectedApplication.status.slice(1)}
                    </span>
                    <span className="text-gray-500">
                      Submitted {formatDate(selectedApplication.submittedAt)}
                    </span>
                  </div>
                </div>
                <button
                  onClick={() => setSelectedApplication(null)}
                  className="text-gray-400 hover:text-gray-600"
                >
                  <X className="w-6 h-6" />
                </button>
              </div>

              <div className="grid md:grid-cols-2 gap-8">
                <div className="space-y-6">
                  <div>
                    <h3 className="font-semibold text-gray-900 mb-3">Contact Information</h3>
                    <div className="space-y-2 text-sm">
                      <div><strong>Owner:</strong> {selectedApplication.ownerName}</div>
                      <div><strong>Email:</strong> {selectedApplication.email}</div>
                      <div><strong>Phone:</strong> {selectedApplication.phone}</div>
                      {selectedApplication.website && (
                        <div>
                          <strong>Website:</strong>{' '}
                          <a href={selectedApplication.website} target="_blank" rel="noopener noreferrer" 
                             className="text-blue-600 hover:underline flex items-center gap-1">
                            {selectedApplication.website}
                            <ExternalLink className="w-3 h-3" />
                          </a>
                        </div>
                      )}
                    </div>
                  </div>

                  <div>
                    <h3 className="font-semibold text-gray-900 mb-3">Location</h3>
                    <div className="text-sm">
                      <div>{selectedApplication.address}</div>
                      <div>{selectedApplication.city}, {selectedApplication.province}</div>
                      <div>{selectedApplication.postalCode}</div>
                    </div>
                  </div>

                  <div>
                    <h3 className="font-semibold text-gray-900 mb-3">Business Details</h3>
                    <div className="space-y-2 text-sm">
                      <div><strong>License:</strong> {selectedApplication.businessLicense}</div>
                      <div><strong>Insurance:</strong> {selectedApplication.insuranceNumber}</div>
                      <div><strong>Capacity:</strong> {selectedApplication.capacity} people</div>
                      <div><strong>Expected Start:</strong> {formatDate(selectedApplication.expectedStartDate)}</div>
                      {selectedApplication.monthlyRevenue && (
                        <div><strong>Monthly Revenue:</strong> ${selectedApplication.monthlyRevenue.toLocaleString()}</div>
                      )}
                    </div>
                  </div>
                </div>

                <div className="space-y-6">
                  <div>
                    <h3 className="font-semibold text-gray-900 mb-3">Description</h3>
                    <p className="text-sm text-gray-700">{selectedApplication.description}</p>
                  </div>

                  <div>
                    <h3 className="font-semibold text-gray-900 mb-3">Categories</h3>
                    <div className="flex flex-wrap gap-2">
                      {selectedApplication.categories.map(category => (
                        <span key={category} className="px-3 py-1 bg-blue-50 text-blue-700 rounded text-sm">
                          {category}
                        </span>
                      ))}
                    </div>
                  </div>

                  {selectedApplication.socialMedia && (
                    <div>
                      <h3 className="font-semibold text-gray-900 mb-3">Social Media</h3>
                      <div className="space-y-1 text-sm">
                        {selectedApplication.socialMedia.instagram && (
                          <div><strong>Instagram:</strong> {selectedApplication.socialMedia.instagram}</div>
                        )}
                        {selectedApplication.socialMedia.facebook && (
                          <div><strong>Facebook:</strong> {selectedApplication.socialMedia.facebook}</div>
                        )}
                        {selectedApplication.socialMedia.twitter && (
                          <div><strong>Twitter:</strong> {selectedApplication.socialMedia.twitter}</div>
                        )}
                      </div>
                    </div>
                  )}

                  {selectedApplication.reviewNotes && (
                    <div>
                      <h3 className="font-semibold text-gray-900 mb-3">Review Notes</h3>
                      <p className="text-sm text-gray-700 bg-gray-50 p-3 rounded">
                        {selectedApplication.reviewNotes}
                      </p>
                    </div>
                  )}
                </div>
              </div>

              {(selectedApplication.status === 'pending' || selectedApplication.status === 'review') && (
                <div className="flex gap-3 mt-8 pt-6 border-t">
                  <button
                    onClick={() => {
                      handleReject(selectedApplication.id, 'Application requires additional documentation')
                      setSelectedApplication(null)
                    }}
                    className="flex items-center px-4 py-2 bg-red-100 text-red-700 hover:bg-red-200 rounded"
                  >
                    <X className="w-4 h-4 mr-2" />
                    Reject Application
                  </button>
                  <button
                    onClick={() => {
                      handleApprove(selectedApplication.id)
                      setSelectedApplication(null)
                    }}
                    className="flex items-center px-4 py-2 bg-green-100 text-green-700 hover:bg-green-200 rounded"
                  >
                    <Check className="w-4 h-4 mr-2" />
                    Approve Application
                  </button>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  )
}