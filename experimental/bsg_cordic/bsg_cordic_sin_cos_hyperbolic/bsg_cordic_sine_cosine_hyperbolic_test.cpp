#include "Vbsg_cordic_sine_cosine_hyperbolic.h"
#include "verilated.h"
#include <iostream>
#include <math.h>
#include "params_def.h" 

// This header file grants access to all the default or the passed parameters to the 
//module generation script.
// VM_TRACE is asserted when we want to enable tracing and can be found in makefile.
// as -DVM_TRACE.

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

double maxquant = theta_final*pow(2,precision); 

// The maximum quantity is determined by the angle that can be accumulated
// by the negative and positive iterations. Please refer to the table mentioned
// in the readme for the maximum angle accumulated by a particular number of
// iterations.
									  
unsigned long int startquant = pow(2,startquant_pow);

// The starting quantity is a very important parameter of testing. Due to truncation effect
// the sense of magnitude of smaller numbers is lost and results in high error. The starting quantity can be
// 2^(negprec+posprec+1) so that the sense of magnitude is not lost throughout the iterations and 
// this gives very accurate results. The fixed point representation should also be carefully selected.
// There will be very high error in smaller numbers due to the above explained truncation
// error. This can easily be shifted to an error range of 0.1-1% or better by
// using some careful fixed point respresentation and it is highly advised to retain
// at least 8-12 bits for decimal point to get above rated results.

unsigned long int numsamples = (pow(2,anglen-1)-1);

// While testing please be very careful of the number of samples. Sometimes the
// anglen can make the sample_width = 0 which will definitely result in unnecessary
// high errors. If the test fails, the first thing to check is `sample_width`.

unsigned long int sample_width = round((maxquant-startquant)/numsamples);
																			
unsigned long int startquant_print = startquant;	
														
unsigned long int *samples;													

unsigned long int *result_sinh;

unsigned long int *result_cosh;

unsigned long int clkcycles = numsamples+posiprec+negprec+4;

int main(int argc, char **argv, char **env)
{
	Verilated::commandArgs(argc, argv);
	Vbsg_cordic_sine_cosine_hyperbolic* top = new Vbsg_cordic_sine_cosine_hyperbolic;

	#if VM_TRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	#endif

	int samp_len = 0;
	samples = new unsigned long int [clkcycles];
	result_sinh = new unsigned long int [clkcycles];
	result_cosh = new unsigned long int [clkcycles];
	int valid_in = 1;
	int ready_in = 1;

	#if VM_TRACE
	top->trace (tfp, 99);
	tfp->open ("CORDIC_sinh_cosh.vcd");
	#endif

	for(int i=0;i<clkcycles;i++){

		while(main_time<10){

			#if VM_TRACE
			tfp->dump (main_time+i*10);
			#endif

			if((main_time%10)==0){

				if(startquant<maxquant){
				top->ang_i = startquant;
				samples[i] = startquant;
				samp_len++;
				}

				top->val_i = valid_in;
				top->ready_i = ready_in;
				top->clk_i = 1;
				result_sinh[i] = top->sinh_o;
				result_cosh[i] = top->cosh_o;
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

	double aver_squa_err_sinh = 0;
	double aver_squa_err_cosh = 0;

	double aver_err_sinh, aver_err_cosh;

	float maxerr_sinh = 0;
	float maxerr_cosh = 0;

	double max_err_samp_sinh;
	double max_err_samp_cosh;

	for(int i=0;i<samp_len;i++){
		float samp = samples[i]/pow(2,precision);

		double ideal_value_sinh = sinh(samp);
		double ideal_value_cosh = cosh(samp);

		double obser_value_sinh = result_sinh[i+(negprec+posiprec+1+2)]/pow(2,precision);
		double obser_value_cosh = result_cosh[i+(negprec+posiprec+1+2)]/pow(2,precision);

		float err_sinh = (ideal_value_sinh - obser_value_sinh)/ideal_value_sinh;
		float err_cosh = (ideal_value_cosh - obser_value_sinh)/ideal_value_cosh;

		double sinh_err = err_sinh*err_sinh;
		double cosh_err = err_cosh*err_cosh;

		aver_squa_err_sinh+=sinh_err;
		aver_squa_err_cosh+=cosh_err;
		
		if(maxerr_sinh<fabs(err_sinh)){
			maxerr_sinh = err_sinh;
			max_err_samp_sinh = samp;

		}

		if(maxerr_cosh<fabs(err_cosh)){
			maxerr_cosh = err_cosh;
			max_err_samp_cosh = samp;

		}

		}
		aver_squa_err_sinh/=samp_len;
		aver_squa_err_cosh/=samp_len;

		float stan_dev_sinh = sqrt(aver_squa_err_sinh);
		float stan_dev_cosh = sqrt(aver_squa_err_cosh);
		std::cout<<std::endl;
		std::cout<<std::endl;
		std::cout<<"Minimum Vector tested:"<<startquant_print<<std::endl;
		std::cout<<"Maximum Vector tested:"<<maxquant<<std::endl;
		std::cout<<"Sampling Interval:"<<sample_width<<std::endl;
		std::cout<<"Maximum Error in Hyperbolic Sine:"<<maxerr_sinh<<"%"<<std::endl;
		std::cout<<"Standard Deviation observed:"<<stan_dev_sinh<<std::endl;
		std::cout<<"Maximum Error Vector:"<<max_err_samp_sinh<<std::endl;
		std::cout<<"Maximum Error in Hyperbolic Cosine:"<<maxerr_cosh<<"%"<<std::endl;
		std::cout<<"Standard Deviation observed:"<<stan_dev_cosh<<std::endl;
		std::cout<<"Maximum Error Vector:"<<max_err_samp_cosh<<std::endl;

		#if VM_TRACE
		tfp->close();
		#endif

		delete top;
		exit(0);
	}
	
