```

██████╗ ███████╗ ██████╗         ███████╗██████╗ ██╗   ██╗
██╔══██╗██╔════╝██╔════╝         ██╔════╝██╔══██╗██║   ██║
██████╔╝███████╗██║  ███╗        █████╗  ██████╔╝██║   ██║
██╔══██╗╚════██║██║   ██║        ██╔══╝  ██╔═══╝ ██║   ██║
██████╔╝███████║╚██████╔╝███████╗██║     ██║     ╚██████╔╝
╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝      ╚═════╝ 


BaseJump Floating-Point Arithmetic Core


This library implements IEEE-754 floating-point arithmetic operators: add, sub, mul, cmp, i2f, f2i.
These modules are parameterizable by exponent and mantissa bit-width (e_p, m_p), which the users
can specify to pick the floating-point encoding of their choice.

Typical values for these parameters are: 

----------------------------------------------
              exponent (e_p)    mantissa (m_p) 
----------------------------------------------
binary64      11                52
binary32      8                 23
binary16      5                 10
bfloat16      8                 7
----------------------------------------------


1.  bsg_fpu_add_sub

    - 3-stage pipeline.
    - rounding mode is "round to nearest even".
    - If either input is signaling NaN, the output is signaling NaN,
      and invalid exceptinon is raised.
    - If either input is quiet NaN, output is set to quiet NaN.
    - If both inputs are infinite, output is set to either infinite or quiet NaN,
      depending on sub_i and signs of inputs.
      For example, pos_infty plus pos_infty results in pos_infty, whereas
      pos_infty plus neg_infty results in quiet NaN.
    - If either input is denormal, then output is set to quiet NaN,
      and unimplemented exception is raised.
    - If the sum or diff results in denormal, then output is set to zero,
      and underflow exception is raised.
    - If the result underflows, then the output is set to zero,
      and underflow exception is raised.
    - If the result overflows, then the output is set to infinity,
      and overflow exception is raised.

2.  bsg_fpu_mul

    - 3-stage pipeline.
    - rounding mode is "round to nearest even".
    - If either input is signaling NaN, output is set to signaling NaN, and invalid exception is raised.
    - If either input is quiet NaN, output is set to quiet NaN.
    - If one input is infinite and the other is finite, then the output is set to infinity.
    - If one input is infinite and the other is zero, then the output is set to quiet NaN,
      and invalid exception is raised.
    - If one input zero and the other is non-zero, then the output is set to zero.
    - If both inputs are denormal, then the output is set to zero, and underflow exception is raised.
    - If one input is denormal, and the other is not denormal, then the output is set to quiet NaN,
      and unimplemented exception is raised.
    - If the product results in denormal, then the output is set to zero,
      and underflow exception is raised.
    - If the result underflows, then the output is set to zero,
      and underflow exception is raised.
    - If the result overflows, then the output is set to infinitiy,
      and overflow exception is raised.

3.  bsg_fpu_cmp
    - No pipeline stage.
    - This module computes less-than, equal, less-than-or-equal.
    - This module also computes min and max.
    

4.  bsg_fpu_i2f
    - 1-stage pipeline
    - there is a port (signed_i) to decide whether the input integer is signed or unsigned.

5.  bsg_fpu_f2i
    - No pipeline stage.
    - there is a port (signed_i) to decide whether the output integer is signed or unsigned.
    - If the input is negative float and the output is chosen to be unsigned,
      then the output is set to zero and invalid exception is raised.
    - If the input is (+/-) zero, or exponent is too small or big, or the input is NaN,
      then the output is set to zero and invalid exception is raised.



```
