#include "Vbsg_cordic_tan_hyperbolic_inverse.h"
#include "verilated.h"
#include <iostream>
#include <math.h>
#include "params_def.h"

// This header file grants access to all the default or the passed parameters to the 
//module generation script.
// VM_TRACE is asserted when we want to enable tracing and can be found in makefile
// as TRACE.

#if VM_TRACE			
#include <verilated_vcd_c.h> 
#endif

vluint64_t main_time = 0;
double sc_time_stamp(){
	return main_time;
}

double theta_max_compute(int negprec, int posiprec)
{
// This function computes the maximum theta(angle) that can be
// computed by the negprec+posprec number of hyperbolic iterations. In this
// particular module this theta translates to the half of the maximum
// attainable natural logarithm value.

	double theta =atanh(pow(2,-posiprec));		   
												   
	for(int i=-negprec;i<=posiprec;i++)				
	{
		if(i<=0)
			theta+=atanh(1-pow(2,i-2));
		else
			theta+=atanh(pow(2,-i));
	}
	return theta;
}

double theta_final = theta_max_compute(negprec, posiprec);

double maxquant = pow(2,anslen-2)-1-pow(2,anslen-13);

// The maximum quantity is determined by the angle that can be accumulated
// by the negative and positive iterations. In this case, since the domain of
// the function atanh(x) is [0,1) 1-bit is reserved for sign, 1 for single digit
// to the right left of the decimal point and the rest for the fractional quantity.
// The effective input quantity would be input/pow(2,anslen-2).

unsigned long int startquant = pow(2,startquant_pow);

// The starting quantity is a very important parameter of testing. Due to truncation effect
// the sense of magnitude of smaller numbers is lost and results in high error. The starting quantity can be
// 2^(negprec+posprec+1) so that the sense of magnitude is not lost throughout the iterations and 
// this gives very accurate results. The fixed point representation should also be carefully selected. There will be
// very high error in smaller numbers due to the above explained truncation
// error. This can easily be shifted to an error range of 0.1-1% or better by
// using some careful fixed point respresentation and it is highly advised to retain
// at least 8-12 bits for decimal point to get above rated results.

unsigned long int numsamples = (pow(2,anglen-1)-1);
									 
unsigned long int sample_width = round((maxquant-startquant)/numsamples);
																			
																			
unsigned long int *samples;													
unsigned long int *result_atanh;

unsigned long int clkcycles = numsamples+posiprec+negprec+4;

int main(int argc, char **argv, char **env)
{
	Verilated::commandArgs(argc, argv);
	Vbsg_cordic_tan_hyperbolic_inverse* top = new Vbsg_cordic_tan_hyperbolic_inverse;

	#if VM_TRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	#endif

	int samp_len = 0;
	samples = new unsigned long int [clkcycles];
	result_atanh = new unsigned long int [clkcycles];
	int valid_in = 1;
	int ready_in = 1;

	#if VM_TRACE
	top->trace (tfp, 99);
	tfp->open ("CORDIC_atanh.vcd");
	#endif

	for(int i=0;i<clkcycles;i++){

		while(main_time<10){

			#if VM_TRACE
			tfp->dump (main_time+i*10);
			#endif

			if((main_time%10)==0){

				if(startquant<maxquant){
				top->quant_i = startquant;
				top->val_i = valid_in;
				top->ready_i = ready_in;
				samples[i] = startquant;
				samp_len++;
				}

				top->clk_i = 1;
				result_atanh[i] = top->atanh_o;
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

	double aver_squa_err_atanh = 0;

	double aver_err_atanh;

	float maxerr_atanh = 0;

	double max_err_samp_atanh;

	for(int i=0;i<samp_len;i++){
		float samp = samples[i]/pow(2,anslen-2);

		double ideal_value_atanh = atanh(samp);

		double obser_value_atanh = result_atanh[i+(negprec+posiprec+1+2)]/pow(2,precision);

		float err_atanh = (ideal_value_atanh - obser_value_atanh)/ideal_value_atanh;

		double atanh_err = err_atanh*err_atanh;

		aver_squa_err_atanh+=atanh_err;

		if(maxerr_atanh<fabs(err_atanh)){
			maxerr_atanh = err_atanh;
			max_err_samp_atanh = samp;

		}

		}

		aver_squa_err_atanh/=samp_len;

		float stan_dev_atanh = sqrt(aver_squa_err_atanh);

		std::cout<<std::endl;
		std::cout<<std::endl;
		std::cout<<"Minimum Vector tested:"<<pow(2,startquant_pow)<<std::endl;
		std::cout<<"Maximum Vector tested:"<<maxquant<<std::endl;
		std::cout<<"Sampling Interval:"<<sample_width<<std::endl;
		std::cout<<"Maximum Error in Hyperbolic Tangent Inverse:"<<maxerr_atanh<<"%"<<std::endl;
		std::cout<<"Standard Deviation observed:"<<stan_dev_atanh<<std::endl;
		std::cout<<"Maximum Error Vector:"<<max_err_samp_atanh<<std::endl;

		#if VM_TRACE
		tfp->close();
		#endif

		delete top;
		exit(0);
	}
	