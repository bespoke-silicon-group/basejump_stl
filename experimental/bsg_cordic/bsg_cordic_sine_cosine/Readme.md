# bsg_cordic_sin_cos  

This is a CORDIC based design to compute the sine and cosine of a quantity and returns sin(ang_i) and cos(ang_i). `ang_i` is the input to the module and outputs the sine in `sin_o` and cosine in `cos_o`. The module has an input domain of [ -PI, PI ] and outputs a signed value.
The default rule for `make` is generating verilog module file with default parameters and **params_def.h** which enables access of the parmeters passed to the script for verilator testing. By default, the module is tested only for values lying in the first quadrant. This is done
so because the module, in its computation design converges for [ 0,PI/2 ] and quadrant shifting is used to get all the input values in the first quadrant and the signs are adjusted for. To test for values in the other three quadarnts, change the values of `maxquant` and 
`startquant`. Please make sure that a margin of around 0.05 degrees or less (depending upon the `angbitlen`) is given for each quadrant boundary. Please refer to comments around line #38, #52 and #107 for a detailed explanation on what to change for testing values lying in the 
other quadrants. Since, sine and cosine are even or odd symmetric with reference to the different quadrants, the absolute error would be the same for each of them. 


There are different variants of CORDIC that inherently converge for [ -PI, PI ] but this approach may also have a very similar resource utilisation. The 2-bits dictating the sign of each sine and cosine that are propagating in the pipeline are very similar to the extra bits
needed to represent a bit-length of [ 360 ].

The documentation with more details for all the functions can be found at: https://docs.google.com/document/d/1FMqU0_CAKDEv--3Nw7s5GUfzWhasyPWOG0TNULLdxeE/edit

### Input and Output Representation
All the quantities are treated and represented as fixed-point signed. If the `angbitlen` is 20 and `precision` is 12 bits, then answer is represented as 0xAA.BBB and if ansbitlen is 32, then one bit is reserved for sign and one for the right point of the decimal and the equivalent `quant_i` is represented as 32'bXX.YYYYYYYY... because the input domain to the function sin(x) and cos(x) is [ -1,1 ] .  

### Module and Script parameters
Generate the verilog module with **bsg_sine_cosine_script.py** script which generates the **params_def.h** as well. The following arguments are passed to the script:

**angbitlen** : Defines the bit-length of the angular ('z' in CORDIC naming) datapath. Has a precision of `precision`  bits and is input to the module. The output is in  **degrees**. Choose this carefully to accomodate the angles of the look-up table, maximum input quantity as
well as the number of precision bits. Determining this bit-length is pretty straightforward. `angbitlen` = 1 sign-bit + bit-length of [ 180 ] ( 8-bits, 180 = 0xB4 ) + `precision` bits. It's highly recommended to limit the input to the module to around 89.9 or a quantity very near to 
90 to avoid the possibility of overflow. A very general observation is that the more bits you have in your answer datapath the nearer the module can get near 90 degrees. It's tested for a margin of ~0.05 degrees of margin on each boundary of every quadrant. For example, the 1st
quadrant limits with which the module works with a maximum absolute error of 7.2e-05 are [0.05,89.95] degrees.

**ansbitlen**: Defines the bit-length of the answer ('x' and 'y' in CORDIC naming) datapath. Since the range of sine and cosine is [ 1,1 ], the 'answer' datapath has a precision of 'ansbitlen-1' .This bit-length can be of any desired length and can be decided upon by the maximum error that an application can tolerate.  

**posprec**: Determines the number of iterations in positive direction which determines the precision of the output. It's advised to increase the `precision` bits as well as you go high because with low precision and large number of iterations, the last few angles in the look-up
table would become zero. Those pipeline stages are effectively wasted because they won't be able to contribute to the angle in 'z' or `angle` registers. After you generate the verilog code, do look-out for any XX'h0 values in the look-up table.  

**precision**: Determines the precision of the input angle ( ang_i ) as well as the values of the angle look-up table.  


**startquant_pow**: Determines the bit position to start the input of testing from. In this module, this starting quantity power is only valid for 1st quadrant. By default all the values are checked in the first quadrant only. If experiencing high error in the lower range of
quantities, try increasing this quantity. This can happen due to the fact that there's a large truncation error for the lower quantities because they lose their sense of magnitude in just first few iterations. Adjust this quantity along with the **ansbitlen** to shift the  max error to mid-lower quantities. 
