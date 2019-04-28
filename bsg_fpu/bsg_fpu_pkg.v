/**
 *  bsg_fpu_pkg.v
 *
 *  @author tommy
 */

package bsg_fpu_pkg;

  typedef enum logic [2:0] {
    BSG_FPU_ADD,
    BSG_FPU_SUB,
    BSG_FPU_MUL,
    BSG_FPU_EQ,
    BSG_FPU_LT,
    BSG_FPU_LE
  } bsg_fpu_opcode_e;

  `define BSG_FPU_SIGNAN(sgn,e,m) {sgn, {e{1'b1}}, 1'b0, {(m-1){1'b1}}}
  `define BSG_FPU_QUIETNAN(sgn,e,m) {sgn, {e{1'b1}}, {m{1'b1}}}
  `define BSG_FPU_INFTY(sgn,e,m) {sgn, {e{1'b1}}, {m{1'b0}}}
  `define BSG_FPU_ZERO(sgn,e,m) {sgn, {(e+m){1'b0}}}

endpackage
