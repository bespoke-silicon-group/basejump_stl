#include "Vbsg_cordic_squaroot_natlog.h"
#include "verilated.h"
#include <iostream>
#include <math.h>
#include "params_def.h"
// This header file grants access to all the default or the passed parameters to the 
//module generation script. VM_TRACE is asserted when we want to enable tracing
//  and can be found in makefile as -DVM_TRACE.

#if VM_TRACE			
#include <verilated_vcd_c.h> 
#endif

vluint64_t main_time = 0;
double sc_time_stamp(){
	return main_time;
}

double theta_max_compute(int negprec, int posiprec)
// This function computes the maximum theta(angle) that can be
// computed by the negprec+posprec number of hyperbolic iterations. In this
// particular module this theta translates to the half of the maximum
// attainable natural logarithm value. Has the tendency to underestimate the final value
// by ~ 0.5-0.2%. Can directly copy the value corresponding to 'm' from the table in
// readme.
{												   
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

double maxquant = exp(2*theta_final)*pow(2,precision) > (pow(2,anslen-2) -1)  ? pow(2,anslen-2)-1: exp(2*theta_final)*pow(2,precision);
// The maximum quantity is determined by the angle that can be accumulated in the 
// ang register  by the negative and positive iterations. We need to be careful 
// about the max quantity that cab be accomodated by 'anslen' bits.

unsigned long int startquant = pow(2,startquant_pow);
// The starting quantity is a very important parameter of testing. Due to truncation effect
// the sense of magnitude of smaller numbers is lost and results in high error. 
//The fixed point representation should also be carefully selected. There will be
// very high error in smaller numbers due to the above explained truncation																  
// error. This can easily be shifted to an error range of 0.1-1% or better by	
// using some careful fixed point respresentation and it is highly advised to retain
// at least 8-12 bits for decimal point to get above rated results.

unsigned long int numsamples = (pow(2,anglen)-1);
									 
unsigned long int sample_width = round((maxquant-startquant)/numsamples);
																			
unsigned long int *samples;													

unsigned long int *result_squaroot;

unsigned long int *result_natlog;

unsigned long int clkcycles = numsamples+posiprec+negprec+4;

int main(int argc, char **argv, char **env)
{
	Verilated::commandArgs(argc, argv);
	Vbsg_cordic_squaroot_natlog* top = new Vbsg_cordic_squaroot_natlog;

	#if VM_TRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	#endif

	int samp_len = 0;
	samples = new unsigned long int [clkcycles];
	result_squaroot = new unsigned long int [clkcycles];
	result_natlog = new unsigned long int [clkcycles];
	int valid_in = 1;
	int ready_in = 1;

	#if VM_TRACE
	top->trace (tfp, 99);
	tfp->open ("CORDIC_squa_natlog.vcd");
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
				int val_i = top->val_i;
				int val_o = top->val_o;
				int ready_i = top->ready_i;
				int ready_o = top->ready_o;
				}

				top->clk_i = 1;
				result_squaroot[i] = top->squaroot_o;
				result_natlog[i] = top->natlog_o;
				startquant+=sample_width;
				}			
			
			if((main_time%10)==6){
				top->clk_i = 0;
			}

			top->eval();
			
			main_time++;
			
		}

		main_time = 0;
	}	

	double aver_squa_err_ans = 0;
	double aver_squa_err_ang = 0;

	double aver_err_ans, aver_err_ang;

	float maxerr_sq = 0;
	float maxerr_nl = 0;

	double max_err_samp_sq;
	double max_err_samp_nl;

	std::cout.precision(10);
	for(int i=0;i<samp_len;i++){
		float samp = samples[i]/pow(2,precision);

		long int signed_result_natlog = result_natlog[i+(negprec+posiprec+1+2)];
		if (signed_result_natlog & signedconst)
    		signed_result_natlog |= ~signedconst2;

    	// The above construct helps to convert the unsigned magnitude representation
    	// to signed and works for arbitrary bit-length. If experiencing high error
    	// rate, please look into this as well and check the values obtained for 
    	// quantities lower than 1 (or 1*pow(2,precision) in absolute magnitude).
		double ideal_value_sq = sqrt(samp);
		double ideal_value_nl = log(samp);

		double obser_value_sq = result_squaroot[i+(negprec+posiprec+1+2)]/pow(2,precision);
		double obser_value_nl = signed_result_natlog/pow(2,precision);

		float err_sq = (ideal_value_sq - obser_value_sq)/ideal_value_sq;
		float err_nl = (ideal_value_nl - obser_value_nl)/ideal_value_nl;

		double squa_err = err_sq*err_sq;
		double natl_err = err_nl*err_nl;

		aver_squa_err_ans+=squa_err;
		aver_squa_err_ang+=natl_err;

		
		if(maxerr_sq<fabs(err_sq)){
			maxerr_sq = err_sq;
			max_err_samp_sq = samp;

		}

		if(maxerr_nl<fabs(err_nl)){
			maxerr_nl = err_nl;
			max_err_samp_nl = samp;

		}

		}
		aver_squa_err_ans/=samp_len;
		aver_squa_err_ang/=samp_len;

		float stan_dev_ans = sqrt(aver_squa_err_ans);
		float stan_dev_ang = sqrt(aver_squa_err_ang);

		std::cout<<std::endl;
		std::cout<<std::endl;
		std::cout.precision(10);
		std::cout<<"Minimum Vector tested:"<<pow(2,startquant_pow)<<std::endl;
		std::cout<<"Maximum Vector tested:"<<maxquant<<std::endl;
		std::cout<<"Sampling Interval:"<<sample_width<<std::endl;
		std::cout<<"Maximum Error in Natural Logarithm:"<<maxerr_nl*100<<"%"<<std::endl;
		std::cout<<"Standard Deviation observed:"<<stan_dev_ang<<std::endl;
		std::cout<<"Maximum Error Vector:"<<max_err_samp_nl<<std::endl;
		std::cout<<"Maximum Error in Square Root:"<<maxerr_sq*100<<"%"<<std::endl;
		std::cout<<"Standard Deviation observed:"<<stan_dev_ans<<std::endl;
		std::cout<<"Maximum Error Vector:"<<max_err_samp_sq<<std::endl;

		#if VM_TRACE
		tfp->close();
		#endif

		delete top;
		exit(0);
	}
	
