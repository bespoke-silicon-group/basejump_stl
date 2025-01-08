// these are helpful macros for inputs to this module
// they could be used if you were actually dividing by a constant and couldn't use bsg_hash_bank
// and whatever the synthesis tool does is unsatisfactory
// or, they could be used for test, and software equivalents

`define bsg_idiv_unsigned_recip_shift(denom) $clog2(denom)
`define bsg_idiv_unsigned_recip_shift_width(denom_width) $clog2(denom_width+1)

// ceil(2^(shift+numer_width) / denom)
// but watching out for precision issues with shifts


`define bsg_idiv_unsigned_recip_multiply(denom,numer_width,denom_width) ((`BSG_SAFE_SHIFT_LEFT_CONST_BY_VARIABLE( 1, ($clog2(denom)+numer_width),(denom_width+numer_width), 0 ) + denom - 1'b1) / denom)

`define bsg_idiv_unsigned_recip_multiply_width(numer_width) ((numer_width)+1)

