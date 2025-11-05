/**
 * Payment Step Component
 * Handles payment processing for class bookings
 */

'use client'

import React, { useState, useEffect } from 'react'
import { usePaymentModel } from '@/lib/contexts/PaymentModelContext'
import { 
  CreditCardIcon,
  BanknotesIcon,
  ShieldCheckIcon,
  ExclamationTriangleIcon,
  CheckCircleIcon,
  CurrencyDollarIcon
} from '@heroicons/react/24/outline'

interface PaymentStepProps {
  classData: {
    id: string
    title: string
    price: number
    instructor: {
      name: string
    }
    nextSession?: {
      date: string
      timeSlot: string
      location: string
    }
  }
  onPaymentComplete: (paymentData: PaymentData) => void
  onBack: () => void
  isGuest?: boolean
}

interface PaymentData {
  paymentMethod: 'card' | 'apple_pay' | 'google_pay' | 'credits'
  paymentIntentId?: string
  amount: number
  currency: string
  cardLast4?: string
  transactionId: string
}

interface SavedPaymentMethod {
  id: string
  type: 'card'
  last4: string
  brand: string
  expiryMonth: number
  expiryYear: number
  isDefault: boolean
}

const mockSavedPaymentMethods: SavedPaymentMethod[] = [
  {
    id: '1',
    type: 'card',
    last4: '4242',
    brand: 'visa',
    expiryMonth: 12,
    expiryYear: 2025,
    isDefault: true
  },
  {
    id: '2',
    type: 'card',
    last4: '0005',
    brand: 'mastercard',
    expiryMonth: 8,
    expiryYear: 2026,
    isDefault: false
  }
]

