/**
 *  bsg_fpu_pkg.v
 *
 *  @author tommy
 *
 */

package bsg_fpu_pkg;

  // opcode for bsg_fpu_top
  //
  typedef enum logic [3:0] {

    // arithmetic
    BSG_FPU_ADD,
    BSG_FPU_SUB,
    BSG_FPU_MUL,

    // comparison
    BSG_FPU_EQ,
    BSG_FPU_LT,
    BSG_FPU_LE,

    // min-max
    BSG_FPU_MIN,
    BSG_FPU_MAX,

    // conversion
    BSG_FPU_UI2F,
    BSG_FPU_I2F,
    BSG_FPU_F2I,
    BSG_FPU_F2UI,

    // sign inject
    BSG_FPU_SGNJ,
    BSG_FPU_SGNJN,
    BSG_FPU_SGNJX,

    // classify
    BSG_FPU_CLASS

  } bsg_fpu_opcode_e;


  // Special numbers
  //
  `define BSG_FPU_QUIETNAN(e,m) {1'b0, {e{1'b1}}, 1'b1, {(m-1){1'b0}}}  // aka canonical NaN
  `define BSG_FPU_SIGNAN(e,m) {1'b0, {e{1'b1}}, 1'b0, {(m-1){1'b1}}}    // signaling NaN
  `define BSG_FPU_INFTY(sgn,e,m) {sgn, {e{1'b1}}, {m{1'b0}}}            // infinity
  `define BSG_FPU_ZERO(sgn,e,m) {sgn, {(e+m){1'b0}}}                    // zero


endpackage
