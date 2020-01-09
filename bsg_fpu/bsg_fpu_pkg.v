/**
 *  bsg_fpu_pkg.v
 *
 *  @author tommy
 *
 */

 `ifndef BSG_FUP

 `define BSG_FUP

package bsg_fpu_pkg;

  // Special numbers
  //
  `define BSG_FPU_QUIETNAN(e,m) {1'b0, {e{1'b1}}, 1'b1, {(m-1){1'b0}}}  // aka canonical NaN
  `define BSG_FPU_SIGNAN(e,m) {1'b0, {e{1'b1}}, 1'b0, {(m-1){1'b1}}}    // signaling NaN
  `define BSG_FPU_INFTY(sgn,e,m) {sgn, {e{1'b1}}, {m{1'b0}}}            // infinity
  `define BSG_FPU_ZERO(sgn,e,m) {sgn, {(e+m){1'b0}}}                    // zero


endpackage

`endif
