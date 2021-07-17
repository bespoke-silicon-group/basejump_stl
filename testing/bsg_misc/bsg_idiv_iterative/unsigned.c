// Program to produce a file with the expected output
// for all possible inputs to an unsigned 4-bit divider pursuant to
// RISC-V ISA Manual: Section 7.2 - Division Operations

#include <stdio.h>
#include <math.h>
#include <limits.h>
#define WIDTH 4
#define ITERS 1 << (WIDTH*2)
// #define ITERS 10000

// Function to compute quotient
unsigned long long int quotient(unsigned long long int a, unsigned long long int b){
  if (b == 0) { // RISC-V 7.2: Quotient of division by zero has all bits set 
    if (WIDTH == 64) {
      return ULLONG_MAX;
    } else {
      return (pow(2, WIDTH) - 1);
    }
  } else { // Return integer division result when not a RISC-V edge case
    return a / b;
  }
}

// Function to compute remainder
unsigned long long int rem(unsigned long long int a, unsigned long long int b){
  if (b == 0) { // RISC-V 7.2: Remainder of division by zero is dividend
    return a;
  } else {
    return a % b; // Return modulus when not a RISC-V edge case
  }
}

int main(){
  FILE *file_in, *file_out;
  unsigned long long int dividend, divisor, remain, quot;
  
  file_in = fopen("u.txt", "r");
  file_out = fopen("u_expected.txt", "w");
  
  for (int i = 0; i < ITERS; i ++) {
    fscanf(file_in, "%llu", &dividend);
    fscanf(file_in, "%llu", &divisor);
    
    //Calling function quotient()    
    quot = quotient(dividend, divisor);

    //Calling function remainder()    
    remain = rem(dividend, divisor);

    fprintf(file_out, "%llu %llu %llu %llu\n", dividend, divisor, quot, remain);
  }

  fclose(file_in);
  fclose(file_out);

  return 0;
}
