import SimpleDashboard from './dashboard/SimpleDashboard';

export default function HomePage() {
  return (
    <SimpleDashboard studioName="Hobbyist Studio" userName="Studio Owner">
      <div className="space-y-6">
        <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
          <h2 className="text-xl font-semibold text-blue-900 mb-2">🎯 Features Available</h2>
          <ul className="text-blue-800 space-y-2">
            <li>• Multi-step onboarding wizard</li>
            <li>• Studio dashboard with analytics</li>
            <li>• Class management (CRUD)</li>
            <li>• Staff invitation & management</li>
            <li>• Booking management & communication</li>
            <li>• Settings & subscription management</li>
          </ul>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-green-50 p-4 rounded-lg border border-green-200">
            <h3 className="font-semibold text-green-900">Classes</h3>
            <p className="text-green-700 text-sm">Manage your class schedule</p>
          </div>
          <div className="bg-purple-50 p-4 rounded-lg border border-purple-200">
            <h3 className="font-semibold text-purple-900">Students</h3>
            <p className="text-purple-700 text-sm">View student registrations</p>
          </div>
          <div className="bg-orange-50 p-4 rounded-lg border border-orange-200">
            <h3 className="font-semibold text-orange-900">Analytics</h3>
            <p className="text-orange-700 text-sm">Track your studio metrics</p>
          </div>
        </div>

        <div className="bg-green-50 p-4 rounded-lg border border-green-200">
          <p className="text-green-800">
            <strong>✅ Status:</strong> Dashboard is now working! Original DashboardLayout had syntax issues.
          </p>
        </div>
      </div>
    </SimpleDashboard>
  );
}