import * as React from "react"
import { cn } from "@/lib/utils"
import { Button } from "./button"
import { Calendar } from "lucide-react"

type DivProps = React.HTMLAttributes<HTMLDivElement>

interface DatePickerWithRangeProps extends Omit<DivProps, "onSelect"> {
  from?: Date
  to?: Date
  onSelect?: (range: { from: Date; to: Date }) => void
}

// Simplified date range picker - in production you'd use a library
export function DatePickerWithRange({
  className,
  from,
  to,
  onSelect,
  ...props
}: DatePickerWithRangeProps) {
  const handleSelect = () => {
    const now = new Date()
    onSelect?.({ from: from ?? now, to: to ?? now })
  }

  return (
    <div className={cn("grid gap-2", className)} {...props}>
      <Button
        variant="outline"
        className="justify-start text-left font-normal"
        onClick={handleSelect}
      >
        <Calendar className="mr-2 h-4 w-4" />
        {from ? (
          to ? (
            <>
              {from.toLocaleDateString()} - {to.toLocaleDateString()}
            </>
          ) : (
            from.toLocaleDateString()
          )
        ) : (
          <span>Pick a date range</span>
        )}
      </Button>
    </div>
  )
}
