#include "Vbsg_cordic_sine_cosine.h"
#include "verilated.h"
#include <iostream>
#include <math.h>
#include "params_def.h"

// ^^ This header file grants access to all the default or the passed parameters to  
// the module generation script.
// VM_TRACE is asserted when we want to enable tracing and can be found in makefile
// as --trace.

#if VM_TRACE			
#include <verilated_vcd_c.h> 
#endif

#define PI 3.141592653589793238463

vluint64_t main_time = 0;
double sc_time_stamp(){
	return main_time;
}

double error_bound_2_norm_Z(int precis_p, int precision, int anslen)
// ^^ This function calculates the maximum error bound for
// Z-Reduction. For detailed exlanation, please refer to 'Kota and
//Cavallaro: CORDIC Arithmetic for special-purpose processors; Pg:771,772'
{																	 
	float quantiz_err_max = pow(2,-(precis_p-1));
	float trunc_err_max = precis_p*pow(2,-precision);
	float approx_err = 1.5*precis_p*pow(2,-(anslen-1)); //Approximation error due
	// to the finite number of iterations.
	float max_bound_err = quantiz_err_max+trunc_err_max+approx_err;
 	return max_bound_err;
}


long double maxquant = 89.95*pow(2,precision);
 // It's highly recommended to limit the input to the module 
 // to around 89.9 or a quantity very near to 90 to avoid 
 // the possibility of overflow. A very general observation is that the 
 // more bits you have in your answer datapath the nearer the module can
// get near 90 degrees. The design has a domain of [-PI , PI] but we only
// test one quadrant at a time. This is due to the fact that the design can't 
// converge for values near to the quadrant bounday. That's why for 1st 
// quadrant we start from around ~0.05 and end at ~89.95 degrees. For a successful
// test, each quadrant should be given this much difference. To test for different 
// quadrants change the maxquant and startquant accordingly keeping the above 
// mentioned difference in mind. maxquant can take values like 89.95, 179.95,
// -89.95 and -179.95.   
  
long double startquant = pow(2,startquant_pow);// 
// startquant needs to be chnaged accordingly as the quadrant changes. The values 
// it can take (in order of the maxquant values given above) 0.05, 90.05, -0.05
// and -90.05. While testing negative quadrants it's very important to change the 
// comparison sign to '>' at line #104. 

long double numsamples = (pow(2,anglen-2)-1);

long double sample_width = round((maxquant-startquant)/numsamples);
//While testing it's highly probable that the test can fail because the 
// sample_width is 0. If that's the case try changing the power in
// numsamples to make the sampling width to at least 1. 
																			

long double startquant_print = startquant; 
																
long double *samples;													

long int *result_sine;

long int *result_cosine;

unsigned long int clkcycles = numsamples+precis_p+6;

