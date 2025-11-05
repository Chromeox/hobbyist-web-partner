export default function TermsOfService() {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <div className="max-w-4xl mx-auto bg-white rounded-lg shadow p-8">
        <h1 className="text-3xl font-bold mb-8">Terms of Service</h1>
        <p className="text-gray-600 mb-6">Last updated: {new Date().toLocaleDateString()}</p>
        
        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">1. Acceptance of Terms</h2>
          <p className="mb-4">
            By accessing or using the Hobbyist application ("Service"), you agree to be bound by these Terms of Service.
            If you do not agree to these terms, please do not use our Service.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">2. Description of Service</h2>
          <p className="mb-4">
            Hobbyist is a platform that connects users with hobby classes and studios. We facilitate bookings,
            payments, and communication between users and studios.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">3. User Accounts</h2>
          <p className="mb-4">To use certain features of the Service, you must create an account. You agree to:</p>
          <ul className="list-disc pl-6 mb-4">
            <li>Provide accurate and complete information</li>
            <li>Maintain the security of your account credentials</li>
            <li>Notify us immediately of any unauthorized use</li>
            <li>Be responsible for all activities under your account</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">4. Bookings and Payments</h2>
          <h3 className="text-xl font-semibold mb-2">4.1 Bookings</h3>
          <p className="mb-4">
            When you book a class through Hobbyist, you are entering into a contract directly with the studio.
            Hobbyist acts as an intermediary platform.
          </p>
          
          <h3 className="text-xl font-semibold mb-2">4.2 Payments</h3>
          <p className="mb-4">
            All payments are processed through our secure payment provider (Stripe). By making a payment,
            you agree to Stripe's terms of service.
          </p>
          
          <h3 className="text-xl font-semibold mb-2">4.3 Cancellations and Refunds</h3>
          <p className="mb-4">
            Cancellation and refund policies are set by individual studios. Please review the studio's
            policy before booking.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">5. User Conduct</h2>
          <p className="mb-4">You agree not to:</p>
          <ul className="list-disc pl-6 mb-4">
            <li>Violate any laws or regulations</li>
            <li>Infringe on intellectual property rights</li>
            <li>Harass, abuse, or harm other users or studios</li>
            <li>Submit false or misleading information</li>
            <li>Attempt to gain unauthorized access to the Service</li>
            <li>Use the Service for any commercial purpose without permission</li>
          </ul>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">6. Intellectual Property</h2>
          <p className="mb-4">
            All content on Hobbyist, including text, graphics, logos, and software, is the property of
            Hobbyist or its licensors and is protected by intellectual property laws.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">7. Disclaimer of Warranties</h2>
          <p className="mb-4">
            The Service is provided "as is" and "as available" without warranties of any kind, either express
            or implied. We do not guarantee that the Service will be uninterrupted, secure, or error-free.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">8. Limitation of Liability</h2>
          <p className="mb-4">
            To the maximum extent permitted by law, Hobbyist shall not be liable for any indirect, incidental,
            special, consequential, or punitive damages resulting from your use of the Service.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">9. Indemnification</h2>
          <p className="mb-4">
            You agree to indemnify and hold harmless Hobbyist and its affiliates from any claims, damages,
            or expenses arising from your use of the Service or violation of these Terms.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">10. Termination</h2>
          <p className="mb-4">
            We reserve the right to terminate or suspend your account at any time for violation of these Terms
            or for any other reason at our sole discretion.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">11. Governing Law</h2>
          <p className="mb-4">
            These Terms shall be governed by and construed in accordance with the laws of [Your Jurisdiction],
            without regard to its conflict of law provisions.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">12. Changes to Terms</h2>
          <p className="mb-4">
            We reserve the right to modify these Terms at any time. We will notify users of any material changes
            via email or through the Service.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">13. Contact Information</h2>
          <p className="mb-4">
            If you have questions about these Terms, please contact us at:
          </p>
          <p className="mb-4">
            Email: legal@hobbyist.app<br />
            Address: [Your Business Address]
          </p>
        </section>
      </div>
    </div>
  );
}