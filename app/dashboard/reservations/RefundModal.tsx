'use client'

import { CreditCard, AlertCircle } from 'lucide-react'
import { useState } from 'react'

interface RefundModalProps {
  onClose: () => void
  reservation: any
  onRefund?: (refundData: any) => void
}

export default function RefundModal({ onClose, reservation, onRefund }: RefundModalProps) {
  const [reason, setReason] = useState('')
  const [processing, setProcessing] = useState(false)

  const handleRefund = () => {
    setProcessing(true)
    // Simulate refund process
    setTimeout(() => {
      onRefund?.({
        reservationId: reservation.id,
        creditAmount: reservation.creditCost,
        reason
      })
      onClose()
    }, 1000)
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
        <h2 className="text-lg font-semibold mb-4">Refund Credits</h2>
        
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
          <div className="flex items-start">
            <CreditCard className="h-5 w-5 text-blue-600 mt-0.5 mr-2" />
            <div>
              <p className="text-sm font-medium text-blue-900">Credit Refund Details</p>
              <p className="text-sm text-blue-700 mt-1">
                Refunding <span className="font-bold">{reservation?.creditCost} credits</span> to {reservation?.studentName}
              </p>
              <p className="text-xs text-blue-600 mt-1">
                New balance: {reservation?.studentCredits + reservation?.creditCost} credits
              </p>
            </div>
          </div>
        </div>

        <div className="mb-4">
          <label className="block text-sm font-medium text-gray-700 mb-2">
            Refund Reason
          </label>
          <textarea
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
            rows={3}
            placeholder="Enter reason for refund..."
          />
        </div>

        <div className="bg-amber-50 border border-amber-200 rounded-lg p-3 mb-4">
          <div className="flex items-start">
            <AlertCircle className="h-4 w-4 text-amber-600 mt-0.5 mr-2" />
            <p className="text-xs text-amber-700">
              Credits will be immediately available for the student to use on future reservations.
            </p>
          </div>
        </div>

        <div className="flex gap-3">
          <button
            onClick={handleRefund}
            disabled={!reason || processing}
            className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {processing ? 'Processing...' : 'Confirm Refund'}
          </button>
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  )
}