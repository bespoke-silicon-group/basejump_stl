//====================================================================
// bsg_idiv_iterative.sv
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
//
// Schematic: https://docs.google.com/presentation/d/1F7Lam7fMCp-v9K1PsjTvypWHJFFXfqoX6pJrmgf-_JE/
//
// TODO
// 1. added register to hold the previous operands, if the current operands
//    are the same with prevous one, we can output the results instantly. This
//    is useful for a RISC ISA, in which only quotient or remainder is need in
//    one instruction.
// 2. usging data detection logic to reduce the iteration cycles.
`include "bsg_defines.sv"

module bsg_idiv_iterative #(parameter width_p=32, parameter bitstack_p=0, parameter bits_per_iter_p = 1)
    (input                  clk_i
    ,input                  reset_i

    ,input                  v_i      //there is a request
    ,output                 ready_and_o  //idiv is idle 

    ,input [width_p-1: 0]   dividend_i
    ,input [width_p-1: 0]   divisor_i
    ,input                  signed_div_i

    ,output                 v_o      //result is valid
    ,output [width_p-1: 0]  quotient_o
    ,output [width_p-1: 0]  remainder_o
    ,input                  yumi_i
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
   initial begin
        assert (bits_per_iter_p == 1 || bits_per_iter_p == 2)
        else $error("Illegal value for parameters bits_per_iter_p given: (%0d). Legal values are 1 or 2.", bits_per_iter_p);
	   
	assert (bits_per_iter_p == 1 || (bits_per_iter_p == 2 && (width_p % 2 == 0)))
	else $error("Illegal value for parameter width_p: (%0d) given bits_per_iter_p: (%0d). Width must be even when resolving 2 bits per iteration", width_p, bits_per_iter_p);
   end
`endif
   
   wire [width_p:0] opA_r;
   assign remainder_o = opA_r[width_p-1:0];

   wire [width_p:0] opC_r;
   assign quotient_o = opC_r[width_p-1:0];

   wire         signed_div_r;
   wire divisor_msb  = signed_div_i & divisor_i[width_p-1];
   wire dividend_msb = signed_div_i & dividend_i[width_p-1];

   wire latch_signed_div_lo;
   bsg_dff_en#(.width_p(1)) req_reg
       (.data_i (signed_div_i)
       ,.data_o (signed_div_r)
       ,.en_i   (latch_signed_div_lo)
       ,.clk_i(clk_i)
        );

   //if the divisor is zero
   wire         zero_divisor_li   =  ~(| opA_r);

   wire [1:0]   opA_sel_lo;
   wire [width_p:0]  opA_mux;

   wire [width_p:0]  add1_out, add2_out;
   bsg_mux_one_hot #(.width_p(width_p+1), .els_p(2)) muxA
          ( .data_i({ {divisor_msb, divisor_i}, add1_out } )
           ,.data_o(  opA_mux )
           ,.sel_one_hot_i(opA_sel_lo)
     );
   
   wire [width_p:0]  opB_mux, opC_mux;
   wire [bits_per_iter_p + 1:0] opB_sel_lo, opC_sel_lo;
   
   if (bits_per_iter_p == 2) begin

      bsg_mux_one_hot #(.width_p(width_p+1), .els_p(4)) muxB
        (.data_i( {opC_r, add1_out, {add1_out[width_p-1:0], opC_r[width_p]}, {add2_out[width_p-1:0], opC_r[width_p-1]}} )
	      ,.data_o(  opB_mux )
	      ,.sel_one_hot_i(opB_sel_lo)
	      );

      bsg_mux_one_hot #(.width_p(width_p+1), .els_p(4)) muxC
        (.data_i( {{dividend_msb, dividend_i},add1_out, {opC_r[width_p-1:0], ~add1_out[width_p]}, {opC_r[width_p-2:0], ~add1_out[width_p], ~add2_out[width_p]}})
        ,.data_o(  opC_mux )
        ,.sel_one_hot_i(opC_sel_lo)
        );
      
   end else begin

      bsg_mux_one_hot #(.width_p(width_p+1), .els_p(3)) muxB
        (.data_i( {opC_r, add1_out, {add1_out[width_p-1:0], opC_r[width_p]}} )
        ,.data_o( opB_mux )
        ,.sel_one_hot_i(opB_sel_lo)
        );

      bsg_mux_one_hot #(.width_p(width_p+1), .els_p(3)) muxC
        (.data_i( {{dividend_msb, dividend_i},add1_out, {opC_r[width_p-1:0], ~add1_out[width_p]}} )
        ,.data_o( opC_mux )
	      ,.sel_one_hot_i(opC_sel_lo)
	      );
       
  end
   
   wire opA_ld_lo;
   bsg_dff_en#(.width_p(width_p+1)) opA_reg
       (.data_i (opA_mux)
       ,.data_o (opA_r  )
       ,.en_i   (opA_ld_lo )
       ,.clk_i(clk_i)
       );
 
   wire         opB_ld_lo;
   wire [width_p:0]  opB_r;
   bsg_dff_en#(.width_p(width_p+1)) opB_reg
       (.data_i (opB_mux)
       ,.data_o (opB_r  )
       ,.en_i   (opB_ld_lo )
       ,.clk_i(clk_i)
       );

   wire opC_ld_lo;
   bsg_dff_en#(.width_p(width_p+1)) opC_reg
       (.data_i (opC_mux)
       ,.data_o (opC_r  )
       ,.en_i   (opC_ld_lo )
       ,.clk_i(clk_i)
       );

  wire        opA_inv_lo;
  wire        opB_inv_lo;
  wire        opA_clr_lo;
  wire        opB_clr_lo;

  wire [width_p:0] add1_in0;
  wire [width_p:0] add1_in1;  
  wire [width_p:0] add2_in0;
  wire [width_p:0] add2_in1;

  // this logic is sandwiched between bitstacks -- MBT
  if (bitstack_p) begin: bs

    wire [width_p:0] opA_xnor;
    bsg_xnor#(.width_p(width_p+1)) xnor_opA 
        (.a_i({(width_p+1){opA_inv_lo}})
        ,.b_i(opA_r)
        ,.o  (opA_xnor)
        ); 

    wire [width_p:0] opB_xnor;
    bsg_xnor#(.width_p(width_p+1)) xnor_opB 
        (.a_i({(width_p+1){opB_inv_lo}})
        ,.b_i(opB_r)
        ,.o  (opB_xnor)
        ); 

    bsg_nor2 #(.width_p(width_p+1)) nor_opA 
       ( .a_i( opA_xnor )
        ,.b_i({(width_p+1){~opA_clr_lo}})
        ,.o  (add1_in0)
        );

    bsg_nor2 #(.width_p(width_p+1)) nor_opB 
       ( .a_i( opB_xnor )
        ,.b_i( {(width_p+1){~opB_clr_lo}})
        ,.o  (add1_in1)
        );
     
    if (bits_per_iter_p == 2) begin 
      bsg_xor#(.width_p(width_p+1)) xor_add1 
          (.a_i({(width_p+1){~add1_out[width_p]}})
          ,.b_i(opA_r)
          ,.o  (add2_in0)
          );
      assign add2_in1 = {add1_out[width_p-1:0], opC_r[width_p]};
    end
 
  end
  else begin: nbs
    assign add1_in0 = (opA_r ^ {width_p+1{opA_inv_lo}}) & {width_p+1{opA_clr_lo}};
    assign add1_in1 = (opB_r ^ {width_p+1{opB_inv_lo}}) & {width_p+1{opB_clr_lo}};
    
    if (bits_per_iter_p == 2) begin
      assign add2_in0 = (opA_r ^ {width_p+1{~add1_out[width_p]}});
      assign add2_in1 = {add1_out[width_p-1:0], opC_r[width_p]};
    end
			 
  end


  wire adder1_cin_lo;
  bsg_adder_cin #(.width_p(width_p+1)) adder1
   (.a_i  (add1_in0)
   ,.b_i  (add1_in1)
   ,.cin_i(adder1_cin_lo)
   ,.o    (add1_out)
   );

  if (bits_per_iter_p == 2) begin
    wire adder2_cin = ~add1_out[width_p];
    bsg_adder_cin #(.width_p(width_p+1)) adder2
     (.a_i  (add2_in0)
     ,.b_i  (add2_in1)
     ,.cin_i(adder2_cin)
     ,.o    (add2_out)
     );
  end
  else begin
    assign add2_out = '0;
  end
   
  bsg_idiv_iterative_controller #(.width_p(width_p), .bits_per_iter_p(bits_per_iter_p)) control 
     ( .reset_i                  (reset_i)
      ,.clk_i                    (clk_i)

      ,.v_i                      (v_i)
      ,.ready_and_o              (ready_and_o)

      ,.zero_divisor_i           (zero_divisor_li)
      ,.signed_div_r_i           (signed_div_r)
      ,.adder1_result_is_neg_i   (add1_out[width_p])
      ,.adder2_result_is_neg_i   (add2_out[width_p])
      ,.opA_is_neg_i             (opA_r[width_p])
      ,.opC_is_neg_i             (opC_r[width_p])

      ,.opA_sel_o                (opA_sel_lo)
      ,.opA_ld_o                 (opA_ld_lo)
      ,.opA_inv_o                (opA_inv_lo)
      ,.opA_clr_l_o              (opA_clr_lo)

      ,.opB_sel_o                (opB_sel_lo)
      ,.opB_ld_o                 (opB_ld_lo)
      ,.opB_inv_o                (opB_inv_lo)
      ,.opB_clr_l_o              (opB_clr_lo)

      ,.opC_sel_o                (opC_sel_lo)
      ,.opC_ld_o                 (opC_ld_lo)

      ,.latch_signed_div_o       (latch_signed_div_lo)
      ,.adder1_cin_o             (adder1_cin_lo)

      ,.v_o(v_o)
      ,.yumi_i(yumi_i)
     );
endmodule // divide
