// Program to produce a file with the expected output
// for all possible inputs to an unsigned 4-bit divider pursuant to
// RISC-V ISA Manual: Section 7.2 - Division Operations

#include <stdio.h>
// Function to compute quotient
int quotient(int a, int b){
  if (b == 0) { // RISC-V 7.2: Quotient of division by zero has all bits set 
    return 15;
  } else { // Return integer division result when not a RISC-V edge case
    return a / b;
  }
}

// Function to compute remainder
int rem(int a, int b){
  if (b == 0) { // RISC-V 7.2: Remainder of division by zero is dividend
    return a;
  } else {
    return a % b; // Return modulus when not a RISC-V edge case
  }
}

int main(){
  FILE *file_in, *file_out;
  int dividend, divisor, remain, quot;
  
  file_in = fopen("u.txt", "r");
  file_out = fopen("u_expected.txt", "w");

  for (int i = 0; i < 256; i ++) {
    fscanf(file_in, "%d", &dividend);
    fscanf(file_in, "%d", &divisor);
    
    //Calling function quotient()    
    quot = quotient(dividend, divisor);

    //Calling function remainder()    
    remain = rem(dividend, divisor);

    fprintf(file_out, "%d %d %d %d\n", dividend, divisor, quot, remain);
  }

  fclose(file_in);
  fclose(file_out);

  return 0;
}
