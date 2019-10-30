
module testbench
  import bsg_dmc_pkg::*;
  import bsg_cache_pkg::*;
  ();

parameter num_cache_p = 4;
parameter addr_width_p = 27;
parameter data_width_p = 32;
parameter block_size_in_words_p = 8;
parameter sets_p = 512;
parameter ways_p = `WAYS_P;

parameter ui_addr_width_p = 27;
parameter ui_data_width_p = 32;
parameter ui_burst_length_p = 8;
parameter dq_data_width_p = 32;

localparam burst_data_width_lp = ui_data_width_p * ui_burst_length_p;
localparam ui_mask_width_lp = ui_data_width_p >> 3;
localparam dq_group_lp = dq_data_width_p >> 3;
localparam dq_burst_length_lp = burst_data_width_lp / dq_data_width_p;

// clock and reset
//
logic clk, dfi_clk, dfi_clk_2x;
bsg_nonsynth_clock_gen #(
  .cycle_time_p(1000)
) ui_clock_gen (
  .o(clk)
);

bsg_nonsynth_clock_gen #(
  .cycle_time_p(5000)
) dfi_clock_gen (
  .o(dfi_clk)
);

bsg_nonsynth_clock_gen #(
  .cycle_time_p(2500)
) dfi_2x_clock_gen (
  .o(dfi_clk_2x)
);

logic reset;
bsg_nonsynth_reset_gen #(
  .reset_cycles_lo_p(8)
  ,.reset_cycles_hi_p(30)  
) reset_gen (
  .clk_i(clk)
  ,.async_reset_o(reset)
);

// test master
//
`declare_bsg_cache_dma_pkt_s(addr_width_p);
bsg_cache_dma_pkt_s [num_cache_p-1:0] dma_pkt;
logic [num_cache_p-1:0] dma_pkt_v_lo;
logic [num_cache_p-1:0] dma_pkt_yumi_li;

logic [num_cache_p-1:0][data_width_p-1:0] dma_data_li;
logic [num_cache_p-1:0] dma_data_v_li;
logic [num_cache_p-1:0] dma_data_ready_lo;

logic [num_cache_p-1:0][data_width_p-1:0] dma_data_lo;
logic [num_cache_p-1:0] dma_data_v_lo;
logic [num_cache_p-1:0] dma_data_yumi_li;

logic done_lo;

bsg_test_master #(
  .num_cache_p(num_cache_p)
  ,.addr_width_p(addr_width_p)
  ,.data_width_p(data_width_p)
  ,.block_size_in_words_p(block_size_in_words_p)
  ,.sets_p(sets_p)
  ,.ways_p(ways_p)
) test_master (
  .clk_i(clk)
  ,.reset_i(reset)

  ,.dma_pkt_o(dma_pkt)
  ,.dma_pkt_v_o(dma_pkt_v_lo)
  ,.dma_pkt_yumi_i(dma_pkt_yumi_li)

  ,.dma_data_i(dma_data_li)
  ,.dma_data_v_i(dma_data_v_li)
  ,.dma_data_ready_o(dma_data_ready_lo)

  ,.dma_data_o(dma_data_lo)
  ,.dma_data_v_o(dma_data_v_lo)
  ,.dma_data_yumi_i(dma_data_yumi_li) 
  
  ,.done_o(done_lo)
);


// DUT
//
logic [addr_width_p+2-1:0] app_addr;
logic [2:0] app_cmd;
logic app_en;
logic app_rdy;

logic app_wdf_wren;
logic [ui_data_width_p-1:0] app_wdf_data;
logic [ui_mask_width_lp-1:0] app_wdf_mask;
logic app_wdf_end;
logic app_wdf_rdy;

logic app_rd_data_valid;
logic [ui_data_width_p-1:0] app_rd_data;
logic app_rd_data_end;

