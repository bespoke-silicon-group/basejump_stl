`define WIDTH_P 3
`define ELS_P   4
`define SEED_P  1000

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  All the elements in the memory are written once and the first ELS_P/4
  elements are re-written with w_v_i kept LOW to check if those elements are
  overwritten.

2. PARAMETERIZATION

  The synthesis of the design is not much influenced by data width WIDTH_P.
  But the parameter ELS_P must be varied to include different cases, powers of 2 
  and non power of 2 for example. SEED_P may be varied to generate different 
  streams of random numbers that are written into the memory. A minimum
  set of tests might be WIDTH_P=1,4,5 and ELS_P=1,2,3,4,5,8.

***************************************************************************/

module test_bsg;
  
  localparam width_lp      = `WIDTH_P;
  localparam els_lp        = `ELS_P;
  localparam addr_width_lp = `BSG_SAFE_CLOG2(`ELS_P);
  
  localparam cycle_time_lp = 20;
  localparam seed_lp       = `SEED_P;
  
  initial
  begin
    $display("\n");
    $display("testing bsg_mem_2r1w with ...");
    $display("WIDTH_P: %0d", width_lp);
    $display("ELS_P:   %0d", els_lp);
    /*$monitor("count: %0d", count
             , " w_addr_i: %b", test_input_wdata
             , " w_addr_i: %b", test_input_waddr
             , " w_v_i: %b", test_input_wv
             , " r0_data_o: %b", test_output_rdata0
             , " r1_data_o: %b", test_output_rdata1
            );*/
  end

  // clock and reset generation
  wire clk;
  wire reset;
  
  bsg_nonsynth_clock_gen #( .cycle_time_p(cycle_time_lp)
                          ) clock_gen
                          ( .o(clk)
                          );
    
  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(1)
                           , .reset_cycles_hi_p(5)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          );

  logic [width_lp-1:0]      test_input_wdata, test_output_rdata0, test_output_rdata1;
  logic [addr_width_lp-1:0] test_input_waddr, test_input_raddr0, test_input_raddr1;
  logic                     test_input_wv;

  bsg_mem_2r1w #(  .width_p               (width_lp)
                 , .els_p                 (els_lp)
                 , .read_write_same_addr_p(1)
                )  DUT
                (  .w_clk_i  (clk)
                 , .w_reset_i(reset)
                 , .w_v_i    (test_input_wv)
                 , .w_addr_i (test_input_waddr)
                 , .w_data_i (test_input_wdata)
                 , .r0_addr_i(test_input_raddr0)
                 , .r0_v_i   (1'b1)
                 , .r1_addr_i(test_input_raddr1)
                 , .r1_v_i   (1'b1)
                 , .r0_data_o(test_output_rdata0)
                 , .r1_data_o(test_output_rdata1)
                );
  
  // random test data generation; 
  // generates a new random number after every +ve clock edge
  bsg_nonsynth_random_gen #(  .width_p(width_lp)
                            , .seed_p (seed_lp)
                           )  random_gen
                           (  .clk_i  (clk)
                            , .reset_i(reset)
                            , .yumi_i (1'b1)
                            , .data_o (test_input_wdata)
                           );

  logic [addr_width_lp:0] count; // no. of cycles after reset
  logic [width_lp-1:0] prev_input, prev_input_r; // 2 previous data inputs
  logic [(els_lp/4):0][width_lp-1:0] temp; // stores inital (els_lp/4)+1 values
                                           // written in first pass for verification
                                           // in second pass
  logic finish_r;
  
  always_ff @(posedge clk)
  begin
    if(reset)
      begin
        test_input_wv     <= 1'b1;
        test_input_waddr  <= addr_width_lp'(0);
        test_input_raddr0 <= addr_width_lp'(0);
        test_input_raddr1 <= (els_lp >= 2)? {addr_width_lp'(0), 1'b1}:0;
        prev_input        <= width_lp'(0);
        count             <= 0;
        finish_r          <= 1'b0;
      end
    else
      begin
        if(count == els_lp+(els_lp/4)+1)
          finish_r <= 1'b1;
        if(finish_r)
          $finish;
        
        if(count >= 2)
          begin
            test_input_raddr0 <= (test_input_raddr0 + 1) % els_lp;
            test_input_raddr1 <= (test_input_raddr1 + 1) % els_lp;
          end
        if(count <= (els_lp/4))
          begin
            temp[count] <= test_input_wdata;
          end
        if(count >= (els_lp-1))
          begin
            test_input_wv <= 1'b0;
          end
        
        count <= (count + 1);
        test_input_waddr <= (test_input_waddr + 1) % els_lp;
        prev_input   <= test_input_wdata;
        prev_input_r <= prev_input;
      end
  end

  always_ff @(posedge clk)
  begin
    if(count>=2 && count<=els_lp)
      begin
        assert(test_output_rdata1 == prev_input)
          else $error("error in reading address: %b", test_input_raddr1);
        assert(test_output_rdata0 == prev_input_r)
          else $error("error in reading address: %b", test_input_raddr0);
      end
    if(count == els_lp+1)
      begin
        assert(test_output_rdata1 == temp[test_input_raddr1])
          else $error("error in reading address: %b", test_input_raddr1);
        assert(test_output_rdata0 == prev_input_r)
          else $error("error in reading address: %b", test_input_raddr0);
      end
    if(count > els_lp+1)
      begin
        assert(test_output_rdata1 == temp[test_input_raddr1])
          else $error("error in reading address: %b", test_input_raddr1);
        assert(test_output_rdata0 == temp[test_input_raddr0])
          else $error("error in reading address: %b", test_input_raddr0);
      end
  end
endmodule
