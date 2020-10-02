//====================================================================
// bsg_idiv_iterative.v
// 11/14/2016, shawnless.xie@gmail.com
//====================================================================
//
// An N-bit integer iterative divider, capable of signed & unsigned division
// Code refactored based on Sam Larser's work
// -------------------------------------------
// Cycles       Operation
// -------------------------------------------
// 1            latch inputs
// 2            negate divisor (if necessary)
// 3            negate dividend (if necessary)
// 4            shift in msb of the dividend
// 5-37         iterate
// 38           repair remainder (if necessary)
// 39           negate remainder (if necessary)
// 40           negate quotient (if necessary)
// -------------------------------------------
// TODO
// 1. added register to hold the previous operands, if the current operands
//    are the same with prevous one, we can output the results instantly. This
//    is useful for a RISC ISA, in which only quotient or remainder is need in
//    one instruction.
// 2. usging data detection logic to reduce the iteration cycles.
`include "bsg_defines.v"

module bsg_idiv_iterative #(parameter width_p=32, parameter bitstack_p=0)
    (input                  clk_i
    ,input                  reset_i

    ,input                  v_i      //there is a request
    ,output                 ready_o  //idiv is idle 

    ,input [width_p-1: 0]   dividend_i
    ,input [width_p-1: 0]   divisor_i
    ,input                  signed_div_i

    ,output                 v_o      //result is valid
    ,output [width_p-1: 0]  quotient_o
    ,output [width_p-1: 0]  remainder_o
    ,input                  yumi_i
    );


   wire [width_p:0] opA;
   assign remainder_o = opA[width_p-1:0];

   wire [width_p:0] opC;
   assign quotient_o = opC[width_p-1:0];

   wire         signed_div_r;
   wire [width_p-1:0]  dividend_r;
   wire [width_p-1:0]  divisor_r;
   wire divisor_msb  = signed_div_r & divisor_r[width_p-1];
   wire dividend_msb = signed_div_r & dividend_r[width_p-1];

   wire latch_inputs;
   bsg_dff_en#(.width_p(1)) req_reg
       (.data_i (signed_div_i)
       ,.data_o (signed_div_r)
       ,.en_i   (latch_inputs)
       ,.clk_i(clk_i)
        );

   bsg_dff_en#(.width_p(width_p))dividend_reg
       (.data_i (dividend_i)
       ,.data_o (dividend_r)
       ,.en_i   (latch_inputs)
       ,.clk_i(clk_i)
       );

   bsg_dff_en#(.width_p(width_p))divisor_reg
       (.data_i (divisor_i)
       ,.data_o (divisor_r)
       ,.en_i   (latch_inputs)
       ,.clk_i(clk_i)
       );

   //if the divisor is zero
   wire         zero_divisor_li   =  ~(| divisor_r);

   wire         opA_sel;
   wire [width_p:0]  opA_mux;
   wire [width_p:0]  add_out;
   bsg_mux  #(.width_p(width_p+1), .els_p(2)) muxA
       (.data_i({ {divisor_msb, divisor_r}, add_out } )
       ,.data_o(opA_mux)
       ,.sel_i(opA_sel)
     );

   wire [2:0]   opB_sel;
   wire [width_p:0]  opB_mux;
   bsg_mux_one_hot #(.width_p(width_p+1), .els_p(3)) muxB
          ( .data_i( {opC, add_out, {add_out[width_p-1:0], opC[width_p]}} )
           ,.data_o(  opB_mux )
           ,.sel_one_hot_i(opB_sel)
     );

   wire [2:0]   opC_sel;
   wire [width_p:0]  opC_mux;
   bsg_mux_one_hot #(.width_p(width_p+1), .els_p(3)) muxC
          ( .data_i( {{dividend_msb, dividend_r},add_out, {opC[width_p-1:0], ~add_out[width_p]}} )
           ,.data_o(  opC_mux )
           ,.sel_one_hot_i(opC_sel)
     );

   wire opA_ld;
   bsg_dff_en#(.width_p(width_p+1)) opA_reg
       (.data_i (opA_mux)
       ,.data_o (opA    )
       ,.en_i   (opA_ld )
       ,.clk_i(clk_i)
       );
 
   wire         opB_ld;
   wire [width_p:0]  opB;
   bsg_dff_en#(.width_p(width_p+1)) opB_reg
       (.data_i (opB_mux)
       ,.data_o (opB    )
       ,.en_i   (opB_ld )
       ,.clk_i(clk_i)
       );

   wire opC_ld;
   bsg_dff_en#(.width_p(width_p+1)) opC_reg
       (.data_i (opC_mux)
       ,.data_o (opC    )
       ,.en_i   (opC_ld )
       ,.clk_i(clk_i)
       );

  wire        opA_inv;
  wire        opB_inv;
  wire        opA_clr_l;
  wire        opB_clr_l;

  wire [width_p:0] add_in0;
  wire [width_p:0] add_in1;


  // this logic is sandwiched between bitstacks -- MBT
  if (bitstack_p) begin: bs

    wire [width_p:0] opA_xnor;
    bsg_xnor#(.width_p(width_p+1)) xnor_opA 
        (.a_i({(width_p+1){opA_inv}})
        ,.b_i(opA)
        ,.o  (opA_xnor)
        ); 

    wire [width_p:0] opB_xnor;
    bsg_xnor#(.width_p(width_p+1)) xnor_opB 
        (.a_i({(width_p+1){opB_inv}})
        ,.b_i(opB)
        ,.o  (opB_xnor)
        ); 

    bsg_nor2 #(.width_p(width_p+1)) nor_opA 
       ( .a_i( opA_xnor )
        ,.b_i({(width_p+1){~opA_clr_l}})
        ,.o  (add_in0)
        );

    bsg_nor2 #(.width_p(width_p+1)) nor_opB 
       ( .a_i( opB_xnor )
        ,.b_i( {(width_p+1){~opB_clr_l}})
        ,.o  (add_in1)
        );

  end
  else begin: nbs

    assign add_in0 = (opA ^ {width_p+1{opA_inv}}) & {width_p+1{opA_clr_l}};
    assign add_in1 = (opB ^ {width_p+1{opB_inv}}) & {width_p+1{opB_clr_l}};

  end


  wire adder_cin;
  bsg_adder_cin #(.width_p(width_p+1)) adder
   (.a_i  (add_in0)
   ,.b_i  (add_in1)
   ,.cin_i(adder_cin)
   ,.o    (add_out)
   );

  bsg_idiv_iterative_controller #(.width_p(width_p)) control 
     ( .reset_i                  (reset_i)
      ,.clk_i                    (clk_i)

      ,.v_i                      (v_i)
      ,.ready_o                  (ready_o)

      ,.zero_divisor_i           (zero_divisor_li)
      ,.signed_div_r_i           (signed_div_r)
      ,.adder_result_is_neg_i    (add_out[width_p])
      ,.opA_is_neg_i             (opA[width_p])
      ,.opC_is_neg_i             (opC[width_p])

      ,.opA_sel_o                (opA_sel)
      ,.opA_ld_o                 (opA_ld)
      ,.opA_inv_o                (opA_inv)
      ,.opA_clr_l_o              (opA_clr_l)

      ,.opB_sel_o                (opB_sel)
      ,.opB_ld_o                 (opB_ld)
      ,.opB_inv_o                (opB_inv)
      ,.opB_clr_l_o              (opB_clr_l)

      ,.opC_sel_o                (opC_sel)
      ,.opC_ld_o                 (opC_ld)

      ,.latch_inputs_o           (latch_inputs)
      ,.adder_cin_o              (adder_cin)

      ,.v_o(v_o)
      ,.yumi_i(yumi_i)
     );
endmodule // divide
