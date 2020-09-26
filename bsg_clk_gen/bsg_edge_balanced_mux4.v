// This module is simply a 4-input mux. The edge balancing
// properties are process specific. A 250nm harded version
// can be found at:
//
//      bsg_ip_cores/hard/bsg_clk_gen/bsg_edge_balanced_mux4.v
//
// This module should be replaced by the hardened version
// when being synthesized.
//
`include "bsg_defines.v"

module bsg_edge_balanced_mux4
  (input        A
  ,input        B
  ,input        C
  ,input        D
  ,input  [1:0] S

  ,output logic Y
  );

  always_comb
    begin
      case (S)
        0:       Y = A;
        1:       Y = B;
        2:       Y = C;
        3:       Y = D;
        default: Y = 1'bx;
      endcase
    end

endmodule

