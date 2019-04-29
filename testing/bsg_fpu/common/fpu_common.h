/**
 *  fpu_common.h
 *
 *  @author tommy
 */

#ifndef FPU_COMMON_H
#define FPU_COMMON_H

#include <stdbool.h>
#include <stdint.h>
#include <math.h>

#define flt(X) (*(float*)&X)
#define hex(X) (*(uint32_t*)&X)


void print_done(int ring_width_p);
void print_float_in_binary(float f);
bool is_sig_nan(float f);
bool is_nan(float f);
bool is_infty(float f);
bool is_denormal(float f);
bool is_zero(float f);

float i2f(uint32_t i);
uint32_t f2i(float f);

float snanf();
float infty();

#endif
