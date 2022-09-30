`define WIDTH_P 32
`define ELS_P   16
`define SEED_P  10000

`include "bsg_defines.v"

module test_bsg
#(
  parameter width_p             = `WIDTH_P
  ,parameter els_p              = `ELS_P
  ,parameter seed_p             = `SEED_P
  ,parameter num_subbank_p      =  2
  ,parameter latch_last_read_p  =  1
  ,parameter reset_cycles_lo_p  =  1
  ,parameter reset_cycles_hi_p  =  10
  ,parameter mask_granularity_p =  1
  ,localparam subbank_width_lp  =  width_p/num_subbank_p
  ,localparam mask_width_lp     =  subbank_width_lp/mask_granularity_p
  ,localparam els_lp            = `BSG_SAFE_CLOG2(els_p)
) 
( input wire clk,
  input wire [num_subbank_p-1:0] v_i,
  input wire [num_subbank_p-1:0] w_i
) ;

  wire reset ;
  wire [num_subbank_p-1:0][mask_width_lp-1:0] w_mask_i;
  wire [num_subbank_p-1:0][subbank_width_lp-1:0] test_input_data;
	wire [num_subbank_p-1:0][subbank_width_lp-1:0] actual_data;
  wire [els_lp-1:0] test_input_addr ;
	wire [num_subbank_p-1:0][subbank_width_lp-1:0] expected_data;

  initial
  begin
    $display("===========================================================");
    $display("testing bsg_mem_1rw_sync_mask_write_bit_subbanked with ...");
    $display("WIDTH_P       : %0d", width_p);
    $display("ELS_P         : %0d", els_p);
    $display("NUM_SUBBANK_P : %0d", num_subbank_p);
  end

  assign w_mask_i = 32'hffffffff;

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
  
  bsg_nonsynth_random_gen #(  .width_p(els_lp)
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
                                            )  DUT
                                            ( .clk_i    (clk)
                                              , .reset_i(reset)
                                              , .data_i (test_input_data)
                                              , .w_mask_i(w_mask_i)
                                              , .addr_i (test_input_addr)
                                              , .v_i    (|v_i)
                                              , .w_i    (|w_i)
                                              , .data_o (actual_data)
                                            );

  //Reference Model
  bsg_mem_1rw_sync_mask_write_bit #(
                                    .width_p(subbank_width_lp)
                                    ,.els_p(els_p)
                                  ) 
                                   bank [num_subbank_p-1:0]
                                  ( .clk_i(clk)
                                    ,.reset_i(reset)
                                    ,.v_i(v_i)
                                    ,.w_i(w_i)
                                    ,.addr_i(test_input_addr)
                                    ,.data_i(test_input_data)
                                    ,.w_mask_i(w_mask_i)
                                    ,.data_o(expected_data)
                                  );

  always@(posedge clk) begin
		if (v_i && !w_i) begin
			if(expected_data == actual_data)  
        $fdisplay(f,"[FOUND MATCH] At time %t --> expected_data : 0x%h | actual_data : 0x%h",$realtime,expected_data,actual_data);
			else 
        $error("\n[FOUND MISMATCH] At time %0t --> expected_data : 0x%0h | actual_data : 0x%0h",$realtime,expected_data,actual_data);
    end
  end

  integer 	f = 0;

  initial 
    f = $fopen("output.log","w");

  final 
    $display("\nSimulation Ended! You can see results in output.log\n"); 

endmodule