int main(int argc, char **argv, char **env)
{
	Verilated::commandArgs(argc, argv);
	Vbsg_cordic_sine_cosine* top = new Vbsg_cordic_sine_cosine;

	#if VM_TRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	#endif

	int samp_len = 0;
	samples = new long double [clkcycles];
	result_sine = new long int [clkcycles];
	result_cosine = new long int [clkcycles];
	int valid_in = 1;
	int ready_in = 1;


	#if VM_TRACE
	top->trace (tfp, 99);
	tfp->open ("CORDIC_sine_cosine.vcd");
	#endif


	for(int i=0;i<clkcycles;i++){

		while(main_time<10){

			#if VM_TRACE
			tfp->dump (main_time+i*10);
			#endif

			if((main_time%10)==0){

				if(startquant<maxquant){
				// Change the comparison sign to '>' while testing for 
				// negative quadrants.
				top->ang_i = startquant;
				top->val_i = valid_in;
				top->ready_i = ready_in;
				samples[i] = startquant;
				samp_len++;
					
				}
				top->clk_i = 1;
				result_sine[i] = top->sin_o;
				result_cosine[i] = top->cos_o;
				startquant+=sample_width;
				int val_i = top->val_i;
				int val_o = top->val_o;
				int ready_i = top->ready_i;
				int ready_o = top->ready_o;
				}			
			
			if((main_time%10)==6){
				top->clk_i = 0;
			}

			top->eval();
			
			main_time++;
			
		}

		main_time = 0;
	}	

	double aver_squa_err_cos = 0;
	double aver_squa_err_sin = 0;

	float maxerr_cos = 0;
	float maxerr_sin = 0;

	double max_err_samp_cos;
	double max_err_samp_sin;

	bool test_fail;

	for(int i=0;i<samp_len;i++){
		float samp = (samples[i]/pow(2,precision))*PI/180;

		long int signed_result_sin = result_sine[i+(precis_p+1+1+1)];
		long int signed_result_cos = result_cosine[i+(precis_p+1+1+1)];

		if (signed_result_sin & signedconst)
    		signed_result_sin |= ~signedconst2;

    	if (signed_result_cos & signedconst)
    		signed_result_cos |= ~signedconst2;


		double ideal_value_sin = sin(samp);
		double ideal_value_cos = cos(samp);


		double obser_value_cos = (signed_result_cos/pow(2,anslen-1));
		double obser_value_sin = (signed_result_sin/pow(2,anslen-1));

		float err_cos = (ideal_value_cos - obser_value_cos);
		float err_sin = (ideal_value_sin - obser_value_sin);

		double cos_err_squa = err_cos*err_cos;
		double sin_err_squa = err_sin*err_sin;

		aver_squa_err_cos+=cos_err_squa;
		aver_squa_err_sin+=sin_err_squa;

		if(maxerr_cos<fabs(err_cos)){
			maxerr_cos = err_cos;
			max_err_samp_cos = samp;
		}
		if(maxerr_sin<fabs(err_sin)){
			maxerr_sin = err_sin;
			max_err_samp_sin = samp;
		}

		}
	aver_squa_err_cos/=samp_len;
	aver_squa_err_sin/=samp_len;

	float stan_dev_cos = sqrt(aver_squa_err_cos);
	float stan_dev_sin = sqrt(aver_squa_err_sin);

	float error_expec_cos_sin = error_bound_2_norm_Z(precis_p,precision,anslen);

	std::cout.precision(10);
	std::cout<<std::endl;
	std::cout<<std::endl;
	std::cout<<"Minimum Vector tested:"<<startquant_print<<std::endl;
	std::cout<<"Maximum Vector tested:"<<maxquant<<std::endl;
	std::cout<<"Sampling Interval:"<<sample_width<<std::endl;
	std::cout<<"Maximum Error in Cosine:"<<maxerr_cos<<std::endl;
	std::cout<<"Maximum Error in Sine:"<<maxerr_sin<<std::endl;
	std::cout<<"Standard Deviation observed in Cosine:"<<stan_dev_cos<<std::endl;
	std::cout<<"Standard Deviation observed in Sine:"<<stan_dev_sin<<std::endl;
	std::cout<<"Maximum Error Vector (angle with fixed point representation) for Cosine:";
	std::cout<<max_err_samp_cos*180/PI<<std::endl;
	std::cout<<"Maximum Error Vector (angle with fixed point representation) for Sine:";
	std::cout<<max_err_samp_sin*180/PI<<std::endl;
	std::cout<<"Maximum error bound on Z-Reduction to find Sine and Cosine of the input angle: ";
	std::cout<<error_expec_cos_sin<<std::endl;

	if(fabs(maxerr_cos)>error_expec_cos_sin){
		test_fail = true;
		std::cout<<"TEST FAILED for Cosine!"<<std::endl;
		std::cout<<"Maximum error is out of bounds by "<<maxerr_cos - error_expec_cos_sin<<std::endl;
	}
	else{
		test_fail = false;
		std::cout<<"TEST PASSED for Cosine!"<<std::endl;
	}
	if(fabs(maxerr_sin)>error_expec_cos_sin){
		test_fail = true;
		std::cout<<"TEST FAILED for Sine!"<<std::endl;
		std::cout<<"Maximum error is out of bounds by "<<maxerr_sin - error_expec_cos_sin<<std::endl;
	}

	else{
		test_fail = false;
		std::cout<<"TEST PASSED for Sine!"<<std::endl;
	}
	

	#if VM_TRACE
	tfp->close();
	#endif

	delete top;
	exit(0);
	}
	


