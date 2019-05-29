#include<svdpi.h>

#include<cstdio>
#include<cstdlib>

extern "C" int float32Representation(float f){
    int *x = (int *)(&f);
    return *x;
}

extern "C" float float32Encode(int x){
    float *y =  (float *)(&x);
    return *y;
}

extern "C" int64_t float64Representation(double f){
    int64_t *x = (int64_t *)(&f);
    return *x;
}

extern "C" double float64Encode(int64_t x){
    double *y = (double *)(&x);
    return *y;
}

extern "C" short getDivisionResult(short dividend, short divisor){
    unsigned int dividend_mantissa = (dividend & 1023) + 1024;
    unsigned int divisor_mantissa = (divisor & 1023) + 1024;

    dividend_mantissa <<= 11;
    unsigned short dividend_exponent = (dividend & 0x7C00) >> 10;
    unsigned short divisor_exponent = (divisor & 0x7C00) >> 10;

    unsigned short quotient_sign = (dividend ^ divisor) & 0x8000;

    short quotient_exponent = (dividend_exponent - divisor_exponent + 15);

    unsigned int quotient = dividend_mantissa / divisor_mantissa;
    int shifted = 0;

    if((quotient & 2048) == 0){
        quotient_exponent--;
    }
    return quotient_sign | (quotient_exponent << 10) | (quotient & 1023);
}

extern "C" int performFloat16Division(short dividend, short divisor, short quotient_hw, int unimplemented, int overflow, int underflow, int invalid, int divisor_is_zero){
    // subnormal condition
    short s_deno = !(dividend & 0x7C00);
    short d_deno = !(divisor & 0x7C00);

    if((s_deno | d_deno) & unimplemented) return 1;

    // NaN
    short result_is_nan = (dividend & 0x7C00) == 0x7C00 && (dividend & 0x3FF) != 0 // dividend is NaN
                        || (divisor & 0x7C00) == 0x7C00 && (divisor & 0x3FF) != 0  // divisor is NaN
                        || (dividend & 0x7C00) == 0x7C00 && (dividend & 0x3FF) == 0 && (divisor & 0x7C00) == 0x7C00 && (divisor & 0x3FF) == 0 // inf/inf
                        || dividend == 0 && divisor == 0; // 0/0
    if(result_is_nan && (quotient_hw & 0x7C00) == 0x7C00 && (quotient_hw & 0x3FF) != 0) 
        return 1;
    
    // Inf

    short result_is_inf = (dividend & 0x7C00) == 0x7C00 && (dividend & 0x3FF) == 0 && (divisor & 0x7C00) != 0x7C00 | // inf / normal value
                        ((dividend & 0x7FFF) != 0 && (divisor & 0x7FFF) == 0); // normal value / 0

    if(result_is_inf && (quotient_hw & 0x7C00) == 0x7C00 && (quotient_hw & 0x3FF) == 0) return 1;
    if((divisor & 0x7FFF) == 0 && divisor_is_zero) return 1;

    unsigned int dividend_mantissa = (dividend & 1023) + 1024;
    unsigned int divisor_mantissa = (divisor & 1023) + 1024;

    dividend_mantissa <<= 11;
    unsigned short dividend_exponent = (dividend & 0x7C00) >> 10;
    unsigned short divisor_exponent = (divisor & 0x7C00) >> 10;

    unsigned short quotient_sign = (dividend ^ divisor) & 0x8000;

    short quotient_exponent = (dividend_exponent - divisor_exponent + 15);

    unsigned int quotient = dividend_mantissa / divisor_mantissa;
    int shifted = 0;

    if((quotient & 2048) == 0){
        quotient_exponent--;
    } else {
        quotient >>= 1;
    }

    // check overflow and underflow
    if((quotient_exponent & 0xFFE0) == 0xFFE0 && underflow) return 1;
    if((quotient_exponent & 0xFFE0) == 0x20 && overflow) return 1;


    short quotient_expected =  quotient_sign | (quotient_exponent << 10) | quotient & 1023;

    if(quotient_expected == quotient_hw)
        return 1;
    else
        return 0;

    // inf condition

}

extern "C" void pause(){
    if(std::getc(stdin) == 'q'){
        std::exit(0);
    }
}