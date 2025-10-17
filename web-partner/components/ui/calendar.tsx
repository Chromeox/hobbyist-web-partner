import * as React from "react"
import { cn } from "@/lib/utils"

type DivProps = React.HTMLAttributes<HTMLDivElement>

interface CalendarProps extends Omit<DivProps, "onSelect"> {
  mode?: "single" | "range"
  selected?: Date
  onSelect?: (date: Date | undefined) => void
}

// Simplified calendar component - in production you'd use a library like react-day-picker
const Calendar = React.forwardRef<HTMLDivElement, CalendarProps>(
  ({ className, onSelect, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn("p-3 bg-white border rounded-lg", className)}
        onClick={() => onSelect?.(new Date())}
        {...props}
      >
        <div className="text-center text-sm text-gray-500">
          Calendar component placeholder
        </div>
      </div>
    )
  }
)
Calendar.displayName = "Calendar"

export { Calendar }
