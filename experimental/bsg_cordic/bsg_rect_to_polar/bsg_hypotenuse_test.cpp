#include "Vbsg_cordic_hypotenuse.h"
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

double error_bound_2_norm_Y(int precis_p, int precision)
// ^^ This function calculates the maximum error bound for
// Y-Reduction. For detailed exlanation, please refer to 'Kota and
//Cavallaro: CORDIC Arithmetic for special-purpose processors; Pg:773'
{																	 
	float approx_bound_mod_y_n = 1.5*pow(2,-precision)*precis_p;
	float K_n = 1.0;
	float x,z;
	for(int i=0;i<precis_p+1;i++)
    {
 		z=pow(2,i);
        x=cos(atan2(1.00,z));
        K_n=K_n*x;
 	}
 	float max_bound_err = asin(approx_bound_mod_y_n/K_n) + precis_p*pow(2,-precision);
 	return max_bound_err;
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



double maxquant_bitlen = anslen - precision -2;
double maxquant_limit = pow(2,anslen-2);
double maxquant_test = maxquant_limit;
 // The maximum quantity after a lot of testing is recommended
 // to be 2^(anslen-2)-1 and not 2^(anslen-1) to save us from
 // overflow. It's equivalent to saying that we have one extra bit
 // for overflow. For detailed exlanation, please refer to 'Kota and
//Cavallaro: CORDIC Arithmetic for special-purpose processors; Pg:773,774'
  
long int startquant = pow(2,startquant_pow);
long int startquant_print = startquant; 

long int numsamples = (pow(2,(anslen-2)/2)-1);
long int sample_width = round((maxquant_limit-startquant)/numsamples);
																			
																			
long int *samples_x;
long int *samples_y;													

long int *result_mag;
long int *result_angl;

unsigned long int clkcycles = numsamples+precis_p+4;

int main(int argc, char **argv, char **env)
{
	Verilated::commandArgs(argc, argv);
	Vbsg_cordic_hypotenuse* top = new Vbsg_cordic_hypotenuse;

	#if VM_TRACE
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	#endif

	int samp_len = 0;
	samples_x = new long int [clkcycles];
	samples_y = new long int [clkcycles];
	result_mag = new long int [clkcycles];
	result_angl = new long int [clkcycles];
	int valid_in = 1;
	int ready_in = 1;


	#if VM_TRACE
	top->trace (tfp, 99);
	tfp->open ("CORDIC_hypotenuse.vcd");
	#endif

	for(int i=0;i<clkcycles;i++){

		while(main_time<10){

			#if VM_TRACE
			tfp->dump (main_time+i*10);
			#endif

			if((main_time%10)==0){

				if(sqrt(pow(startquant,2)+pow(maxquant_test,2))<pow(2,anslen-2)){
				top->x_i = startquant;
				top->y_i = maxquant_test;
				top->val_i = valid_in;
				top->ready_i = ready_in;
				samples_x[i] = startquant;
				samples_y[i] = maxquant_test;
				samp_len++;
				}
				top->clk_i = 1;
				result_mag[i] = top->mag_o;
				result_angl[i] = top->angl_o;
				startquant+=sample_width;
				maxquant_test-=sample_width;
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

	double aver_squa_err_mag = 0;
	double aver_squa_err_angl = 0;

	float maxerr_mag = 0;
	float maxerr_angl = 0;

	double max_err_samp_mag_x;
	double max_err_samp_mag_y;
	double max_err_samp_angl;

	bool test_fail;

	for(int i=1;i<samp_len;i++){
		
		double ideal_value_mag = sqrt(pow(samples_y[i],2)+pow(samples_x[i],2))/pow(2,precision);
		double ideal_value_angl = atan2(samples_y[i],samples_x[i]);

		long int signed_result_angl = result_angl[i+(precis_p+1+1+1+1)];
		if (signed_result_angl & signedconst)
    		signed_result_angl |= ~signedconst2;


		double obser_value_mag = (result_mag[i+(precis_p+1+1+1+1)]/pow(2,precision));
		double obser_value_angl = (signed_result_angl/pow(2,precision))*PI/180;

		float err_mag = (ideal_value_mag - obser_value_mag);
		float err_angl = (ideal_value_angl - obser_value_angl);

		double mag_err_squa = err_mag*err_mag;
		double angl_err_squa = err_angl*err_angl;
		
		aver_squa_err_mag+=mag_err_squa;
		aver_squa_err_angl+=angl_err_squa;
		
		// std::cout<<ideal_value_mag<<"    "<<obser_value_mag<<"   "<<samples_y[i]<<"  "<<samples_x[i]<<std::endl;
		if(maxerr_mag<fabs(err_mag)){

			maxerr_mag = fabs(err_mag);
			max_err_samp_mag_x = samples_x[i];
			max_err_samp_mag_y = samples_y[i];
		}

		if(maxerr_angl<fabs(err_angl)){

			maxerr_angl = fabs(err_angl);
			max_err_samp_angl = ideal_value_angl;
		}

		}
	aver_squa_err_mag/=samp_len;
	aver_squa_err_angl/=samp_len;

	float stan_dev_mag = sqrt(aver_squa_err_mag);
	float stan_dev_angl = sqrt(aver_squa_err_angl);

	float error_expec_angl = error_bound_2_norm_Y(precis_p,precision);
	float error_expec_mag = error_bound_2_norm_Z(precis_p,precision,anslen);

	std::cout.precision(10);
	std::cout<<std::endl;
	std::cout<<std::endl;
	std::cout<<"Minimum Vector tested:"<<startquant_print<<std::endl;
	// std::cout<<"Maximum Vector tested:"<<maxquant<<std::endl;
	std::cout<<"Sampling Interval:"<<sample_width<<std::endl;
	std::cout<<"Maximum Error in Magnitude:"<<maxerr_mag<<std::endl;
	std::cout<<"Standard Deviation observed in Magnitude:"<<stan_dev_mag<<std::endl;
	std::cout<<"Maximum Error Vector (x,y):";
	std::cout<<"("<<max_err_samp_mag_x<<" ,"<<max_err_samp_mag_y<<")"<<std::endl;
	std::cout<<"Maximum Error in angle (theta):"<<maxerr_angl<<std::endl;
	std::cout<<"Standard Deviation observed in angle (theta):"<<stan_dev_angl<<std::endl;
	std::cout<<"Maximum Error Vector (angle in radians with fixed point representation):";
	std::cout<<max_err_samp_angl<<std::endl;
	std::cout<<"Maximum error bound on Y-Reduction in finding angle(theta): ";
	std::cout<<error_expec_angl<<std::endl;
	std::cout<<"Maximum error bound(in radians) on Z-Reduction in finding  Magnitude: ";
	std::cout<<error_expec_mag<<std::endl;

	if(fabs(maxerr_mag)>error_expec_mag){
		test_fail = true;
		std::cout<<"TEST FAILED for Magnitude!"<<std::endl;
	}

	else{
		test_fail = false;
		std::cout<<"TEST PASSED for Magnitude!"<<std::endl;
	}

	if(fabs(maxerr_angl)>error_expec_angl){
		test_fail = true;
		std::cout<<"TEST FAILED for Angle!"<<std::endl;
	}

	else{
		test_fail = false;
		std::cout<<"TEST PASSED for Angle!"<<std::endl;
	}
	

	#if VM_TRACE
	tfp->close();
	#endif

	delete top;
	exit(0);
	}
	