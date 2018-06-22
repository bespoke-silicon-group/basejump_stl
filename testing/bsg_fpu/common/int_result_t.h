/**
 *  int_result.h
 *
 *  @author Tommy Jung
 */

#ifndef INT_RESULT_H
#define INT_RESULT_H

typedef struct {
    int unimplemented,
        invalid,
        overflow,
        underflow;
    int z;
} int_result_t;

void assert_int(int_result_t *ires);

#endif
