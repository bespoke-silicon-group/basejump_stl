# bsg_cordic_sin_cos_hyperbolic
This is a CORDIC based design to compute the sine hyperbolic and cosine hyperbolic of a quantity and returns sinh(ang_i) and cosh(ang_i). `ang_i` is the input to the module and outputs the sinh in `sinh_o` and cosh in `cosh_o`. The module has an input domain of [ 0, theta_max ] and outputs a signed value. The quantity `theta_max` is dictated by the table given below where 'M' is the number of iterations in negative direction (negprec). The table simply states the minimum number of iterations needed to compute a maximum of sinh or cosh of 'theta_max'. With more number of iterations in negative direction, the constant needed for computation inside the module increases and so does the bit-length needed to represent the constant. It's also recommended not to compute the quantities very close of 'theta_max'. If possible and enough resources are available, try choosing an 'M' which is 1 greater than the maximum needed. For example, if a max input angle of 9.63 is needed try choosing 'M' as 5 rather than 4, just to be safe. But in the cases of higer 'M', it's not always recommended to go for one iteration higher because the bit-length of the internal constant increases significantly and too many extra resources may be used to be in the 'safe' zone. In short, try not to compute a quantity very very near to the 'theta_max'. The function `theta_max_compute` in the test file computes the theta max slightly lower than the ideal. Maybe it's due to the approximation errors in the computation of atanh. 
The default rule for `make` is generating verilog module file with default parameters and **params_def.h** which enables access of the parmeters passed to the script for verilator testing.

The documentation with more details for all the functions can be found at: https://docs.google.com/document/d/1FMqU0_CAKDEv--3Nw7s5GUfzWhasyPWOG0TNULLdxeE/edit

### Input and Output Representation
All the quantities are treated and represented as fixed-point signed. If the `angbitlen` is 20 and `precision` is 12 bits, then answer is represented as 0xAA.BBB and if ansbitlen is 40, then `quant_i` is represented as 0xQQQQQQQ.YYY. This includes 1 overflow-bit if included.





### Module and Script parameters
Generate the verilog module with **bsg_sine_cosine_hyperbolic_script.py** script which generates the **params_def.h** as well. The following arguments are passed to the script:  

**angbitlen** : Defines the bit-length of the angular ('z' in CORDIC naming) datapath. Has a precision of `precision`  bits and is input to the module. Choose this carefully to accomodate the angles of the look-up table, maximum input quantity as well as the number of precision bits. Determining this bit-length is pretty straightforward. `angbitlen` = 1 sign-bit + bit-length of [theta_max] + `precision` bits. It's highly recommended to use 1-bit for overflow as well.  

**ansbitlen**: Defines the bit-length of the answer ('x' and 'y' in CORDIC naming) datapath. It also has a precision of `precision bits`. It's important to consider the bit-length of the internal constant while determining this length. If `ansbitlen` is determined using the 'theta_max' then the bit-length of internal constant doesn't need to be considered because it will always be less than the maximum quantity to the corresponding theta_max. For example, if the 'M' needed is 6, then `ansbitlen` will be 1-sign + 1-overflow bit + bit-length of [ sinh(15.54462) ] + `precision` bits. The rest of the fine details are commented in the code at relevant places.  

**negprec**: Determines the number of iterations in negative direction. These iterations increase the domain of input that can be converged by the module. These come as a part of the extension to the Hyperbolic CORDIC proposed by X.Hu in "Expanding the range of convergence of the CORDIC algorithm" in 1991. Choose the number of iterations as determined by the maximum input quantity to the module by the table listed below. 


**posprec**: Determines the number of iterations in positive direction which determines the precision of the output. It's advised to increase the `precision` bits as well as you go high because with low precision and large number of iterations, the last few angles in the look-up table would become zero. Those pipeline stages are effectively wasted because they won't be able to contribute to the angle in 'z' or `angle` registers. After you generate the verilog code, do look-out for any XX'h0 values in the look-up table.  

**precision**: Determines the precision of the input angle ( ang_i ) as well as the values of the angle look-up table.  

**startquant_pow**: Determines the bit position to start the input of testing from. If experiencing high error in the lower range of quantities, try increasing this quantity. This can happen due to the fact that there's a large truncation error for the lower quantities because they lose their sense of magnitude in just first few iterations. Adjust this quantity along with the **ansbitlen** to shift the  max error to mid-lower quantities.  

- 

| M      |Max Input Angle  | M     | Max Input Angle    | M|Max Input Angle|
| :---:       |    :----:   |:---: |:---:  | :---:|:---:|
| 0      | 2.09113       | 5   |12.42644 |10|31.48609
| 1   | 3.44515        | 6      |15.54462|
| 2   | 5.16215        |7     |19.00987|
| 3   | 7.23371        | 8     |22.82194|
| 4   | 9.65581        | 9      |26.98070|
