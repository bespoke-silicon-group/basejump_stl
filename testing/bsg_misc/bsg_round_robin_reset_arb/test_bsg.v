`define INPUTS_P 4

/***************** TEST RATIONALE **********************
1. STATE SPACE
  
  The UUT is tested with every possible reqs_i. Each reqs_i
  is maintained for 2*INPUTS_P cycles and the grant_count,
  no. of times a given input line is granted, of each line
  is checked to verify the fairness of the arbitrer.

2. PARAMETERIZATION
  
  The no. of inputs is the parameter of this test module.
  A reasonable set of tests would include INPUTS_P = 1 2 3,
  to check corner cases, and INPUTS_P = 4 10, which include 
  a power of 2 and a non power of 2. 
********************************************************/

module test_bsg;
  
  localparam cycle_time_lp = 20; 
  localparam inputs_lp     = `INPUTS_P;
  localparam case_num_lp   = 4;
  
  // Clock and reset generation
  wire clk;
  wire reset;
  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_lp)
						  )  clock_gen
						  (  .o(clk)
						  );
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
						   , .reset_cycles_lo_p(1)
						   , .reset_cycles_hi_p(5)
						  )  reset_gen
						  (  .clk_i        (clk) 
						   , .async_reset_o(reset)
						  );

  initial
  begin
	  $display("\n\n\n");
	  $display("===========================================================");
	  $display("testing with ...");
	  $display("INPUTS_P: %d\n", inputs_lp);
  end

  logic test_input_ready;
  logic [inputs_lp-1:0] test_input_reqs_v     [case_num_lp];
  logic [inputs_lp-1:0] test_output_grants_v  [case_num_lp];

  logic [inputs_lp-1:0] test_input_reqs     ;
  logic [inputs_lp-1:0] test_output_grants;

  //assign the test cases
  initial begin
    test_input_reqs_v[ 0 ] =  4'b0000 ;  test_output_grants_v[ 0 ] = 4'b0000;
    test_input_reqs_v[ 1 ] =  4'b0100 ;  test_output_grants_v[ 1 ] = 4'b0100; //single request, 
    test_input_reqs_v[ 2 ] =  4'b1010 ;  test_output_grants_v[ 2 ] = 4'b1000; //
    test_input_reqs_v[ 3 ] =  4'b1110 ;  test_output_grants_v[ 3 ] = 4'b0010; //
  end
  
  integer case_num;
  // test input generation
  
  always_ff @(posedge clk) begin
    if(reset) begin
        case_num         <= 0;
        test_input_reqs  <= (inputs_lp)'(0);
        test_input_ready <= 1'b1;
    end else begin
        case_num         <= (case_num + 1)%case_num_lp ; 
        test_input_reqs  <= test_input_reqs_v [ ( case_num +1) % case_num_lp ];
    end
  end

  //instantiate the instance
  wire v;
  bsg_round_robin_arb #(.inputs_p(inputs_lp)
                       ,.reset_on_sr_p( 1'b1 )
                       ) UUT
                       ( .clk_i   (clk)
                        ,.reset_i (reset)

                        ,.grants_en_i (test_input_ready)

                        ,.reqs_i  (test_input_reqs)
                        ,.grants_o(test_output_grants)

		                ,.v_o   (v)
			            ,.tag_o ( )
		                ,.yumi_i(v)
                       );

  // check the result
  always_ff @(negedge clk) begin
    if(v) begin 
        $display("\n case num = %d, requests = %b", case_num, test_input_reqs ); if( test_output_grants_v [ case_num ]  == test_output_grants )
            $display("grants =%b, last_n=%b, last_r=%b, ==>Pass", test_output_grants, UUT.last_n, UUT.last_r);
        else
            $display("grants =%b, expect=%b, last_n=%b, last_r=%b,==>fail", test_output_grants,test_output_grants_v[ case_num ], UUT.last_n, UUT.last_r );
    end
  end

  // finish
  always@(negedge clk)
    if( case_num == (case_num_lp -1) ) begin
        $display("==========================================================");
        #20  $finish;
    end

endmodule

