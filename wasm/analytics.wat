;; WebAssembly Text Format for Analytics Module
;; High-performance calculations for Hobbyist platform

(module
  ;; Import JavaScript memory
  (import "js" "memory" (memory 1))
  
  ;; Import console.log for debugging
  (import "console" "log" (func $log (param i32)))
  
  ;; Export memory for JavaScript access
  (export "memory" (memory 0))
  
  ;; Fast moving average calculation
  ;; Input: array pointer, length
  ;; Output: average as f32
  (func $movingAverage (export "movingAverage") 
    (param $ptr i32) 
    (param $len i32) 
    (result f32)
    (local $sum f32)
    (local $i i32)
    (local $end i32)
    
    ;; Initialize sum to 0
    (local.set $sum (f32.const 0))
    
    ;; Calculate end position
    (local.set $end 
      (i32.add 
        (local.get $ptr)
        (i32.mul (local.get $len) (i32.const 4))
      )
    )
    
    ;; Loop through array
    (local.set $i (local.get $ptr))
    (block $break
      (loop $continue
        ;; Check if we've reached the end
        (br_if $break 
          (i32.ge_u (local.get $i) (local.get $end))
        )
        
        ;; Add current value to sum
        (local.set $sum
          (f32.add
            (local.get $sum)
            (f32.load (local.get $i))
          )
        )
        
        ;; Increment pointer by 4 bytes (size of f32)
        (local.set $i 
          (i32.add (local.get $i) (i32.const 4))
        )
        
        (br $continue)
      )
    )
    
    ;; Calculate and return average
    (f32.div
      (local.get $sum)
      (f32.convert_i32_s (local.get $len))
    )
  )
  
  ;; Calculate standard deviation
  (func $standardDeviation (export "standardDeviation")
    (param $ptr i32)
    (param $len i32)
    (param $mean f32)
    (result f32)
    (local $variance f32)
    (local $diff f32)
    (local $i i32)
    (local $end i32)
    
    (local.set $variance (f32.const 0))
    
    ;; Calculate end position
    (local.set $end 
      (i32.add 
        (local.get $ptr)
        (i32.mul (local.get $len) (i32.const 4))
      )
    )
    
    ;; Calculate variance
    (local.set $i (local.get $ptr))
    (block $break
      (loop $continue
        (br_if $break 
          (i32.ge_u (local.get $i) (local.get $end))
        )
        
        ;; Calculate difference from mean
        (local.set $diff
          (f32.sub
            (f32.load (local.get $i))
            (local.get $mean)
          )
        )
        
        ;; Add squared difference to variance
        (local.set $variance
          (f32.add
            (local.get $variance)
            (f32.mul (local.get $diff) (local.get $diff))
          )
        )
        
        (local.set $i 
          (i32.add (local.get $i) (i32.const 4))
        )
        
        (br $continue)
      )
    )
    
    ;; Return standard deviation (sqrt of variance/n)
    (f32.sqrt
      (f32.div
        (local.get $variance)
        (f32.convert_i32_s (local.get $len))
      )
    )
  )
  
  ;; Linear regression slope calculation
  (func $linearRegressionSlope (export "linearRegressionSlope")
    (param $xPtr i32)
    (param $yPtr i32)
    (param $len i32)
    (result f32)
    (local $sumX f32)
    (local $sumY f32)
    (local $sumXY f32)
    (local $sumXX f32)
    (local $i i32)
    (local $n f32)
    (local $x f32)
    (local $y f32)
    
    ;; Initialize sums
    (local.set $sumX (f32.const 0))
    (local.set $sumY (f32.const 0))
    (local.set $sumXY (f32.const 0))
    (local.set $sumXX (f32.const 0))
    (local.set $n (f32.convert_i32_s (local.get $len)))
    
    ;; Calculate sums
    (local.set $i (i32.const 0))
    (block $break
      (loop $continue
        (br_if $break 
          (i32.ge_u (local.get $i) (local.get $len))
        )
        
        ;; Load x and y values
        (local.set $x 
          (f32.load 
            (i32.add 
              (local.get $xPtr)
              (i32.mul (local.get $i) (i32.const 4))
            )
          )
        )
        
        (local.set $y 
          (f32.load 
            (i32.add 
              (local.get $yPtr)
              (i32.mul (local.get $i) (i32.const 4))
            )
          )
        )
        
        ;; Update sums
        (local.set $sumX (f32.add (local.get $sumX) (local.get $x)))
        (local.set $sumY (f32.add (local.get $sumY) (local.get $y)))
        (local.set $sumXY 
          (f32.add 
            (local.get $sumXY)
            (f32.mul (local.get $x) (local.get $y))
          )
        )
        (local.set $sumXX 
          (f32.add 
            (local.get $sumXX)
            (f32.mul (local.get $x) (local.get $x))
          )
        )
        
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $continue)
      )
    )
    
    ;; Calculate and return slope
    ;; slope = (n*sumXY - sumX*sumY) / (n*sumXX - sumX*sumX)
    (f32.div
      (f32.sub
        (f32.mul (local.get $n) (local.get $sumXY))
        (f32.mul (local.get $sumX) (local.get $sumY))
      )
      (f32.sub
        (f32.mul (local.get $n) (local.get $sumXX))
        (f32.mul (local.get $sumX) (local.get $sumX))
      )
    )
  )
  
  ;; Calculate percentile
  (func $percentile (export "percentile")
    (param $ptr i32)
    (param $len i32)
    (param $p f32) ;; Percentile (0-100)
    (result f32)
    (local $index f32)
    (local $lower i32)
    (local $upper i32)
    (local $weight f32)
    (local $lowerVal f32)
    (local $upperVal f32)
    
    ;; Calculate index
    (local.set $index
      (f32.mul
        (f32.div (local.get $p) (f32.const 100))
        (f32.convert_i32_s (i32.sub (local.get $len) (i32.const 1)))
      )
    )
    
    ;; Get lower and upper indices
    (local.set $lower (i32.trunc_f32_s (local.get $index)))
    (local.set $upper 
      (i32.min
        (i32.add (local.get $lower) (i32.const 1))
        (i32.sub (local.get $len) (i32.const 1))
      )
    )
    
    ;; Calculate weight for interpolation
    (local.set $weight 
      (f32.sub 
        (local.get $index)
        (f32.convert_i32_s (local.get $lower))
      )
    )
    
    ;; Load values
    (local.set $lowerVal
      (f32.load
        (i32.add
          (local.get $ptr)
          (i32.mul (local.get $lower) (i32.const 4))
        )
      )
    )
    
    (local.set $upperVal
      (f32.load
        (i32.add
          (local.get $ptr)
          (i32.mul (local.get $upper) (i32.const 4))
        )
      )
    )
    
    ;; Interpolate and return
    (f32.add
      (local.get $lowerVal)
      (f32.mul
        (local.get $weight)
        (f32.sub (local.get $upperVal) (local.get $lowerVal))
      )
    )
  )
  
  ;; Fast correlation coefficient
  (func $correlation (export "correlation")
    (param $xPtr i32)
    (param $yPtr i32)
    (param $len i32)
    (result f32)
    (local $sumX f32)
    (local $sumY f32)
    (local $sumXY f32)
    (local $sumX2 f32)
    (local $sumY2 f32)
    (local $n f32)
    (local $i i32)
    (local $x f32)
    (local $y f32)
    (local $numerator f32)
    (local $denominator f32)
    
    ;; Initialize
    (local.set $n (f32.convert_i32_s (local.get $len)))
    (local.set $sumX (f32.const 0))
    (local.set $sumY (f32.const 0))
    (local.set $sumXY (f32.const 0))
    (local.set $sumX2 (f32.const 0))
    (local.set $sumY2 (f32.const 0))
    
    ;; Calculate sums
    (local.set $i (i32.const 0))
    (block $break
      (loop $continue
        (br_if $break (i32.ge_u (local.get $i) (local.get $len)))
        
        ;; Load values
        (local.set $x 
          (f32.load 
            (i32.add 
              (local.get $xPtr)
              (i32.mul (local.get $i) (i32.const 4))
            )
          )
        )
        
        (local.set $y 
          (f32.load 
            (i32.add 
              (local.get $yPtr)
              (i32.mul (local.get $i) (i32.const 4))
            )
          )
        )
        
        ;; Update sums
        (local.set $sumX (f32.add (local.get $sumX) (local.get $x)))
        (local.set $sumY (f32.add (local.get $sumY) (local.get $y)))
        (local.set $sumXY 
          (f32.add 
            (local.get $sumXY)
            (f32.mul (local.get $x) (local.get $y))
          )
        )
        (local.set $sumX2 
          (f32.add 
            (local.get $sumX2)
            (f32.mul (local.get $x) (local.get $x))
          )
        )
        (local.set $sumY2 
          (f32.add 
            (local.get $sumY2)
            (f32.mul (local.get $y) (local.get $y))
          )
        )
        
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $continue)
      )
    )
    
    ;; Calculate correlation coefficient
    (local.set $numerator
      (f32.sub
        (f32.mul (local.get $n) (local.get $sumXY))
        (f32.mul (local.get $sumX) (local.get $sumY))
      )
    )
    
    (local.set $denominator
      (f32.sqrt
        (f32.mul
          (f32.sub
            (f32.mul (local.get $n) (local.get $sumX2))
            (f32.mul (local.get $sumX) (local.get $sumX))
          )
          (f32.sub
            (f32.mul (local.get $n) (local.get $sumY2))
            (f32.mul (local.get $sumY) (local.get $sumY))
          )
        )
      )
    )
    
    ;; Return correlation (handle division by zero)
    (if (result f32)
      (f32.eq (local.get $denominator) (f32.const 0))
      (then (f32.const 0))
      (else 
        (f32.div (local.get $numerator) (local.get $denominator))
      )
    )
  )
  
  ;; Fast matrix multiplication for predictions
  (func $matrixMultiply (export "matrixMultiply")
    (param $aPtr i32) ;; Matrix A pointer
    (param $bPtr i32) ;; Matrix B pointer
    (param $cPtr i32) ;; Result matrix C pointer
    (param $m i32)    ;; Rows in A
    (param $n i32)    ;; Cols in A, Rows in B
    (param $p i32)    ;; Cols in B
    (local $i i32)
    (local $j i32)
    (local $k i32)
    (local $sum f32)
    (local $aVal f32)
    (local $bVal f32)
    
    ;; Triple nested loop for matrix multiplication
    (local.set $i (i32.const 0))
    (block $breakI
      (loop $continueI
        (br_if $breakI (i32.ge_u (local.get $i) (local.get $m)))
        
        (local.set $j (i32.const 0))
        (block $breakJ
          (loop $continueJ
            (br_if $breakJ (i32.ge_u (local.get $j) (local.get $p)))
            
            (local.set $sum (f32.const 0))
            (local.set $k (i32.const 0))
            (block $breakK
              (loop $continueK
                (br_if $breakK (i32.ge_u (local.get $k) (local.get $n)))
                
                ;; Load A[i][k]
                (local.set $aVal
                  (f32.load
                    (i32.add
                      (local.get $aPtr)
                      (i32.mul
                        (i32.add
                          (i32.mul (local.get $i) (local.get $n))
                          (local.get $k)
                        )
                        (i32.const 4)
                      )
                    )
                  )
                )
                
                ;; Load B[k][j]
                (local.set $bVal
                  (f32.load
                    (i32.add
                      (local.get $bPtr)
                      (i32.mul
                        (i32.add
                          (i32.mul (local.get $k) (local.get $p))
                          (local.get $j)
                        )
                        (i32.const 4)
                      )
                    )
                  )
                )
                
                ;; Add to sum
                (local.set $sum
                  (f32.add
                    (local.get $sum)
                    (f32.mul (local.get $aVal) (local.get $bVal))
                  )
                )
                
                (local.set $k (i32.add (local.get $k) (i32.const 1)))
                (br $continueK)
              )
            )
            
            ;; Store C[i][j] = sum
            (f32.store
              (i32.add
                (local.get $cPtr)
                (i32.mul
                  (i32.add
                    (i32.mul (local.get $i) (local.get $p))
                    (local.get $j)
                  )
                  (i32.const 4)
                )
              )
              (local.get $sum)
            )
            
            (local.set $j (i32.add (local.get $j) (i32.const 1)))
            (br $continueJ)
          )
        )
        
        (local.set $i (i32.add (local.get $i) (i32.const 1)))
        (br $continueI)
      )
    )
  )
)