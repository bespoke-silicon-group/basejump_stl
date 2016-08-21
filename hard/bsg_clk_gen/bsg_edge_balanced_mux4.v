// TSMC 250nm implementation of a 4-input mux. This mux has
// the property of being edge balanced which makes it ideal
// for clock input. A non-process specific implementation
// can be found at:
//
//      bsg_ip_cores/bsg_clk_gen/bsg_edge_balanced_mux4.v
// 
// This module should replace the non-process specific
// implementation when being synthesized.
//
module bsg_edge_balanced_mux4
  (input        A
  ,input        B
  ,input        C
  ,input        D
  ,input  [1:0] S
  ,output       Y
  );

  wire Y_inv;
  
  MXI4X4 M1
    (.A(A)
    ,.B(B)
    ,.C(C)
    ,.D(D)
    ,.S0(S[0])
    ,.S1(S[1])
    ,.Y(Y_inv)
    );
  
  CLKINVX16 I1
    (.A(Y_inv)
    ,.Y(Y)
    );

endmodule
