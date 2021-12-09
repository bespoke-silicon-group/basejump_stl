#include "Vbsg_cordic_atan.h"
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

double error_bound_2_norm(int precis_p, int precision)
// ^^ This function calculates the maximum error bound for
// Y-Reduction. For detailed exlanation, please refer to 'Kota and
//Cavallaro: CORDIC Arithmetic for special-purpose processors; Pg:773'
{																	 
	float approx_bound_mod_y_n = 1.5*pow(2,-precision)*precis_p;
	float K_n = 1.0;
	float x,z;
	for(int i=0;i<20;i++)
    {
 		z=pow(2,i);
        x=cos(atan2(1.00,z));
        K_n=K_n*x;
 	}
 	float max_bound_err = asin(approx_bound_mod_y_n/K_n) + precis_p*pow(2,-precision);
 	return max_bound_err;
}

double maxquant = pow(2,anslen-2)-1;
 // The maximum quantity after a lot of testing is recommended
 // to be 2^(anslen-2)-1 and not 2^(anslen-1) to save us from
 // overflow. It's equivalent to saying that we have one extra bit
 // for overflow. For detailed exlanation, please refer to 'Kota and
//Cavallaro: CORDIC Arithmetic for special-purpose processors; Pg:773,774'
 

// In this simulation we're running only with positive input values because
// atan is an odd function so the error will be exactly same for negative values.
// All the bit-lengths and quantities are given to the module 
// with signed representation.
unsigned long int startquant = pow(2,startquant_pow);// 

unsigned long int numsamples = (pow(2,anglen-1)-1);

unsigned long int sample_width = round((maxquant-startquant)/numsamples);
																			
																			
unsigned long int *samples;													

unsigned long int *result_atan;

unsigned long int clkcycles = numsamples+precis_p+4;

int main(int argc, char **argv, char **env)
{
	Verilated::commandArgs(argc, argv);
	Vbsg_cordic_atan* top = new Vbsg_cordic_atan;

	#if VM_TRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	#endif

	int samp_len = 0;
	samples = new unsigned long int [clkcycles];
	result_atan = new unsigned long int [clkcycles];
	int valid_in = 1;
	int ready_in = 1;

	#if VM_TRACE
	top->trace (tfp, 99);
	tfp->open ("CORDIC_atan.vcd");
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
				result_atan[i] = top->tan_inv_o;
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

	double aver_squa_err_ang = 0;

	double aver_err_ang;

	float maxerr_atan = 0;

	double max_err_samp_atan;

	bool test_fail;

	for(int i=0;i<samp_len;i++){
		float samp = samples[i]/pow(2,precision);

		double ideal_value_atan = atan(samp);

		double obser_value_atan = (result_atan[i+(precis_p+1+1)]/pow(2,precision))*PI/180;

		float err_atan = (ideal_value_atan - obser_value_atan);

		double atan_err_squa = err_atan*err_atan;

		aver_squa_err_ang+=atan_err_squa;
		if(maxerr_atan<fabs(err_atan)){
			maxerr_atan = fabs(err_atan);
			max_err_samp_atan = samp;
		}

		}
	aver_squa_err_ang/=samp_len;
	float stan_dev_ang = sqrt(aver_squa_err_ang);
	float error_expec_atan = error_bound_2_norm(precis_p,precision);

	std::cout.precision(10);
	std::cout<<std::endl;
	std::cout<<std::endl;
	std::cout<<"Minimum Vector tested:"<<pow(2,startquant_pow)<<std::endl;
	std::cout<<"Maximum Vector tested:"<<maxquant<<std::endl;
	std::cout<<"Sampling Interval:"<<sample_width<<std::endl;
	std::cout<<"Maximum Error in Tangent Inverse(in radians):"<<maxerr_atan<<std::endl;
	std::cout<<"Standard Deviation observed:"<<stan_dev_ang<<std::endl;
	std::cout<<"Maximum Error Vector (with fixed point representation):";
	std::cout<<max_err_samp_atan<<std::endl;
	std::cout<<"Maximum error bound(in radians) on Y-Reduction to find tan inverse: ";
	std::cout<<error_expec_atan<<std::endl;

	if(fabs(maxerr_atan)>error_expec_atan){
		test_fail = true;
		std::cout<<"TEST FAILED!"<<std::endl;
		std::cout<<"Maximum error is out of bounds by "<<maxerr_atan - error_expec_atan<<std::endl;
	}

	else{
		test_fail = false;
		std::cout<<"TEST PASSED!"<<std::endl;
	}
	

	#if VM_TRACE
	tfp->close();
	#endif

	delete top;
	exit(0);
	}
	


