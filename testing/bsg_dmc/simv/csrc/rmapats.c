// file = 0; split type = patterns; threshold = 100000; total count = 0.
#include <stdio.h>
#include <stdlib.h>
#include <strings.h>
#include "rmapats.h"

scalar dummyScalar;
scalar fScalarIsForced=0;
scalar fScalarIsReleased=0;
scalar fScalarHasChanged=0;
scalar fForceFromNonRoot=0;
scalar fNettypeIsForced=0;
scalar fNettypeIsReleased=0;
void  hsG_0__0 (struct dummyq_struct * I1108, EBLK  * I1109, U  I657);
void  hsG_0__0 (struct dummyq_struct * I1108, EBLK  * I1109, U  I657)
{
    U  I1352;
    U  I1353;
    U  I1354;
    struct futq * I1355;
    I1352 = ((U )vcs_clocks) + I657;
    I1354 = I1352 & ((1 << fHashTableSize) - 1);
    I1109->I703 = (EBLK  *)(-1);
    I1109->I707 = I1352;
    if (I1352 < (U )vcs_clocks) {
        I1353 = ((U  *)&vcs_clocks)[1];
        sched_millenium(I1108, I1109, I1353 + 1, I1352);
    }
    else if ((peblkFutQ1Head != ((void *)0)) && (I657 == 1)) {
        I1109->I708 = (struct eblk *)peblkFutQ1Tail;
        peblkFutQ1Tail->I703 = I1109;
        peblkFutQ1Tail = I1109;
    }
    else if ((I1355 = I1108->I1067[I1354].I720)) {
        I1109->I708 = (struct eblk *)I1355->I719;
        I1355->I719->I703 = (RP )I1109;
        I1355->I719 = (RmaEblk  *)I1109;
    }
    else {
        sched_hsopt(I1108, I1109, I1352);
    }
}
#ifdef __cplusplus
extern "C" {
#endif
void SinitHsimPats(void);
#ifdef __cplusplus
}
#endif
