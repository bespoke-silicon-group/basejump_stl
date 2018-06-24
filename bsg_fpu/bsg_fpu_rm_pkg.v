/**
 *  bsg_fpu_rm_pkg.v
 *
 *  @author Tommy Jung
 */

package bsg_fpu_rm_pkg;

  typedef enum logic [2:0] {
    RNE = 3'b000 // RNE: round to nearest, ties to even (default)
    ,RTZ = 3'b001 // RTZ: round towards zero (truncate)
    ,RDN = 3'b010 // RDN: round down (floor)
    ,RUP = 3'b011 // RUP: round up (ceil)
    ,RMM = 3'b100 // RMM: round to nearest, ties to max magnitude.
  } rm_risc_v;

endpackage : bsg_fpu_rm_pkg
