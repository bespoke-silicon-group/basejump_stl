/**
 *  testbench.v
 */

module testbench();
  
  logic clk, rst, dmc_rst;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(10000)
  ) clock_gen (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(1)
    ,.reset_cycles_hi_p(100)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(rst)
  );
 
  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(1)
    ,.reset_cycles_hi_p(100)
  ) dmc_reset_gen (
    .clk_i(clk)
    ,.async_reset_o(dmc_rst)
  );

  localparam test_mode_lp = `TEST_MODE;

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

  bsg_test_node_client tnc (
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

  logic dfi_clk_2x;
  logic dfi_clk;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(5000)
  ) clk_gen_dfi_2x_inst (
    .o(dfi_clk_2x)
  );
  
  bsg_counter_clock_downsample #(
    .width_p(2)
  ) dfi_clk_ds (
    .clk_i(dfi_clk_2x)
    ,.reset_i(rst)
    ,.val_i(2'b0)
    ,.clk_r_o(dfi_clk)
  ); 


  logic finish_lo;
  bsg_dram_ctrl_if #(
    .addr_width_p(30)
    ,.data_width_p(128)
  ) dram_ctrl_if (
    .clk_i(clk)
  );

  mesh_top_cache #(
    .x_cord_width_p(2)
    ,.y_cord_width_p(2)
    ,.sets_p(2**5)
    ,.data_width_p(32)
    ,.dram_data_width_p(128)
    ,.mem_size_p(2**12) // in words
  ) mtop_cache (
    .clock_i(clk)
    ,.reset_i(rst)
    ,.dram_ctrl_if(dram_ctrl_if)
    ,.finish_o(finish_lo)
  );

localparam dmc = 1;
if (dmc == 1) begin
  localparam dfi_data_width_lp = 32;

  logic ddr_ck_p;
  logic ddr_ck_n;
  logic ddr_cke;
  logic [2:0] ddr_ba;
  logic [15:0] ddr_addr;
  logic ddr_cs_n;
  logic ddr_ras_n;
  logic ddr_cas_n;
  logic ddr_we_n;
  logic ddr_reset_n;
  logic ddr_odt;

  logic [(dfi_data_width_lp>>4)-1:0] dm_oe_n;
  logic [(dfi_data_width_lp>>4)-1:0] dm_o;
  logic [(dfi_data_width_lp>>4)-1:0] dqs_p_oe_n;
  logic [(dfi_data_width_lp>>4)-1:0] dqs_p_o;
  wire [(dfi_data_width_lp>>4)-1:0] dqs_p_i;
  logic [(dfi_data_width_lp>>4)-1:0] dqs_n_oe_n;
  logic [(dfi_data_width_lp>>4)-1:0] dqs_n_o;
  logic [(dfi_data_width_lp>>4)-1:0] dqs_n_i;
  logic [(dfi_data_width_lp>>1)-1:0] dq_oe_n;
  wire [(dfi_data_width_lp>>1)-1:0] dq_o;
  logic [(dfi_data_width_lp>>1)-1:0] dq_i;

  dmc #(
    .UI_ADDR_WIDTH(30)
    ,.UI_DATA_WIDTH(128)
    ,.DFI_DATA_WIDTH(dfi_data_width_lp)
  ) lpddr1_ctrl (

    .sys_rst(~dmc_rst) // active low!!!

    // user interface
    ,.app_addr(dram_ctrl_if.app_addr>>1) // short address!!!
    ,.app_cmd(dram_ctrl_if.app_cmd) 
    ,.app_en(dram_ctrl_if.app_en)
    ,.app_rdy(dram_ctrl_if.app_rdy)
    ,.app_wdf_wren(dram_ctrl_if.app_wdf_wren)
    ,.app_wdf_data(dram_ctrl_if.app_wdf_data)
    ,.app_wdf_mask(dram_ctrl_if.app_wdf_mask)
    ,.app_wdf_end(dram_ctrl_if.app_wdf_end)
    ,.app_wdf_rdy(dram_ctrl_if.app_wdf_rdy)
    ,.app_rd_data_valid(dram_ctrl_if.app_rd_data_valid)
    ,.app_rd_data(dram_ctrl_if.app_rd_data)
    ,.app_rd_data_end(dram_ctrl_if.app_rd_data_end)
    ,.app_ref_req(dram_ctrl_if.app_ref_req)
    ,.app_ref_ack(dram_ctrl_if.app_ref_ack)
    ,.app_zq_req(dram_ctrl_if.app_zq_req)
    ,.app_zq_ack(dram_ctrl_if.app_zq_ack)
    ,.app_sr_req(dram_ctrl_if.app_sr_req)
    ,.app_sr_active(dram_ctrl_if.app_sr_ack)
    ,.init_calib_complete(dram_ctrl_if.init_calib_complete)

    // DDR interface
    ,.ddr_ck_p(ddr_ck_p)
    ,.ddr_ck_n(ddr_ck_n)
    ,.ddr_cke(ddr_cke)
    ,.ddr_ba(ddr_ba)
    ,.ddr_addr(ddr_addr)
    ,.ddr_cs_n(ddr_cs_n)
    ,.ddr_ras_n(ddr_ras_n)
    ,.ddr_cas_n(ddr_cas_n)
    ,.ddr_we_n(ddr_we_n)
    ,.ddr_reset_n(ddr_reset_n)
    ,.ddr_odt(ddr_odt)
  
    ,.dm_oe_n(dm_oe_n)
    ,.dm_o(dm_o)
    ,.dqs_p_oe_n(dqs_p_oe_n)
    ,.dqs_p_o(dqs_p_o)
    ,.dqs_p_i(dqs_p_i)
    ,.dqs_n_oe_n(dqs_n_oe_n)
    ,.dqs_n_o(dqs_n_o)
    ,.dqs_n_i(dqs_n_i)
    ,.dq_oe_n(dq_oe_n)
    ,.dq_o(dq_o)
    ,.dq_i(dq_i)

    ,.ui_clk(clk)
    ,.ui_clk_sync_rst()
    ,.dfi_clk(dfi_clk)
    ,.dfi_clk_2x(dfi_clk_2x)
    ,.device_temp()
  );

  wire [15:0] dq_int;
  wire [1:0] dqs_int;
  
  genvar j; 
  for (j = 0; j < 16; j++) begin
    assign dq_int[j] = dq_oe_n[j] ? 1'bz : dq_o[j];
  end 

  assign dq_i = dq_int;

  for (j = 0; j < 2; j++) begin
    assign dqs_int[j] = dqs_p_oe_n[j] ? 1'bz : dqs_p_o[j];
  end

  assign dqs_p_i = dqs_int;
  
  mobile_ddr nonsynth_1024Mb_dram_model (
    .Clk(ddr_ck_p)
    ,.Clk_n(ddr_ck_n)
    ,.Cke(ddr_cke)
    ,.We_n(ddr_we_n)
    ,.Cs_n(ddr_cs_n)
    ,.Ras_n(ddr_ras_n)
    ,.Cas_n(ddr_cas_n)
    ,.Addr(ddr_addr[13:0])
    ,.Ba(ddr_ba[1:0])
    ,.Dq(dq_int)
    ,.Dqs(dqs_int)
    ,.Dm(dm_o)
  );
end 
else begin

  mock_dram_ctrl #(
    .addr_width_p(30)
    ,.data_width_p(128)
    ,.burst_len_p(1)
    ,.mem_size_p(2**14)
  ) mdc (
    .clock_i(clk)
    ,.reset_i(rst)
    ,.dram_ctrl_if(dram_ctrl_if)
  );
end
  

  initial begin
    wait(finish_lo);
    #(100000);
    $display("********* FINISHED *********");
    $finish;
  end

end

endmodule
