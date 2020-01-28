/**
 *  bsg_fpu_defines.vh
 *
 *  @author tommy
 *
 */

`ifndef BSG_FPU_DEFINES_VH
`define BSG_FPU_DEFINES_VH
  // Special numbers
  `define BSG_FPU_QUIETNAN(e,m) {1'b0, {e{1'b1}}, 1'b1, {(m-1){1'b0}}}  // aka canonical NaN
  `define BSG_FPU_SIGNAN(e,m) {1'b0, {e{1'b1}}, 1'b0, {(m-1){1'b1}}}    // signaling NaN
  `define BSG_FPU_INFTY(sgn,e,m) {sgn, {e{1'b1}}, {m{1'b0}}}            // infinity
  `define BSG_FPU_ZERO(sgn,e,m) {sgn, {(e+m){1'b0}}}                    // zero

`endif
