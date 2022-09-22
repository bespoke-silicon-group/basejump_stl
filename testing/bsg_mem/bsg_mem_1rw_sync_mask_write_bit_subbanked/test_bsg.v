`define WIDTH_P 4
`define ELS_P   8
`define SEED_P  10000

`include "bsg_defines.v"

module test_bsg
#(
  parameter width_p            = `WIDTH_P
  ,parameter els_p             = `ELS_P
  ,parameter seed_p            = `SEED_P
  ,parameter num_subbank_p     =  1
  ,parameter reset_cycles_lo_p =  1
  ,parameter reset_cycles_hi_p =  10
) 
( input wire clk,
  input wire v_i,
  input wire w_i
) ;

  wire reset ;
  logic [width_p-1:0] w_mask_i;
  wire [width_p-1:0] data_o; 
  wire [width_p-1:0] test_input_data;
  wire [`BSG_SAFE_CLOG2(els_p)-1:0] test_input_addr;
  
  initial
  begin
    $display("\n");
    $display("===========================================================");
    $display("At time : %0t",$realtime);
    $display("\n");
    $display("testing bsg_mem_1rw_sync_mask_write_bit_subbanked with ...");
    $display("WIDTH_P       : %0d", width_p);
    $display("ELS_P         : %0d", els_p);
    $display("NUM_SUBBANK_P : %0d", num_subbank_p);
  end

  assign w_mask_i = 32'h1;

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          );

  // random test data generation; 
  // generates a new random number after every +ve clock edge
  bsg_nonsynth_random_gen #(  .width_p(width_p)
                            , .seed_p (seed_p)
                           )  random_data_gen
                           (  .clk_i  (clk)
                            , .reset_i(reset)
                            , .yumi_i (1'b1)
                            , .data_o (test_input_data)
                           );
  
  bsg_nonsynth_random_gen #(  .width_p(`BSG_SAFE_CLOG2(els_p))
                            , .seed_p (seed_p)
                           )  random_addr_gen
                           (  .clk_i  (clk)
                            , .reset_i(reset)
                            , .yumi_i (1'b1)
                            , .data_o (test_input_addr)
                           );

  bsg_mem_1rw_sync_mask_write_bit_subbanked #( .width_p(width_p)
                                               , .els_p  (els_p)
                                               , .num_subbank_p (num_subbank_p)
                                             ) DUT
                                             (  .clk_i    (clk)
                                                , .reset_i(reset)
                                                , .data_i (test_input_data)
                                                , .w_mask_i(w_mask_i)
                                                , .addr_i (test_input_addr)
                                                , .v_i    (v_i)
                                                , .w_i    (w_i)
                                                , .data_o (data_o)
                                             );

endmodule
