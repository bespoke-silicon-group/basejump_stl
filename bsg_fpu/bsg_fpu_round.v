/**
 *  bsg_fpu_round.v
 *
 *  determine whether to round or not depending on sign, lsb, guard, round, and sticky bits.
 *
 *  @author Tommy Jung
 */

// lsb | g r s
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
      3'b000: // RNE: round to nearest, ties to even (default)
        do_round_o = guard_i & (lsb_i | round_i | sticky_i);     
      3'b001: // RTZ: round towards zero (truncate)
        do_round_o = 1'b0;
      3'b010: // RDN: round down (floor)
        do_round_o = sign_i;
      3'b011: // RUP: round up (ceil)
        do_round_o = ~sign_i;
      3'b100: // RMM: round to nearest, ties to max magnitude (what we learned in grammar school).
        do_round_o = guard_i;
      default:
        do_round_o = 1'b0;
    endcase
  end

endmodule
