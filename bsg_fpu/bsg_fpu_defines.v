/**
 *  bsg_fpu_defines.v
 *
 *  @author Tommy Jung
 */


`ifndef BSG_FPU_DEFINES_V
`define BSG_FPU_DEFINES_V

`define BSG_FPU_SIGNAN(sgn,e,m) {sgn, {e{1'b1}}, 1'b0, {(m-1){1'b1}}}
`define BSG_FPU_QUIETNAN(sgn,e,m) {sgn, {e{1'b1}}, {m{1'b1}}}
`define BSG_FPU_INFTY(sgn,e,m) {sgn, {e{1'b1}}, {m{1'b0}}}
`define BSG_FPU_ZERO(sgn,e,m) {sgn, {(e+m){1'b0}}}

`endif

