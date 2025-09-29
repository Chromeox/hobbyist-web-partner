import * as React from "react"
import { cn } from "@/lib/utils"

interface CalendarProps extends React.HTMLAttributes<HTMLDivElement> {
  mode?: "single" | "range"
  selected?: Date
  onSelect?: (date: Date | undefined) => void
}

// Simplified calendar component - in production you'd use a library like react-day-picker
const Calendar = React.forwardRef<HTMLDivElement, CalendarProps>(
  ({ className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn("p-3 bg-white border rounded-lg", className)}
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