# bsg_cordic_atan
This is a CORDIC based design to compute the tangent inverse of a quantity and returns atan(quant_i) . `quant_i` is the input to the module and outputs the tangent inverse in `tan_inv_o`. The module accepts both positive and negative fixed-point quantities and outputs answer i.e. atan in the range ( -90,90 ). The default rule for `make` is generating verilog module file with default parameters and **params_def.h** which enables access of the parmeters passed to the script for verilator testing. 

The documentation with more details for all the functions can be found at: https://docs.google.com/document/d/1FMqU0_CAKDEv--3Nw7s5GUfzWhasyPWOG0TNULLdxeE/edit

### Input and Output Representation
All the quantities are treated and represented as fixed-point signed numbers. If the `angbitlen` is 20 and `precision` is 12 bits, then answer is represented as 0xAA.BBB and if ansbitlen is 40, then `quant_i` is represented as 0xQQQQQQQ.YYY.This includes 1 overflow-bit as well. Note: The simulation just runs for the positive quantities because atan is an odd function, so the errors will be same for both positive and negative quantities but the module has the range (-90,90).  


### Module and Script parameters
Generate the verilog module with **bsg_atan_script.py** script which generates the **params_def.h** as well. The following arguments are passed to the script:  

**angbitlen** : Defines the bit-length of the angular ('z' in CORDIC naming) datapath. Has a precision of `precision`  bits. This 'z'-register values represent the output of the tangent inverse. The output is in **degrees**. 
Choose this carefully to accomodate the angles of the look-up table, maximum input quantity as well as the number of precision bits. Determining this bit-length is pretty straightforward.  
`angbitlen` = 1 sign-bit + bit-length of [90] + `precision` bits. The number of precision bits in this case is **very important** due to the highly non-linear nature of this function. Choose this precision bits by first determining the decimal precision upto which you'd like the atan answer. For example if it's 0.000001, then the minimum bits needed to represent this precision is: -log2(0.000001) where log2 represents log to the base-2. (round off the quantity obtained to the next big integer).  

**ansbitlen**: Defines the bit-length of the answer ('x' and 'y' in CORDIC naming) datapath. Also has a precision of 'precision' bits and is input (quant_i) to the module. Determine this length by: 1 sign-bit + **1 overflow-bit** + bit-length of [ max_number_of_which_atan_calculated ] + `precision` bits. It's recommended to use atleast 1 bit for overflow and as you go high in vector magnitude, increase it accordingly.  

**posprec**: Determines the number of iterations in positive direction which determines the precision of the output. It's advised and observed mathematically to have n-iterations to have a precision of n-bits. It's advised to increase the `precision` bits as well as you go high because with low precision and large number of iterations, the last few angles in the look-up table would become zero. Those pipeline stages are effectively wasted because they won't be able to contribute to the angle in 'z' or `angle` registers. After you generate the verilog code, do look-out for any XX'h0 values in the look-up table.  

**precision**: Determines the precision of the output, lookup table as well as the input.  

**startquant_pow**: Determines the bit position to start the input of testing from. If experiencing high error in the lower range of quantities, try increasing this quantity. This can happen due to the fact that there's a large truncation error for the lower quantities because they lose their sense of magnitude in just first few iterations. Adjust this quantity along with the **ansbitlen** to shift the  max error to mid-lower quantities.  


