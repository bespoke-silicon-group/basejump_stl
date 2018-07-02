`define WIDTH_P 3
`define ELS_P   4
`define SEED_P  100

/**************************** TEST RATIONALE *******************************

1. STATE SPACE

  All the elements are in memory are written once and the first $clog2(`ELS_P)
  elements are re-written with w_v_i kept LOW to check if those elements are
  overwritten.

2. PARAMETERIZATION

  The synthesis of the design is not much influenced by data width WIDTH_P.
  But the parameter ELS_P be varied to include different cases, powers of 2 
  and non power of 2 for example. SEED_P may be varied to generated different 
  streams of random numbers that are written to the test memory. So a minimum
  set of tests might be WIDTH_P=1,4,5 and ELS_P=1,2,3,4,5,8.

***************************************************************************/

module test_bsg;
   
  localparam cycle_time_lp = 20;
  localparam width_lp      = `WIDTH_P; // width of test input
  localparam els_lp        = `ELS_P;
  localparam addr_width_lp = `BSG_SAFE_CLOG2(`ELS_P);
  localparam seed_lp       = `SEED_P;
  
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
  initial
  begin
    /*$monitor("\n@%0t ps: ", $time
             , "test_input_wdata:%b || test_input_waddr:%b || test_input_wv:%b" 
             , test_input_wdata, test_input_waddr, test_input_wv
             , " || test_input_raddr:%b || test_output_rdata:%b"
             , test_input_raddr, test_output_rdata
            );*/

    $display("\n\n\n");
    $display("===========================================================");
    $display("testing bsg_mem_1r1w with ...");
    $display("WIDTH_P: %d", width_lp);
    $display("ELS_P  : %d\n", els_lp);
  end

  logic [width_lp-1:0]      test_input_wdata, test_input_wdata_r; 
  logic [width_lp-1:0]      test_output_rdata;
  logic [addr_width_lp-1:0] test_input_waddr, test_input_raddr;
  logic                     test_input_wv;  
  
  // stores some inputs 
  logic [addr_width_lp-1:0] [width_lp-1:0] test_inputs;

  logic [addr_width_lp:0] count;
  logic finish_r;

  bsg_cycle_counter #(  .width_p   (addr_width_lp+1)
                      , .init_val_p(0)
                     )  counter
                     (  .clk_i    (clk)
                      , .reset_i(reset)
                      , .ctr_r_o(count)
                     );

  bsg_nonsynth_random_gen #(  .width_p(width_lp)
                            , .seed_p (seed_lp)
                           )  random_gen
                           (  .clk_i  (clk)
                            , .reset_i(reset)
                            , .yumi_i (1'b1)
                            , .data_o (test_input_wdata)
                           );

  always_ff @(posedge clk)
  begin
    test_input_wdata_r <= test_input_wdata;
    
    if(reset)
      begin
        test_input_waddr <= addr_width_lp'(0);
        test_input_raddr <= addr_width_lp'(0);
        test_input_wv    <= 1'b1;
        finish_r         <= 1'b0;
      end
    else
      begin
        test_input_waddr <= (test_input_waddr + 1) % els_lp;
        test_input_raddr <= test_input_waddr;
        
        if(count < (els_lp - 1)) // entire mem. is written once
          begin
            if(count < addr_width_lp) 
              // keeps track of initial addr_width_lp values being written
              test_inputs[test_input_waddr] <= test_input_wdata;
          end
        else
          test_input_wv <= 1'b0; // w_v_i is tested in the next round 

        if(count == ((els_lp - 1) + addr_width_lp + 1))
          finish_r <= 1'b1;  
        if(finish_r)
          begin
            $display("=========================================================\n");
            $finish;
          end
      end
  end

  always_ff @(posedge clk)
  begin
    if(!reset)
      if(count <= els_lp)
        // checks if data is not being written correctly
        assert(test_output_rdata == test_input_wdata_r) 
          else $error("mismatch on reading the address: %x\n", test_input_raddr);
      else
        // checks if data is overwritten when w_v_i is asserted
        if(addr_width_lp > 1) // does not work with els_lp=1 i.e., one mem. element 
          assert(test_output_rdata == test_inputs[test_input_raddr]) 
            else $error("data may be overwritten when w_v_i is low at %x\n"
                        , test_input_raddr);
  end

  bsg_mem_1r1w #(  .width_p               (width_lp)
                 , .els_p                 (els_lp)
                 , .read_write_same_addr_p(1)
                 , .addr_width_lp         ()
                )  DUT
                (  .w_clk_i  (clk)
                 , .w_reset_i(reset)
                 , .w_v_i    (test_input_wv)
                 , .w_addr_i (test_input_waddr)
                 , .w_data_i (test_input_wdata)
                 , .r_v_i    (1'b1)
                 , .r_addr_i (test_input_raddr)
                 , .r_data_o (test_output_rdata)
                );

endmodule

