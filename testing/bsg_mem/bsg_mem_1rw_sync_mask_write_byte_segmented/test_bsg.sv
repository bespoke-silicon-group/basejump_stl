`define WIDTH_P 32
`define ELS_P   128
`define SEED_P  2559

`include "bsg_defines.sv"

module test_bsg
#(
  parameter width_p             = `WIDTH_P
  ,parameter els_p              = `ELS_P
  ,parameter seed_p             = `SEED_P
  ,parameter num_segments_p     =  4
  ,parameter latch_last_read_p  =  0
  ,parameter reset_cycles_lo_p  =  1
  ,parameter reset_cycles_hi_p  =  10
  ,localparam segment_width_lp  =  width_p/num_segments_p
	,localparam mask_width_lp     = segment_width_lp >>3
  ,localparam lg_els_lp         = `BSG_SAFE_CLOG2(els_p)
) 
( input wire clk,
  input wire [num_segments_p-1:0] v_i,
  input wire  w_i
) ;

  wire reset ;
  wire [num_segments_p-1:0][mask_width_lp-1:0] w_mask_i;
  wire [num_segments_p-1:0][segment_width_lp-1:0] test_input_data;
	wire [num_segments_p-1:0][segment_width_lp-1:0] actual_data;
  wire [lg_els_lp-1:0] test_input_addr ;
	wire [num_segments_p-1:0][segment_width_lp-1:0] expected_data;

  initial
  begin
    $display("===========================================================");
    $display("testing bsg_mem_1rw_sync_mask_write_byte_segmented with ...");
    $display("WIDTH_P       : %0d", width_p);
    $display("ELS_P         : %0d", els_p);
    $display("num_segments_p : %0d", num_segments_p);
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
  
  bsg_nonsynth_random_gen #(  .width_p(lg_els_lp>0?lg_els_lp:1)
                            , .seed_p (seed_p)
                           )  random_addr_gen
                           (  .clk_i  (clk)
                            , .reset_i(reset)
                            , .yumi_i (1'b1)
                            , .data_o (test_input_addr)
                           );

  bsg_mem_1rw_sync_mask_write_byte_segmented #( .width_p(width_p)
                                              , .els_p  (els_p)
                                              , .num_segments_p (num_segments_p)
                                              , .latch_last_read_p(latch_last_read_p)
                                            )  DUT
                                            ( .clk_i    (clk)
                                              , .reset_i(reset)
                                              , .data_i (test_input_data)
                                              , .w_mask_i(w_mask_i)
                                              , .addr_i (test_input_addr)
                                              , .v_i    (v_i)
                                              , .w_i    (w_i)
                                              , .data_o (actual_data)
                                            );

  //Reference Model
  bsg_mem_1rw_sync_mask_write_byte #(
                                    .data_width_p(segment_width_lp)
                                    ,.els_p(els_p)
                                    ,.latch_last_read_p(latch_last_read_p)
                                    ) 
                                     bank [num_segments_p-1:0]
                                    ( .clk_i(clk)
                                      ,.reset_i(reset)
                                      ,.v_i(v_i)
                                      ,.w_i(w_i)
                                      ,.addr_i(test_input_addr)
                                      ,.data_i(test_input_data)
                                      ,.write_mask_i(w_mask_i)
                                      ,.data_o(expected_data)
                                    );

  integer 	f = 0;

  initial 
    f = $fopen("output.log","w");

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------[LLR]---------------------------------------------------//

  always@(posedge clk) begin
    if (latch_last_read_p) begin
		  if (|v_i && !w_i) begin
		  	if(expected_data == actual_data)  
          $fdisplay(f,"[FOUND MATCH][LLR] At time %t --> expected_data : 0x%h | actual_data : 0x%h",$realtime,expected_data,actual_data);
		  	else 
          $error("\n[FOUND MISMATCH][LLR] At time %0t --> expected_data : 0x%0h | actual_data : 0x%0h",$realtime,expected_data,actual_data);
      end // (v_i && !w_i)
    end // (latch_last_read_p)
  end

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------[NO LLR]------------------------------------------------//

  logic [num_segments_p-1:0] read_en, read_en_r;
  
    for(genvar i=0; i<num_segments_p; i++) 
      assign read_en[i] = v_i[i] & ~w_i;

  logic [1:0] count;
  
  //The below block is use to write only at r_v_i+1 cycle when latch_last_read_p=0

  always @(posedge clk) begin
    if(|read_en) begin
      if (count<2) begin
        if(!read_en_r) begin
          read_en_r<=read_en;
          count<=count+1;
        end
        else
          read_en_r<=0;
          count<=count+1;
      end
    end
    else
      count<=0;
  end

  logic [num_segments_p-1:0][segment_width_lp-1:0] actual_data_lo;

  /*Since we are ORing the v_i while instantiating backing SRAM in the design, we tend to read an invalid segment when 
    latch_last_read_p=0. This will break our checker logic ending up with a simulation failure. When latch_last_read_p
    is 0, we will only check the valid portions of the output.*/

  for(genvar i=0; i<num_segments_p; i++) begin
    for(genvar j=0; j<segment_width_lp; j++) begin
      assign actual_data_lo[i][j] = (v_i[i])?actual_data[i][j]:expected_data[i][j];
    end
  end

  always@(posedge clk) begin 
    if(latch_last_read_p==0) begin
      if(|read_en_r)begin 
        if(expected_data == actual_data_lo)
          $fdisplay(f,"[FOUND MATCH][NO LLR] At time %t --> expected_data : 0x%h | actual_data : 0x%h",$realtime,expected_data,actual_data_lo);
        else
          $error("\n[FOUND MISMATCH][NO LLR] At time %0t --> expected_data : 0x%0h | actual_data : 0x%0h",$realtime,expected_data,actual_data);
      end
    end //(latch_last_read_p==0)
  end

  final 
    $display("\nSimulation Ended! You can see results in output.log\n"); 

endmodule
