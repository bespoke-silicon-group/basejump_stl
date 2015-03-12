#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

scalar dummyScalar;
scalar fScalarIsForced=0;
scalar fScalarIsReleased=0;
scalar fScalarHasChanged=0;
void  hsG_0(struct dummyq_struct * I791, EBLK  * I792, U  I574);
void  hsG_0(struct dummyq_struct * I791, EBLK  * I792, U  I574)
{
    U  I982;
    U  I983;
    U  I984;
    struct futq * I985;
    I982 = ((U )vcs_clocks) + I574;
    I984 = I982 & 0xfff;
    I792->I510 = (EBLK  *)(-1);
    I792->I520 = I982;
    if (I982 < (U )vcs_clocks) {
        I983 = ((U  *)&vcs_clocks)[1];
        sched_millenium(I791, I792, I983 + 1, I982);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I574 == 1)) {
        I792->I521 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I510 = I792;
        peblkFutQ1Tail = I792;
    }
    else if ((I985 = I791->I760[I984].I527)) {
        I792->I521 = (struct eblk *)I985->I526;
        I985->I526->I510 = (RP )I792;
        I985->I526 = (RmaEblk  *)I792;
    }
    else {
        sched_hsopt(I791, I792, I982);
    }
}
U   hsG_1(U  I805);
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
