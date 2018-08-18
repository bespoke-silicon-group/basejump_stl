/**
 *  testbench.v
 */

module testbench();
  
  logic clk, rst;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(2)
  ) clock_gen (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(1)
    ,.reset_cycles_hi_p(50)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(rst)
  );
 
  localparam test_mode_lp = 1;

if (test_mode_lp == 0) begin // FSB testing
 
  logic [31:0] trace_rom_addr;
  logic [79:0] trace_rom_data;

  logic tr_v_i;
  logic [79:0] tr_data_i;
  logic tr_ready_o;
  
  logic tr_v_o;
  logic [79:0] tr_data_o;
  logic tr_yumi_i;

  logic done_lo;
  logic error_lo;
 
  bsg_fsb_node_trace_replay #(
    .ring_width_p(76)
    ,.rom_addr_width_p(32)
  ) trace_replay (
    .clk_i(clk)
    ,.reset_i(rst)
    ,.en_i(1'b1)

    ,.v_i(tr_v_i)
    ,.data_i(tr_data_i[75:0])
    ,.ready_o(tr_ready_o)

    ,.v_o(tr_v_o)
    ,.data_o(tr_data_o[75:0])
    ,.yumi_i(tr_yumi_i)
    
    ,.rom_addr_o(trace_rom_addr)
    ,.rom_data_i(trace_rom_data)

    ,.done_o(done_lo)
    ,.error_o(error_lo)
  );

  assign tr_data_o[79:76] = 4'b0;

  bsg_trace_master_rom #(.width_p(80), .addr_width_p(32)) trace_rom (
    .addr_i(trace_rom_addr)
    ,.data_o(trace_rom_data)
  );

  logic node_v_o;
  logic [79:0] node_data_o [0:0];
  logic node_ready_i;

  logic node_en;
  logic node_rst;

  logic node_v_i;
  logic [79:0] node_data_i [0:0];
  logic node_yumi_o;
 
  bsg_fsb #(
    .width_p(80)
    ,.nodes_p(1)
    ,.snoop_vec_p(1'b0)
    ,.enabled_at_start_vec_p(1'b1)
  ) fsb (
    .clk_i(clk)
    ,.reset_i(rst)
   
    ,.asm_v_i(tr_v_o)
    ,.asm_data_i(tr_data_o)
    ,.asm_yumi_o(tr_yumi_i)
    
    ,.asm_v_o(tr_v_i)
    ,.asm_data_o(tr_data_i)
    ,.asm_ready_i(tr_ready_o)
    
    ,.node_v_o(node_v_o)
    ,.node_data_o(node_data_o)
    ,.node_ready_i(node_ready_i)
    
    ,.node_en_r_o(node_en)
    ,.node_reset_r_o(node_rst)

    ,.node_v_i(node_v_i)
    ,.node_data_i(node_data_i)
    ,.node_yumi_o(node_yumi_o)
  );

  bsg_test_node_client #(.id_p(1)) tnc (
    .clock_i(clk)
    ,.reset_i(node_rst)
    ,.en_i(node_en)

    ,.v_i(node_v_o)
    ,.data_i(node_data_o[0])
    ,.ready_o(node_ready_i)
    
    ,.v_o(node_v_i)
    ,.data_o(node_data_i[0])
    ,.yumi_i(node_yumi_o)  
  );

end
else if (test_mode_lp == 1) begin // manycore end-to-end testing
  logic finish_lo;
  mesh_top_cache #(
    .x_cord_width_p(2)
    ,.y_cord_width_p(2)
    ,.sets_p(2**8)
    ,.data_width_p(32)
    ,.dram_data_width_p(128)
    ,.mem_size_p(2**15) // in words
  ) mtop_cache (
    .clock_i(clk)
    ,.reset_i(rst)
    ,.finish_o(finish_lo)
  ); 

  initial begin
    wait(finish_lo);
    #(10);
    $display("********* FINISHED *********");
    $finish;
  end

end

endmodule
