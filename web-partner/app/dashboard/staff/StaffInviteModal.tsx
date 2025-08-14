'use client'

interface StaffInviteModalProps {
  onClose: () => void
  onInvite?: (inviteData: any) => void
}

export default function StaffInviteModal({ onClose, onInvite }: StaffInviteModalProps) {

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg p-6 max-w-md w-full mx-4">
        <h2 className="text-lg font-semibold mb-4">Invite Staff Member</h2>
        <p className="text-gray-600 mb-4">Send invitation to new staff member</p>
        <button
          onClick={onClose}
          className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Close
        </button>
      </div>
    </div>
  )
}