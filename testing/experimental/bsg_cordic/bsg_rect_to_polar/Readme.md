# bsg_cordic_rect_to_polar
This is a CORDIC based design to convert a pair of cartesian coordinates to polar coordinates. `x_i` and `y_i` are two inputs to the module and outputs the magnitude value in `mag_o` and angle in `angl_o` The default rule for `make` is generating Verilog module file with default parameters and **params_def.h** which enables access of the parameters passed to the script for verilator testing. The design converges for the values from all four quadrants. The angular value is represented in degrees and in the range [-180 , 180].

### Input and Output Representation
All the quantities are treated and represented as fixed-point signed numbers. If the `angbitlen` is 20 and `precision` is 12 bits, then answer is represented as 0xAA.BBB and if ansbitlen is 40, then `quant_i` is represented as 0xQQQQQQQ.YYY.This includes 1 overflow-bit as well.


### Module and Script parameters
Generate the Verilog module with **bsg_rect_to_polar_script.py** script which generates the **params_def.h** as well. The following arguments are passed to the script:  

**angbitlen** : Defines the bit-length of the angular ('z' in CORDIC naming) datapath. Has a precision of `precision`  bits. These 'z'-register values represent the output of the polar angle. The output is in **degrees**. 
Choose this carefully to accommodate the angles of the look-up table, maximum input quantity as well as the number of precision bits. Determining this bit-length is pretty straightforward.  
`angbitlen` = 1 sign-bit + bit-length of [180] + `precision` bits. The number of precision bits, in this case, is **very important** due to the highly non-linear nature of this function. Choose these precision bits by first determining the decimal precision up to which you'd like the polar angle answer. For example, if it's 0.000001, then the minimum bits needed to represent this precision is -log2(0.000001) where log2 represents log to the base-2. (round off the quantity obtained to the next big integer).  

**ansbitlen**: Defines the bit-length of the magnitude ('x' and 'y' in CORDIC naming) datapath. Also has a precision of 'precision' bits but a special property of convergence in this module is that the input precision defines the output precision. In this way, the precision can be changed on the fly and the angle value will converge correctly for any valid set of values. Determine this length by: 1 sign-bit +  bit-length of [ max_input_quantity ] + `precision` bits. It's recommended to use at least 1 bit for overflow and as you go high in vector magnitude, increase it accordingly.  

**precisionbitlen**: This parameter decides the bit-length of the CORDIC scaling factor that's multiplied by the value in `ang` register. It's a very important quantity which decides the accuracy of the output in coherence with `posprec`. This parameter can be tweaked with to improve the efficiency of the output considerably if the error tests fail.

**posprec**: Determines the number of iterations in the positive direction which determines the precision of the output. It's advised and observed mathematically to have n-iterations to have a precision of n-bits. It's advised to increase the `precision` bits as well as you go high because with low precision and a large number of iterations, the last few angles in the look-up table would become zero. Those pipeline stages are effectively wasted because they won't be able to contribute to the angle in 'z' or `angle` registers. After you generate the Verilog code, do look-out for any XX'h0 values in the look-up table.  

**precision**: Determines the precision of the output, lookup table as well as the input.  

**startquant_pow**: Determines the bit position start the input of testing from. If experiencing high error in the lower range of quantities, try increasing this quantity. This can happen due to the fact that there's a large truncation error for the lower quantities because they lose their sense of magnitude in just first few iterations. Adjust this quantity along with the **ansbitlen** to shift the  max error to mid-lower quantities.  
