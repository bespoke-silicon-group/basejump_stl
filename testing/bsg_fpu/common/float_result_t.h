/**
 *  float_result.h
 *
 *  @author Tommy Jung
 */

#ifndef FLOAT_RESULT_H
#define FLOAT_RESULT_H

typedef struct {
    int unimplemented,
        invalid,
        overflow,
        underflow;
    float z;
} float_result_t;


void assert(float_result_t *fres);

#endif
