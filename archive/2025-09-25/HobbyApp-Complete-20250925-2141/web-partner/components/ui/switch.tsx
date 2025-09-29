import * as React from "react"
import { cn } from "@/lib/utils"

interface SwitchProps extends Omit<React.ButtonHTMLAttributes<HTMLButtonElement>, 'onChange'> {
  checked?: boolean
  onCheckedChange?: (checked: boolean) => void
  defaultChecked?: boolean
}

const Switch = React.forwardRef<HTMLButtonElement, SwitchProps>(
  ({ className, checked, onCheckedChange, defaultChecked = false, ...props }, ref) => {
    const [isChecked, setIsChecked] = React.useState(defaultChecked)
    const actualChecked = checked !== undefined ? checked : isChecked
    
    const handleClick = () => {
      const newChecked = !actualChecked
      if (onCheckedChange) {
        onCheckedChange(newChecked)
      } else {
        setIsChecked(newChecked)
      }
    }

    return (
      <button
        type="button"
        role="switch"
        aria-checked={actualChecked}
        ref={ref}
        onClick={handleClick}
        className={cn(
          "peer inline-flex h-6 w-11 shrink-0 cursor-pointer items-center rounded-full border-2 border-transparent transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50",
          actualChecked ? "bg-blue-600" : "bg-gray-200",
          className
        )}
        {...props}
      >
        <span
          className={cn(
            "pointer-events-none block h-5 w-5 rounded-full bg-white shadow-lg ring-0 transition-transform",
            actualChecked ? "translate-x-5" : "translate-x-0"
          )}
        />
      </button>
    )
  }
)
Switch.displayName = "Switch"

export { Switch }