bsg_cache_to_dram_ctrl #(
  .num_cache_p(num_cache_p)
  ,.addr_width_p(addr_width_p)
  ,.data_width_p(data_width_p)
  ,.block_size_in_words_p(block_size_in_words_p)

  ,.dram_ctrl_burst_len_p(ui_burst_length_p)
) DUT (
  .clk_i(clk)
  ,.reset_i(reset)
  ,.dram_size_i(3'h4)

  ,.dma_pkt_i(dma_pkt)
  ,.dma_pkt_v_i(dma_pkt_v_lo)
  ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

  ,.dma_data_o(dma_data_li)
  ,.dma_data_v_o(dma_data_v_li)
  ,.dma_data_ready_i(dma_data_ready_lo)

  ,.dma_data_i(dma_data_lo)
  ,.dma_data_v_i(dma_data_v_lo)
  ,.dma_data_yumi_o(dma_data_yumi_li) 
    
  ,.app_addr_o(app_addr)
  ,.app_cmd_o(app_cmd)
  ,.app_en_o(app_en)
  ,.app_rdy_i(app_rdy)

  ,.app_wdf_wren_o(app_wdf_wren)
  ,.app_wdf_data_o(app_wdf_data)
  ,.app_wdf_mask_o(app_wdf_mask)
  ,.app_wdf_end_o(app_wdf_end)
  ,.app_wdf_rdy_i(app_wdf_rdy)

  ,.app_rd_data_valid_i(app_rd_data_valid)
  ,.app_rd_data_i(app_rd_data)
  ,.app_rd_data_end_i(app_rd_data_end)

);

// DMC
//
bsg_dmc_s dmc_p;
assign dmc_p.trefi = 16'd1023;
assign dmc_p.tmrd = 4'd1;
assign dmc_p.trfc = 4'd15;
assign dmc_p.trc = 4'd10;
assign dmc_p.trp = 4'd2;
assign dmc_p.tras = 4'd7;
assign dmc_p.trrd = 4'd1;
assign dmc_p.trcd = 4'd2;
assign dmc_p.twr = 4'd7;
assign dmc_p.twtr = 4'd7;
assign dmc_p.trtp = 4'd3;
assign dmc_p.tcas = 4'd3;
assign dmc_p.col_width = 4'd11;
assign dmc_p.row_width = 4'd14;
assign dmc_p.bank_width = 2'd2;
assign dmc_p.dqs_sel_cal = 2'd3;
assign dmc_p.init_cmd_cnt = 4'd5;

wire ddr_ck_p;
wire ddr_ck_n;
wire ddr_cke;
wire ddr_cs_n;
wire ddr_ras_n;
wire ddr_cas_n;
wire ddr_we_n;
wire [2:0] ddr_ba;
wire [15:0] ddr_addr;

wire [(dq_data_width_p>>3)-1:0] ddr_dm_oen_lo;
wire [(dq_data_width_p>>3)-1:0] ddr_dm_lo;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_p_oen_lo;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_p_ien_lo;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_p_lo;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_p_li;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_n_oen_lo;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_n_ien_lo;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_n_lo;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_n_li;
wire [dq_data_width_p-1:0] ddr_dq_oen_lo;
wire [dq_data_width_p-1:0] ddr_dq_lo;
wire [dq_data_width_p-1:0] ddr_dq_li;
  
wire [(dq_data_width_p>>3)-1:0] ddr_dm;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_p;
wire [(dq_data_width_p>>3)-1:0] ddr_dqs_n;
wire [dq_data_width_p-1:0] ddr_dq;

bsg_dmc #(
  .ui_addr_width_p(ui_addr_width_p)
  ,.ui_data_width_p(ui_data_width_p)
  ,.burst_data_width_p(burst_data_width_lp)
  ,.dq_data_width_p(dq_data_width_p)
) dmc (
  .dmc_p_i(dmc_p)
  ,.sys_rst_i(reset)

  ,.app_addr_i(app_addr[2+:ui_addr_width_p]) // word address
  ,.app_cmd_i(app_cmd)
  ,.app_en_i(app_en)
  ,.app_rdy_o(app_rdy)

  ,.app_wdf_wren_i(app_wdf_wren)
  ,.app_wdf_data_i(app_wdf_data)
  ,.app_wdf_mask_i(app_wdf_mask)
  ,.app_wdf_end_i(app_wdf_end)
  ,.app_wdf_rdy_o(app_wdf_rdy)

  ,.app_rd_data_valid_o(app_rd_data_valid)
  ,.app_rd_data_o(app_rd_data)
  ,.app_rd_data_end_o(app_rd_data_end)

  ,.app_ref_req_i(1'b0)
  ,.app_ref_ack_o()
  ,.app_zq_req_i(1'b0)
  ,.app_zq_ack_o()
  ,.app_sr_req_i(1'b0)
  ,.app_sr_active_o()

  ,.init_calib_complete_o()

  ,.ddr_ck_p_o(ddr_ck_p)
  ,.ddr_ck_n_o(ddr_ck_n)
  ,.ddr_cke_o(ddr_cke)
  ,.ddr_ba_o(ddr_ba)
  ,.ddr_addr_o(ddr_addr)
  ,.ddr_cs_n_o(ddr_cs_n)
  ,.ddr_ras_n_o(ddr_ras_n)
  ,.ddr_cas_n_o(ddr_cas_n)
  ,.ddr_we_n_o(ddr_we_n)
  ,.ddr_reset_n_o()
  ,.ddr_odt_o()

  ,.ddr_dm_oen_o(ddr_dm_oen_lo)
  ,.ddr_dm_o(ddr_dm_lo)
  ,.ddr_dqs_p_oen_o(ddr_dqs_p_oen_lo)
  ,.ddr_dqs_p_ien_o(ddr_dqs_p_ien_lo)
  ,.ddr_dqs_p_o(ddr_dqs_p_lo)
  ,.ddr_dqs_p_i(ddr_dqs_p_li)

  ,.ddr_dqs_n_oen_o()
  ,.ddr_dqs_n_ien_o()
  ,.ddr_dqs_n_o()
  ,.ddr_dqs_n_i()

  ,.ddr_dq_oen_o(ddr_dq_oen_lo)
  ,.ddr_dq_o(ddr_dq_lo)
  ,.ddr_dq_i(ddr_dq_li)

  ,.ui_clk_i(clk)

  ,.dfi_clk_2x_i(~dfi_clk_2x) 
  ,.dfi_clk_i(dfi_clk)

  ,.ui_clk_sync_rst_o()
  ,.device_temp_o()
);

for (genvar i = 0; i< dq_group_lp; i++) begin
  assign ddr_dm[i] = ddr_dm_oen_lo[i] ? 1'bz : ddr_dm_lo[i];
  assign ddr_dqs_p[i] = ddr_dqs_p_oen_lo[i] ? 1'bz : ddr_dqs_p_lo[i];
  assign ddr_dqs_p_li[i] = ddr_dqs_p_ien_lo[i] ? 1'b1 : ddr_dqs_p[i];
end

for (genvar i = 0; i < dq_data_width_p; i++) begin
  assign ddr_dq[i] = ddr_dq_oen_lo[i] ? 1'bz : ddr_dq_lo[i];
  assign ddr_dq_li[i] = ddr_dq[i];
end

// DDR MODEL
//

for (genvar i = 0; i < 2; i++) begin
  mobile_ddr mobile_ddr_inst (
    .Dq(ddr_dq[16*i+:16])
    ,.Dqs(ddr_dqs_p[2*i+:2])
    ,.Addr(ddr_addr[13:0])
    ,.Ba(ddr_ba[1:0])
    ,.Clk(ddr_ck_p)
    ,.Clk_n(ddr_ck_n)
    ,.Cke(ddr_cke)
    ,.Cs_n(ddr_cs_n)
    ,.Ras_n(ddr_ras_n)
    ,.Cas_n(ddr_cas_n)
    ,.We_n(ddr_we_n)
    ,.Dm(ddr_dm[2*i+:2])
  );
end

initial begin
  wait(done_lo);
  $display("###### FINISH ######");
  //for (integer i = 0; i < 5000000; i++) begin
  //  @(posedge clk);
  //end
  $finish;
end

endmodule
