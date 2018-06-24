/**
 *  bsg_fpu_round.v
 *
 *  determine whether to round or not depending on sign, lsb, guard, round, and sticky bits.
 *
 *  @author Tommy Jung
 */

// lsb | g r s

import bsg_fpu_rm_pkg::*;

module bsg_fpu_round (
  input sign_i
  ,input lsb_i
  ,input guard_i
  ,input round_i
  ,input sticky_i
  ,input [2:0] rm_i
  ,output logic do_round_o
);

  // if do_round_o == 1, that means we want to increment the 'magnitude'.
  always_comb begin
    case (rm_i)
      RNE: 
        do_round_o = guard_i & (lsb_i | round_i | sticky_i);     
      RTZ: 
        do_round_o = 1'b0;
      RDN: 
        do_round_o = sign_i & (guard_i | round_i | sticky_i);
      RUP: 
        do_round_o = ~sign_i & (guard_i | round_i | sticky_i);
      RMM: 
        do_round_o = guard_i;
      default:
        do_round_o = 1'b0;
    endcase
  end

endmodule
