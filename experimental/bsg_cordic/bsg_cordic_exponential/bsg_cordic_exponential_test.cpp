#include "Vbsg_cordic_exponential.h"
#include "verilated.h"
#include <iostream>
#include <math.h>
#include "params_def.h" // This header file grants access to all the default  
						//or the passed parameters to the module generation script.
#if VM_TRACE			// VM_TRACE is asserted by verilator when we want to enable
#include <verilated_vcd_c.h> // tracing and can be found in makefile as --trace.
#endif

vluint64_t main_time = 0;
double sc_time_stamp(){
	return main_time;
}

double theta_max_compute(int negprec, int posiprec)// This function computes the maximum 
{										// theta(angle) that can be computed by the
	double theta =atanh(pow(2,-posiprec));	// negprec+posprec number of hyperbolic 
									// iterations. In this case it determines the maximum
	for(int i=-negprec;i<=posiprec;i++)	// exponential power (exp(max_angle)).		
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

unsigned long int startquant = pow(2,startquant_pow);

unsigned long int numsamples = (pow(2,anglen-1)-1);
									 
unsigned long int sample_width = round((maxquant-startquant)/numsamples);  
																			
unsigned long int *samples;													

unsigned long int *result_expon;

unsigned long int clkcycles = numsamples+posiprec+negprec+4;

int main(int argc, char **argv, char **env)
{
	Verilated::commandArgs(argc, argv);
	Vbsg_cordic_exponential* top = new Vbsg_cordic_exponential;

	#if VM_TRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	#endif

	int samp_len = 0;
	samples = new unsigned long int [clkcycles];
	result_expon = new unsigned long int [clkcycles];
	int valid_in = 1;
	int ready_in = 1;

	#if VM_TRACE
	top->trace (tfp, 99);
	tfp->open ("CORDIC_exponential.vcd");
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
				result_expon[i] = top->expz_o;
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

	double aver_squa_err_expon = 0;

	double aver_err_expon;

	float maxerr_expon = 0;

	double max_err_samp_expon;

	for(int i=0;i<samp_len;i++){

		float samp = samples[i]/pow(2,precision);

		double ideal_value_expon = exp(samp);

		double obser_value_expon = result_expon[i+(negprec+posiprec+1+2)]/pow(2,precision);

		float err_expon = (ideal_value_expon - obser_value_expon)/ideal_value_expon;

		double expon_err = err_expon*err_expon;

		aver_squa_err_expon+=expon_err;
		
		if(maxerr_expon<fabs(err_expon)){
			maxerr_expon = err_expon;
			max_err_samp_expon = samp;

		}

		}

		aver_squa_err_expon/=samp_len;

		float stan_dev_expon = sqrt(aver_squa_err_expon);
		std::cout<<std::endl;
		std::cout<<std::endl;
		std::cout<<"Minimum Vector tested:"<<pow(2,startquant_pow)<<std::endl;
		std::cout<<"Maximum Vector tested:"<<maxquant<<std::endl;
		std::cout<<"Sampling Interval:"<<sample_width<<std::endl;
		std::cout<<"Maximum Error in Exponential function:"<<maxerr_expon*100<<"%   "<<std::endl;
		std::cout<<"Standard Deviation observed:"<<stan_dev_expon<<std::endl;
		std::cout<<"Maximum Error Vector with fixed point reprsentation:"<<max_err_samp_expon<<std::endl;

		#if VM_TRACE
		tfp->close();
		#endif

		delete top;
		exit(0);
	}
	


