# bsg_fpu

### bsg_fpu_cmp

This is a floating-point comparator. It can calculate >, <, ==, !=, >=, <=, depending on subop code you provide as an input.

There is no pipeline stage for this module.

### bsg_fpu_add_sub

This is a floating-point adder/subtractor. There are 3 pipeline stages.

Input-side has ready-valid handshake interface.

Output-side has yumi-valid handshake interface.

Its rounding mode is "round to nearest even".

Here is the description of output behavior.

- If either input is signaling NaN, output is set to signaling NaN (0x7fbfffff), and invalid exception is raised.

- If either input is quiet NaN, output is set to quiet NaN (0x7fffffff).

- If both inputs are infinite, output is set to either infinite or quiet NaN, depending on sub_i and signs of inputs. For example, positive infinity plus positive infinity results in positive infinite, whereas positive infinity minus positive infinity results in quiet NaN.

- If either input is denormal, then output is set to quiet NaN, and unimplemented exception is raised.

- If the sum or difference results in denormal, then output is set to zero, and underflow exception is raised.

- If the result underflows, then output is set to zero, and underflow exception is raised.

- If the result overflows, the output is set to infinitiy, and overflow exception is raised.

### bsg_fpu_mul

This is a floating-point multiplier. There are 3 pipeline stages.

Input-side has ready-valid handshake interface.

Output-side has yumi-valid handshake interface.

Its rounding mode is "round to nearest even".

Here is the description of output behavior.

- If either input is signaling NaN, output is set to signaling NaN (0x7fbfffff), and invalid exception is raised.

- If either input is quiet NaN, output is set to quiet NaN (0x7fffffff).

- If one input is infinite and the other is non-zero, then output is set to infinity.

- If one input is infinite and the other is zero, then output is set to quiet NaN, and invalid exception is raised.

- If one input zero and the other is non-zero, then output is set to zero.

- If both inputs are denormal, then output is set to zero, and underflow exception is raised.

- If one input is denormal, and the other is not denormal, then output is set to quiet NaN, and unimplemented exception is raised.

- If the product results in denormal, then output is set to zero, and underflow exception is raised.

- If the result underflows, then output is set to zero, and underflow exception is raised.

- If the result overflows, the output is set to infinitiy, and overflow exception is raised.

### bsg_fpu_i2f

This module converts from signed integer to float.

### bsg_fpu_f2i

This module converts from float to signed integer.

Rounding modes for RISC-V ISA are implemented.

- RNE : round-to-nearest, ties to even (default) 

- RTZ : round-towards-zero (truncate)

- RDN : round-down (floor)

- RUP : round-up (ceil)

- RMM : round-to-nearest, ties to max magnitude (what we learned in grade school).

### Testing

Testing was originally done with trace files. C source code to generate trace patterns is under the directory named "/testing/bsg_fpu".

### Change Log

- 2018-06-19 - added bsg_fpu_i2f_32.

- 2018-06-21 - added bsg_fpu_f2i_32.

- 2018-06-25 - parameterized bsg_fpu_add_sub to support 32/64-bit.
