/**
 *  float_result_t.c
 *
 *  @author Tommy Jung
 */


#include <stdio.h>
#include "util.h"
#include "float_result_t.h"

void assert(float_result_t *fres)
{
    printf("00100_");

    // padding = 75 - 32 - 4 = 39
    for (int i = 0; i < 39; i++) {
        printf("0");
    }
    printf("_");

    // print exceptions
    printf("%d", fres->unimplemented);
    printf("%d", fres->invalid);
    printf("%d", fres->overflow);
    printf("%d", fres->underflow);
    printf("_");
    
    print_float_in_binary(fres->z);
    printf("\n");
}
