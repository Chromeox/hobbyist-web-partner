import * as React from "react"

interface Toast {
  id: string
  title?: string
  description?: string
  variant?: "default" | "destructive"
}

interface ToastContextValue {
  toasts: Toast[]
  toast: (toast: Omit<Toast, "id">) => void
  dismiss: (id: string) => void
}

const ToastContext = React.createContext<ToastContextValue | undefined>(undefined)

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = React.useState<Toast[]>([])

  const toast = React.useCallback((newToast: Omit<Toast, "id">) => {
    const id = Date.now().toString()
    const toastWithId = { ...newToast, id }
    
    setToasts((prev) => [...prev, toastWithId])
    
    // Auto dismiss after 5 seconds
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id))
    }, 5000)
  }, [])

  const dismiss = React.useCallback((id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  return (
    <ToastContext.Provider value={{ toasts, toast, dismiss }}>
      {children}
      {/* Toast display container */}
      <div className="fixed bottom-0 right-0 z-50 m-4 flex flex-col gap-2">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={`rounded-lg border p-4 shadow-lg transition-all ${
              toast.variant === "destructive"
                ? "border-red-200 bg-red-50 text-red-900"
                : "border-gray-200 bg-white text-gray-900"
            }`}
          >
            {toast.title && <div className="font-semibold">{toast.title}</div>}
            {toast.description && (
              <div className="mt-1 text-sm opacity-90">{toast.description}</div>
            )}
            <button
              onClick={() => dismiss(toast.id)}
              className="absolute right-2 top-2 text-gray-400 hover:text-gray-600"
            >
              ×
            </button>
          </div>
        ))}
      </div>
    </ToastContext.Provider>
  )
}

export function useToast() {
  const context = React.useContext(ToastContext)
  
  if (!context) {
    // Return a no-op implementation if provider is missing
    return {
      toast: () => {},
      dismiss: () => {},
      toasts: []
    }
  }
  
  return context
}