export default function PaymentStep({ 
  classData, 
  onPaymentComplete, 
  onBack, 
  isGuest = false 
}: PaymentStepProps) {
  const { paymentModel, isCreditsEnabled, isCashEnabled } = usePaymentModel()
  
  const [paymentMethod, setPaymentMethod] = useState<'saved' | 'new' | 'apple_pay' | 'google_pay' | 'credits'>('saved')
  const [selectedSavedMethod, setSelectedSavedMethod] = useState<string>(mockSavedPaymentMethods[0]?.id || '')
  const [isProcessing, setIsProcessing] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)
  
  // Form fields for new card
  const [cardForm, setCardForm] = useState({
    cardNumber: '',
    expiryDate: '',
    cvv: '',
    name: '',
    zipCode: ''
  })
  
  const [saveCard, setSaveCard] = useState(false)
  const [userCredits] = useState(10) // Mock credits balance

  useEffect(() => {
    // Check available payment methods
    const applePaySession = typeof window !== 'undefined' ? (window as any).ApplePaySession : undefined
    const hasApplePay = typeof applePaySession?.canMakePayments === 'function' && applePaySession.canMakePayments()
    const hasGooglePay = typeof window !== 'undefined'
      && typeof window.PaymentRequest !== 'undefined'
      && typeof (window.PaymentRequest as any)?.prototype?.canMakePayment === 'function'
    
    // Set default payment method
    if (!isGuest && mockSavedPaymentMethods.length > 0) {
      setPaymentMethod('saved')
    } else if (hasApplePay) {
      setPaymentMethod('apple_pay')
    } else {
      setPaymentMethod('new')
    }
  }, [isGuest])

  const formatCardNumber = (value: string) => {
    const v = value.replace(/\s+/g, '').replace(/[^0-9]/gi, '')
    const matches = v.match(/\d{4,16}/g)
    const match = matches && matches[0] || ''
    const parts = []
    for (let i = 0, len = match.length; i < len; i += 4) {
      parts.push(match.substring(i, i + 4))
    }
    if (parts.length) {
      return parts.join(' ')
    } else {
      return v
    }
  }

  const formatExpiryDate = (value: string) => {
    const v = value.replace(/\s+/g, '').replace(/[^0-9]/gi, '')
    if (v.length >= 2) {
      return `${v.substring(0, 2)}/${v.substring(2, 4)}`
    }
    return v
  }

  const handleCardFormChange = (field: string, value: string) => {
    let formattedValue = value
    
    if (field === 'cardNumber') {
      formattedValue = formatCardNumber(value)
    } else if (field === 'expiryDate') {
      formattedValue = formatExpiryDate(value)
    } else if (field === 'cvv') {
      formattedValue = value.replace(/[^0-9]/gi, '').substring(0, 4)
    }
    
    setCardForm(prev => ({
      ...prev,
      [field]: formattedValue
    }))
  }

  const validateCardForm = () => {
    const { cardNumber, expiryDate, cvv, name } = cardForm
    
    if (!cardNumber || cardNumber.replace(/\s/g, '').length < 16) {
      setError('Please enter a valid card number')
      return false
    }
    
    if (!expiryDate || expiryDate.length !== 5) {
      setError('Please enter a valid expiry date')
      return false
    }
    
    if (!cvv || cvv.length < 3) {
      setError('Please enter a valid CVV')
      return false
    }
    
    if (!name.trim()) {
      setError('Please enter the cardholder name')
      return false
    }
    
    return true
  }

  const processPayment = async () => {
    setIsProcessing(true)
    setError(null)
    
    try {
      // Simulate API call delay
      await new Promise(resolve => setTimeout(resolve, 2000))
      
      let paymentData: PaymentData
      
      switch (paymentMethod) {
        case 'saved':
          const savedMethod = mockSavedPaymentMethods.find(m => m.id === selectedSavedMethod)
          paymentData = {
            paymentMethod: 'card',
            amount: classData.price,
            currency: 'USD',
            cardLast4: savedMethod?.last4,
            transactionId: `txn_${Date.now()}`,
            paymentIntentId: `pi_${Date.now()}`
          }
          break
          
        case 'new':
          if (!validateCardForm()) {
            setIsProcessing(false)
            return
          }
          paymentData = {
            paymentMethod: 'card',
            amount: classData.price,
            currency: 'USD',
            cardLast4: cardForm.cardNumber.slice(-4),
            transactionId: `txn_${Date.now()}`,
            paymentIntentId: `pi_${Date.now()}`
          }
          break
          
        case 'apple_pay':
          paymentData = {
            paymentMethod: 'apple_pay',
            amount: classData.price,
            currency: 'USD',
            transactionId: `txn_${Date.now()}`
          }
          break
          
        case 'google_pay':
          paymentData = {
            paymentMethod: 'google_pay',
            amount: classData.price,
            currency: 'USD',
            transactionId: `txn_${Date.now()}`
          }
          break
          
        case 'credits':
          paymentData = {
            paymentMethod: 'credits',
            amount: classData.price,
            currency: 'USD',
            transactionId: `txn_${Date.now()}`
          }
          break
          
        default:
          throw new Error('Invalid payment method')
      }
      
      setSuccess(true)
      
      // Delay for success animation
      setTimeout(() => {
        onPaymentComplete(paymentData)
      }, 1500)
      
    } catch (error) {
      console.error('Payment failed:', error)
      setError('Payment failed. Please try again.')
      setIsProcessing(false)
    }
  }

  const canPayWithCredits = isCreditsEnabled && userCredits >= paymentModel.defaultCreditsPerClass

  if (success) {
    return (
      <div className="text-center py-12">
        <CheckCircleIcon className="w-16 h-16 text-green-500 mx-auto mb-4" />
        <h3 className="text-xl font-semibold text-gray-900 mb-2">Payment Successful!</h3>
        <p className="text-gray-600">Processing your booking...</p>
      </div>
    )
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="text-center pb-6 border-b border-gray-200">
        <h2 className="text-2xl font-bold text-gray-900 mb-2">Complete Payment</h2>
        <div className="bg-gray-50 rounded-lg p-4">
          <h3 className="font-semibold text-gray-900">{classData.title}</h3>
          <p className="text-sm text-gray-600">with {classData.instructor.name}</p>
          {classData.nextSession && (
            <p className="text-sm text-gray-600 mt-1">
              {new Date(classData.nextSession.date).toLocaleDateString()} at {classData.nextSession.timeSlot}
            </p>
          )}
          <div className="text-2xl font-bold text-gray-900 mt-2">${classData.price}</div>
        </div>
      </div>

      {/* Payment method selection */}
      <div className="space-y-4">
        <h3 className="text-lg font-semibold text-gray-900">Payment Method</h3>
        
        {/* Credits option */}
        {canPayWithCredits && (
          <label className="relative">
            <input
              type="radio"
              name="paymentMethod"
              value="credits"
              checked={paymentMethod === 'credits'}
              onChange={(e) => setPaymentMethod(e.target.value as any)}
              className="sr-only"
            />
            <div className={`border-2 rounded-lg p-4 cursor-pointer transition-all ${
              paymentMethod === 'credits' 
                ? 'border-indigo-500 bg-indigo-50' 
                : 'border-gray-200 hover:border-gray-300'
            }`}>
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <CurrencyDollarIcon className="w-6 h-6 text-indigo-600 mr-3" />
                  <div>
                    <p className="font-medium text-gray-900">Use Credits</p>
                    <p className="text-sm text-gray-600">
                      You have {userCredits} credits available
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <p className="font-semibold text-indigo-600">
                    {paymentModel.defaultCreditsPerClass} credits
                  </p>
                  <p className="text-xs text-gray-500">
                    {userCredits - paymentModel.defaultCreditsPerClass} remaining
                  </p>
                </div>
              </div>
            </div>
          </label>
        )}

        {/* Saved payment methods */}
        {!isGuest && mockSavedPaymentMethods.length > 0 && (
          <div className="space-y-2">
            {mockSavedPaymentMethods.map((method) => (
              <label key={method.id} className="relative">
                <input
                  type="radio"
                  name="paymentMethod"
                  value="saved"
                  checked={paymentMethod === 'saved' && selectedSavedMethod === method.id}
                  onChange={() => {
                    setPaymentMethod('saved')
                    setSelectedSavedMethod(method.id)
                  }}
                  className="sr-only"
                />
                <div className={`border-2 rounded-lg p-4 cursor-pointer transition-all ${
                  paymentMethod === 'saved' && selectedSavedMethod === method.id
                    ? 'border-indigo-500 bg-indigo-50' 
                    : 'border-gray-200 hover:border-gray-300'
                }`}>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center">
                      <CreditCardIcon className="w-6 h-6 text-gray-400 mr-3" />
                      <div>
                        <p className="font-medium text-gray-900">
                          {method.brand.charAt(0).toUpperCase() + method.brand.slice(1)} •••• {method.last4}
                        </p>
                        <p className="text-sm text-gray-600">
                          Expires {method.expiryMonth}/{method.expiryYear}
                        </p>
                      </div>
                    </div>
                    {method.isDefault && (
                      <span className="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-800">
                        Default
                      </span>
                    )}
                  </div>
                </div>
              </label>
            ))}
          </div>
        )}

        {/* Apple Pay */}
        <label className="relative">
          <input
            type="radio"
            name="paymentMethod"
            value="apple_pay"
            checked={paymentMethod === 'apple_pay'}
            onChange={(e) => setPaymentMethod(e.target.value as any)}
            className="sr-only"
          />
          <div className={`border-2 rounded-lg p-4 cursor-pointer transition-all ${
            paymentMethod === 'apple_pay' 
              ? 'border-indigo-500 bg-indigo-50' 
              : 'border-gray-200 hover:border-gray-300'
          }`}>
            <div className="flex items-center">
              <div className="w-6 h-6 bg-black rounded mr-3 flex items-center justify-center">
                <span className="text-white text-xs font-bold">A</span>
              </div>
              <p className="font-medium text-gray-900">Apple Pay</p>
            </div>
          </div>
        </label>

        {/* Google Pay */}
        <label className="relative">
          <input
            type="radio"
            name="paymentMethod"
            value="google_pay"
            checked={paymentMethod === 'google_pay'}
            onChange={(e) => setPaymentMethod(e.target.value as any)}
            className="sr-only"
          />
          <div className={`border-2 rounded-lg p-4 cursor-pointer transition-all ${
            paymentMethod === 'google_pay' 
              ? 'border-indigo-500 bg-indigo-50' 
              : 'border-gray-200 hover:border-gray-300'
          }`}>
            <div className="flex items-center">
              <div className="w-6 h-6 bg-blue-500 rounded mr-3 flex items-center justify-center">
                <span className="text-white text-xs font-bold">G</span>
              </div>
              <p className="font-medium text-gray-900">Google Pay</p>
            </div>
          </div>
        </label>

        {/* New card */}
        <label className="relative">
          <input
            type="radio"
            name="paymentMethod"
            value="new"
            checked={paymentMethod === 'new'}
            onChange={(e) => setPaymentMethod(e.target.value as any)}
            className="sr-only"
          />
          <div className={`border-2 rounded-lg p-4 cursor-pointer transition-all ${
            paymentMethod === 'new' 
              ? 'border-indigo-500 bg-indigo-50' 
              : 'border-gray-200 hover:border-gray-300'
          }`}>
            <div className="flex items-center">
              <CreditCardIcon className="w-6 h-6 text-gray-400 mr-3" />
              <p className="font-medium text-gray-900">New Credit or Debit Card</p>
            </div>
          </div>
        </label>
      </div>

      {/* New card form */}
      {paymentMethod === 'new' && (
        <div className="space-y-4 border-t border-gray-200 pt-6">
          <div className="grid grid-cols-1 gap-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Card Number
              </label>
              <input
                type="text"
                placeholder="1234 5678 9012 3456"
                value={cardForm.cardNumber}
                onChange={(e) => handleCardFormChange('cardNumber', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                maxLength={19}
              />
            </div>
            
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Expiry Date
                </label>
                <input
                  type="text"
                  placeholder="MM/YY"
                  value={cardForm.expiryDate}
                  onChange={(e) => handleCardFormChange('expiryDate', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                  maxLength={5}
                />
              </div>
              
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  CVV
                </label>
                <input
                  type="text"
                  placeholder="123"
                  value={cardForm.cvv}
                  onChange={(e) => handleCardFormChange('cvv', e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                  maxLength={4}
                />
              </div>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Cardholder Name
              </label>
              <input
                type="text"
                placeholder="John Doe"
                value={cardForm.name}
                onChange={(e) => handleCardFormChange('name', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                ZIP Code
              </label>
              <input
                type="text"
                placeholder="12345"
                value={cardForm.zipCode}
                onChange={(e) => handleCardFormChange('zipCode', e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md focus:ring-indigo-500 focus:border-indigo-500"
                maxLength={10}
              />
            </div>
          </div>
          
          {!isGuest && (
            <label className="flex items-center">
              <input
                type="checkbox"
                checked={saveCard}
                onChange={(e) => setSaveCard(e.target.checked)}
                className="rounded border-gray-300 text-indigo-600 focus:ring-indigo-500"
              />
              <span className="ml-2 text-sm text-gray-700">
                Save this card for future purchases
              </span>
            </label>
          )}
        </div>
      )}

      {/* Security notice */}
      <div className="bg-gray-50 rounded-lg p-4 flex items-start">
        <ShieldCheckIcon className="w-5 h-5 text-green-600 mt-0.5 mr-3 flex-shrink-0" />
        <div className="text-sm text-gray-600">
          <p className="font-medium text-gray-900 mb-1">Secure Payment</p>
          <p>Your payment information is encrypted and secure. We never store your full card details.</p>
        </div>
      </div>

      {/* Error message */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 flex items-start">
          <ExclamationTriangleIcon className="w-5 h-5 text-red-600 mt-0.5 mr-3 flex-shrink-0" />
          <div className="text-sm text-red-700">
            <p className="font-medium">Payment Error</p>
            <p>{error}</p>
          </div>
        </div>
      )}

      {/* Action buttons */}
      <div className="flex space-x-4 pt-6 border-t border-gray-200">
        <button
          type="button"
          onClick={onBack}
          disabled={isProcessing}
          className="flex-1 px-6 py-3 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-50 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
        >
          Back
        </button>
        
        <button
          type="button"
          onClick={processPayment}
          disabled={isProcessing}
          className="flex-1 px-6 py-3 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors font-medium"
        >
          {isProcessing ? (
            <div className="flex items-center justify-center">
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
              Processing...
            </div>
          ) : (
            `Pay $${classData.price}`
          )}
        </button>
      </div>
    </div>
  )
}
