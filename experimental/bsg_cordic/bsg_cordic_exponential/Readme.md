# bsg_cordic_exponential
This is a Hyperbolic CORDIC based design to compute exponent of a quantity and returns exp(ang_i) . `ang_i` is the input to the module and outputs the answer in `expz_o`. The module uses a fixed-point representation for the input as well as output. The error analysis is the form of relative precentage error and standard deviation of the same. It's advised to use some margin of input at the both extremes of input and output. For example if the maximum input is 15, according to the table given below you might use the parameters for 6 iterations but it's advised to use 7 to not have high error rates at the extremes. The function `theta_max_compute`
computes the theta max slightly lower than the ideal. Maybe it's due to the approximation errors in the computation of atanh.   

The documentation with more details for all the functions can be found at: https://docs.google.com/document/d/1FMqU0_CAKDEv--3Nw7s5GUfzWhasyPWOG0TNULLdxeE/edit

The default rule for `make` is generating verilog module file with default parameters and **params_def.h** which enables access of the parmeters passed to the script for verilator testing. Use `make run` to run the executable and compute the error analysis.
### Module and Script parameters
Generate the verilog module with **bsg_exponential_script.py** script which generates the **params_def.h** as well. The following arguments are passed to the script:    

**angbitlen** : Defines the bit-length of the angular ('z' in CORDIC naming) datapath. Has a precision of `precision`  bits and is input to the module. Choose this carefully to accomodate the angles of the look-up table, maximum input quantity as well as the number of precision bits. The maximum input quantity is determined by the formula in the `bsg_cordic_exponential_test.cpp` test file and is listed below for upto 10 iterations. 

**ansbitlen**: Defines the bit-length of the answer ('x' and 'y' in CORDIC naming) datapath. Also has a precision of 'precision' bits and is output of the module defined by exp(ang_i). A very important consideration while choosing this length is that it should be the maximum of length of either the constant computed in the script by `constant_compute` function or the answer of the next maximum exponent quantity from the table. For example, if the maximum quantity to the input is ang_i = 10 then you need to define this bit-length as the length of exp(12.42644)+1-sign bit+precision number of bits. 


**negprec**: Determines the number of iterations in negative direction. These iterations increase the domain of input that can be converged by the module. These come as a part of the extension to the Hyperbolic CORDIC proposed by X.Hu in **"Expanding the range of convergence of the CORDIC algorithm"** in 1991. Choose the number of iterations as determined by the maximum input quantity to the module by the table listed below. 

**posprec**: Determines the number of iterations in positive direction which determines the precision of the output. It's advised and observed mathematically to have n-iterations to have a precision of n-bits.  

**precision**: Determines the precision of the output, lookup table as well as the input.  

 **startquant_pow**: Determines the bit position to start the input of testing from. If experiencing high error in the lower range of quantities, try increasing this quantity. This can happen due to the fact that there's a large truncation error for the lower quantities because they lose their sense of magnitude in just first few iterations. Adjust this quantity along with the **ansbitlen** to shift the  max error to mid-lower quantities.     


| M      |Max Input Angle  | M     | Max Input Angle    | M|Max Input Angle|
| :---:       |    :----:   |:---: |:---:  | :---:|:---:|
| 0      | 2.09113       | 5   |12.42644 |10|31.48609
| 1   | 3.44515        | 6      |15.54462|
| 2   | 5.16215        |7     |19.00987|
| 3   | 7.23371        | 8     |22.82194|
| 4   | 9.65581        | 9      |26.98070|

### bsg_exponential_help.py  
This script helps in determining the bit-lengths for both input (angbitlen) and output(ansbitlen). It takes in the maximum number (maxquant) that needs to be computed in the form:  
exp(quant_i_max) = maxquant  
In this way it determines the range of quantities corresponding to a particular 'M' in which the number lies and chooses the 'negprec','angbitlen' and 'ansbitlen'. **'negprec'** is found by finding the interval in which the input number lies, **'angbitlen'** by adding 1 sign-bit + bit-length of [ theta_max ] + 'precision' bits.  
**'ansbitlen'** is found by adding 1 sign-bit + bit-length of [ exp(theta_max) ] + 'precision' bits.  
An important observation in this algorithm is that we consider bit-lengths for a range, not for a single input number. For example, if I have a number X and it falls between the range Y and Z and needs a 'negprec' = 6 for it converge. The bit-length dictated by the 
higher limit of the range (Z) and the constant, not the max input number that you enter in the script. That number is just used to find the range in which it lies and then determine the stages and bit-length according to the range limits. 
