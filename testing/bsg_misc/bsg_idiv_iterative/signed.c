// Program to produce a file with the expected output
// for all possible inputs to a signed 4-bit divider pursuant to
// RISC-V ISA Manual: Section 7.2 - Division Operations
#include <stdio.h>
#include <math.h>
#define WIDTH 4
#define ITERS 1 << (WIDTH * 2)
// #define ITERS 10000

// Function to compute quotient
long long int quotient(long long int a, long long int b){
  if (b == 0) { // RISC-V 7.2: Quotient of division by zero has all bits set
    return -1;
  } else if ((a == (-pow(2, WIDTH - 1))) & (b == -1)) { // RISC-V 7.2: Quotient=Dividend for signed div overflow
    return a;
  } else { // Return integer division result when not a RISC-V edge case
    return a / b;
  }
}

// Function to compute remainder
long long int rem(long long int a, long long int b){
  if (b == 0) { // RISC-V 7.2: Remainder of division by zero equals the dividend
    return a;
  } else if ((a == (-pow(2, WIDTH - 1))) & (b == -1)) { // RISC-V 7.2: Remainder is zero for signed div overflow
    return 0;
  } else { // Return modulus when not a RISC-V edge case
    return a % b;
  }
}

int main(){
  FILE *file_in, *file_out;
  long long int dividend, divisor, remain, quot;
  
  file_in = fopen("s.txt", "r");
  file_out = fopen("s_expected.txt", "w");

  for (int i = 0; i < ITERS; i ++) {
    fscanf(file_in, "%lld", &dividend);
    fscanf(file_in, "%lld", &divisor);
    
    //Calling function quotient()    
    quot = quotient(dividend, divisor);

    //Calling function remainder()    
    remain = rem(dividend, divisor);

    fprintf(file_out, "%lld %lld %lld %lld\n", dividend, divisor, quot, remain);
  }

  fclose(file_in);
  fclose(file_out);

  return 0;
}
