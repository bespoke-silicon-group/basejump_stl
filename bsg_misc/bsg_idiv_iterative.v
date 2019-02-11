//====================================================================
// bsg_idiv_iterative.v
// 11/14/2016, shawnless.xie@gmail.com
//====================================================================
//
// An 32bit integer iterative divider, capable of signed & unsigned division
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
//    is useful for 32bit ISA, in which only quotient or remainder is need in
//    one instruction.
// 2. usging data detection logic to reduce the iteration cycles.
module bsg_idiv_iterative (
	 input           reset_i
	,input           clk_i

	,input           v_i      //there is a request
//	,output          yumi_o   //idiv has accept the request
    ,output          ready_o  //idiv is idle 

    ,input [31: 0]   dividend_i
	,input [31: 0]   divisor_i
	,input           signed_div_i

	,output          v_o      //result is valid
	,output [31: 0]  quotient_o
	,output [31: 0]  remainder_o
    ,input           yumi_i
    );


   wire [32:0] opA;
   bsg_buf #(.width_p(32)) remainder_buf (.i(opA[31:0]), .o(remainder_o));

   wire [32:0] opC;
   bsg_buf #(.width_p(32)) quotient_buf  (.i(opC[31:0]), .o(quotient_o));

   wire         signed_div_r;
   wire [31:0]  dividend_r;
   wire [31:0]  divisor_r;
   wire divisor_msb  = signed_div_r & divisor_r[31];
   wire dividend_msb = signed_div_r & dividend_r[31];

   wire latch_inputs;
   bsg_dff_en#(.width_p(1)) req_reg
       (.data_i (signed_div_i)
       ,.data_o (signed_div_r)
       ,.en_i   (latch_inputs)
       ,.clk_i(clk_i)
        );

   bsg_dff_en#(.width_p(32))dividend_reg
       (.data_i (dividend_i)
       ,.data_o (dividend_r)
       ,.en_i   (latch_inputs)
       ,.clk_i(clk_i)
       );

   bsg_dff_en#(.width_p(32))divisor_reg
       (.data_i (divisor_i)
       ,.data_o (divisor_r)
       ,.en_i   (latch_inputs)
       ,.clk_i(clk_i)
       );

   //if the divisor is zero
   wire         zero_divisor_li   =  ~(| divisor_r);

   wire         opA_sel;
   wire [32:0]  opA_mux;
   wire [32:0]  add_out;
   bsg_mux  #(.width_p(33), .els_p(2)) muxA
       (.data_i({ {divisor_msb, divisor_r}, add_out } )
       ,.data_o(opA_mux)
       ,.sel_i(opA_sel)
     );

   wire [2:0]   opB_sel;
   wire [32:0]  opB_mux;
   bsg_mux_one_hot #(.width_p(33), .els_p(3)) muxB
          ( .data_i( {opC, add_out, {add_out[31:0], opC[32]}} )
           ,.data_o(  opB_mux )
           ,.sel_one_hot_i(opB_sel)
     );

   wire [2:0]   opC_sel;
   wire [32:0]  opC_mux;
   bsg_mux_one_hot #(.width_p(33), .els_p(3)) muxC
          ( .data_i( {{dividend_msb, dividend_r},add_out, {opC[31:0], ~add_out[32]}} )
           ,.data_o(  opC_mux )
           ,.sel_one_hot_i(opC_sel)
     );

   wire opA_ld;
   bsg_dff_en#(.width_p(33)) opA_reg
       (.data_i (opA_mux)
       ,.data_o (opA    )
       ,.en_i   (opA_ld )
       ,.clk_i(clk_i)
       );
 
   wire         opB_ld;
   wire [32:0]  opB;
   bsg_dff_en#(.width_p(33)) opB_reg
       (.data_i (opB_mux)
       ,.data_o (opB    )
       ,.en_i   (opB_ld )
       ,.clk_i(clk_i)
       );

   wire opC_ld;
   bsg_dff_en#(.width_p(33)) opC_reg
       (.data_i (opC_mux)
       ,.data_o (opC    )
       ,.en_i   (opC_ld )
       ,.clk_i(clk_i)
       );
   // this logic is sandwiched between bitstacks -- MBT
   //   assign add_in0 = (opA ^ {33{opA_inv}}) & {33{opA_clr_l}};
   //   assign add_in1 = (opB ^ {33{opB_inv}}) & {33{opB_clr_l}};

  wire        opA_inv;
  wire [32:0] opA_inv_buf;
  bsg_buf_ctrl #(.width_p( 33)) buf_opA_inv( .i(opA_inv), .o(opA_inv_buf)) ;

  wire        opB_inv;
  wire [32:0] opB_inv_buf;
  bsg_buf_ctrl #(.width_p( 33)) buf_opB_inv( .i(opB_inv), .o(opB_inv_buf)) ;

  wire        opA_clr_l;
  wire [32:0] opA_clr_buf;
  bsg_buf_ctrl #(.width_p( 33)) buf_opA_clr( .i(~opA_clr_l), .o(opA_clr_buf)) ;

  wire        opB_clr_l;
  wire [32:0] opB_clr_buf;
  bsg_buf_ctrl #(.width_p( 33)) buf_opB_clr( .i(~opB_clr_l), .o(opB_clr_buf)) ;

  wire [32:0] opA_xnor;
  bsg_xnor#(.width_p(33)) xnor_opA 
        (.a_i(opA_inv_buf)
        ,.b_i(opA)
        ,.o  (opA_xnor)
        ); 

  wire [32:0] opB_xnor;
  bsg_xnor#(.width_p(33)) xnor_opB 
        (.a_i(opB_inv_buf)
        ,.b_i(opB)
        ,.o  (opB_xnor)
        ); 

  wire [32:0] add_in0;
  bsg_nor2 #(.width_p(33)) nor_opA 
       ( .a_i( opA_xnor )
        ,.b_i( opA_clr_buf)
        ,.o  (add_in0)
        );

  wire [32:0] add_in1;
  bsg_nor2 #(.width_p(33)) nor_opB 
       ( .a_i( opB_xnor )
        ,.b_i( opB_clr_buf)
        ,.o  (add_in1)
        );

  wire adder_cin;
  bsg_adder_cin #(.width_p(33)) adder
     (.a_i  (add_in0)
     ,.b_i  (add_in1)
     ,.cin_i(adder_cin)
     ,.o    (add_out)
     );

  bsg_idiv_iterative_controller control
     ( .reset_i                  (reset_i)
      ,.clk_i                    (clk_i)

      ,.v_i                      (v_i)
      ,.ready_o                  (ready_o)

      ,.zero_divisor_i           (zero_divisor_li)
      ,.signed_div_r_i           (signed_div_r)
      ,.adder_result_is_neg_i    (add_out[32])
      ,.opA_is_neg_i             (opA[32])
      ,.opC_is_neg_i             (opC[32])

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
