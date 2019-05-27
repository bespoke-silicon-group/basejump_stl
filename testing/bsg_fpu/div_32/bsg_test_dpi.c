#include<svdpi.h>

int float32Representation(float f){
    int *x = (int *)(&f);
    return *x;
}

float float32Encode(int x){
    float *y =  (float *)(&x);
    return *y;
}

int64_t float64Representation(double f){
    int64_t *x = (int64_t *)(&f);
    return *x;
}

double float64Encode(int64_t x){
    double *y = (double *)(&x);
    return *y;
}