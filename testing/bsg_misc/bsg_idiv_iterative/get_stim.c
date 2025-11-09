//*===========================================================================
//
//   Function:  PLI routine to get stimulus from an input data file,
//and apply the values to input signals of the testbench
//
//=========================================================================*/

//#include "/home/tools/synopsys/vcs/sun_sparc_solaris_5.5.1/lib/acc_user.h"
#include "acc_user.h"
#include <stdio.h>
#include <stdlib.h>

FILE *in_file = NULL;/* file to read in stimulus */
char *filename;/* file name of stimulus */
s_setval_value value;/* value of arguments */
s_setval_delay delay;/* delay (hardwired to "none") */


void init()
{
  /* initialize random number generator */
  srand48(0);
      
  /* required when using acc routines */
  acc_initialize();

  /* setup input format and delay */
  value.format    = accIntVal;

  delay.model     = accNoDelay;
  delay.time.type = accRealTime;
  delay.time.real = 0;

  /* open input file */
  filename = "divide_4.stim"; 
  in_file = fopen(filename, "r");

  /* end if file can't be opened */
  if (!in_file)
    {
      io_printf("ERROR: can't open stimulus file %s\n",filename);
      exit(1);
    }
}


int get_stim()
{
  handle signal;/* handle to get_stim arguments */
  int dividend;
  int divisor;

  /* set the dividend */
  signal = acc_handle_tfarg(1);
  if (fscanf(in_file, "%x", &dividend) == EOF)
    dividend = (int)mrand48();

  value.value.integer = dividend;
  acc_set_value(signal, &value, &delay);

  /* set the divisor */
  signal = acc_handle_tfarg(2);
  if (fscanf(in_file, "%x", &divisor) == EOF)
    divisor = (int)mrand48();

  value.value.integer = divisor;
  acc_set_value(signal, &value, &delay);
}


void done()
{
  fclose(in_file);
  acc_close();
}
