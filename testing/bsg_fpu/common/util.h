/**
 *  util.h
 *
 *  @author Tommy Jung
 */

#ifndef UTIL_H
#define UTIL_H

#include <math.h>
#include <stdio.h>
#include <fenv.h>
#include <stdlib.h>
#include <time.h>
#include <stdbool.h>

#define flt(X) (*(float*)&X)
#define hex(X) (*(int*)&X)

float randf();
void print_float_in_binary(float a);
void print_done();
void print_reset();
bool is_denormal(float a);
void checkError(int i);
bool is_sig_nan(float a);
float itof(int a);
int ftoi(float a);
bool is_infty(float a);
void linspace(float *buf, float min, float max, int n);

#endif
