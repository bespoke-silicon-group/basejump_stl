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
#include <stdlib.h>

#define flt(X) (*(float*)&X)
#define hex(X) (*(uint32_t*)&X)

// trace function
void print_done(int ring_width_p);

// print helper
void print_float_in_binary(float f);
void print_int_in_binary(int i);
void print_uint_in_binary(uint32_t i);

// time check
bool is_sig_nan(float f);
bool is_nan(float f);
bool is_infty(float f);
bool is_denormal(float f);
bool is_zero(float f);

// conversion
float i2f(uint32_t i);
uint32_t f2i(float f);

// special number
float snanf();
float infty();

// random gen
float randf();

#endif
