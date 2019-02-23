/**
 *  testbench.v
 */

`include "bsg_manycore_packet.vh"
`include "bsg_cache_dma_pkt.vh"
`include "bsg_cache_pkt.vh"

module testbench();
  import bsg_dram_ctrl_pkg::*;

  // parameters
  //
  parameter num_test_word_p = 2**14;
  parameter link_addr_width_p = 24; 
  parameter cache_addr_width_lp = link_addr_width_p+2-1;

  parameter num_cache_p = 4;
  parameter data_width_p = 32;
  parameter sets_p = 512;
  parameter ways_p = 2;
  parameter block_size_in_words_p = 8;

  parameter dram_ctrl_burst_len_p = 1;
  parameter dram_ctrl_data_width_p = 128;

  parameter dfi_data_width_p = 32;
  
  parameter x_cord_width_p = `BSG_SAFE_CLOG2(num_cache_p);
  parameter y_cord_width_p = 1;
  parameter load_id_width_p = 11;

  parameter link_sif_width_lp =
    `bsg_manycore_link_sif_width(link_addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p,load_id_width_p);

  // clock and reset
  //
  logic clk, reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) clock_gen (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(0)
    ,.reset_cycles_hi_p(4)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  logic dfi_clk_2x, dfi_clk;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(4000)
  ) dfi_clock_gen (
    .o(dfi_clk_2x)
  );

  bsg_counter_clock_downsample #(
    .width_p(2)
  ) dfi_clk_ds (
    .clk_i(dfi_clk_2x)
    ,.reset_i(reset)
    ,.val_i(2'b0)
    ,.clk_r_o(dfi_clk)
  );

  // network
  //
  logic [num_cache_p-1:0][bsg_noc_pkg::S:bsg_noc_pkg::W][link_sif_width_lp-1:0] router_link_sif_li, router_link_sif_lo;
  logic [num_cache_p-1:0][link_sif_width_lp-1:0] proc_link_sif_li, proc_link_sif_lo;

  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_manycore_mesh_node #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.data_width_p(data_width_p)
      ,.addr_width_p(link_addr_width_p)
      ,.load_id_width_p(load_id_width_p)
    ) mesh_node (
      .clk_i(clk)
      ,.reset_i(reset)
      ,.links_sif_i(router_link_sif_li[i])
      ,.links_sif_o(router_link_sif_lo[i])
      ,.proc_link_sif_i(proc_link_sif_li[i])
      ,.proc_link_sif_o(proc_link_sif_lo[i])
      ,.my_x_i(x_cord_width_p'(i))
      ,.my_y_i(y_cord_width_p'(0))
    );

    if (i != 0) begin
      assign router_link_sif_li[i][bsg_noc_pkg::W] = router_link_sif_lo[i-1][bsg_noc_pkg::E];
    end

    if (i != num_cache_p-1) begin
      assign router_link_sif_li[i][bsg_noc_pkg::E] = router_link_sif_lo[i+1][bsg_noc_pkg::W];
    end

    // tieoff
    if (i == 0) begin
      bsg_manycore_link_sif_tieoff #(
        .addr_width_p(link_addr_width_p)
        ,.data_width_p(data_width_p)
        ,.load_id_width_p(load_id_width_p)
        ,.x_cord_width_p(x_cord_width_p)
        ,.y_cord_width_p(y_cord_width_p)
      ) node_w_tieoff (
        .clk_i(clk)
        ,.reset_i(reset)
    
        ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::W])
        ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::W])
      );
    end

    bsg_manycore_link_sif_tieoff #(
      .addr_width_p(link_addr_width_p)
      ,.data_width_p(data_width_p)
      ,.load_id_width_p(load_id_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
    ) node_n_tieoff (
      .clk_i(clk)
      ,.reset_i(reset)
    
      ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::N])
      ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::N])
    );

    if (i == num_cache_p-1) begin
      bsg_manycore_link_sif_tieoff #(
        .addr_width_p(link_addr_width_p)
        ,.data_width_p(data_width_p)
        ,.load_id_width_p(load_id_width_p)
        ,.x_cord_width_p(x_cord_width_p)
        ,.y_cord_width_p(y_cord_width_p)
      ) node_e_tieoff (
        .clk_i(clk)
        ,.reset_i(reset)
    
        ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::E])
        ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::E])
      );
    end
  end

  // master nodes
  //
  logic [num_cache_p-1:0] done_lo;  

  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_test_node_master #(
      .id_p(i)
      ,.link_addr_width_p(link_addr_width_p)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.sets_p(sets_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.load_id_width_p(load_id_width_p)
      ,.num_test_word_p(num_test_word_p)
    ) master (
      .clk_i(clk)
      ,.reset_i(reset)
    
      ,.link_sif_i(proc_link_sif_lo[i])
      ,.link_sif_o(proc_link_sif_li[i]) 
    
      ,.done_o(done_lo[i])
    );
  end

  // manycore link to cache
  //
  `declare_bsg_cache_pkt_s(cache_addr_width_lp, data_width_p);
  bsg_cache_pkt_s [num_cache_p-1:0] cache_pkt;
  logic [num_cache_p-1:0] link_to_cache_v_lo;
  logic [num_cache_p-1:0] link_to_cache_ready_li;
  logic [num_cache_p-1:0][data_width_p-1:0] link_to_cache_data_li;
  logic [num_cache_p-1:0] link_to_cache_v_li;
  logic [num_cache_p-1:0] link_to_cache_yumi_lo;

  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_manycore_link_to_cache #(
      .link_addr_width_p(link_addr_width_p)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.load_id_width_p(load_id_width_p)
      ,.sets_p(sets_p)
      ,.ways_p(ways_p)
      ,.block_size_in_words_p(block_size_in_words_p)
    ) manycore_link_to_cache (
      .clk_i(clk)
      ,.reset_i(reset)

      ,.my_x_i((x_cord_width_p)'(i))
      ,.my_y_i((y_cord_width_p)'(1))
      ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::S])
      ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::S])

      ,.cache_pkt_o(cache_pkt[i])
      ,.v_o(link_to_cache_v_lo[i])
      ,.ready_i(link_to_cache_ready_li[i])

      ,.data_i(link_to_cache_data_li[i])
      ,.v_i(link_to_cache_v_li[i])
      ,.yumi_o(link_to_cache_yumi_lo[i])
    ); 
  end


  // cache
  //
  `declare_bsg_cache_dma_pkt_s(cache_addr_width_lp);
  bsg_cache_dma_pkt_s [num_cache_p-1:0] dma_pkt;
  logic [num_cache_p-1:0] dma_pkt_v_lo;
  logic [num_cache_p-1:0] dma_pkt_yumi_li;

  logic [num_cache_p-1:0][data_width_p-1:0] dma_data_li;
  logic [num_cache_p-1:0] dma_data_v_li;
  logic [num_cache_p-1:0] dma_data_ready_lo;
  
  logic [num_cache_p-1:0][data_width_p-1:0] dma_data_lo;
  logic [num_cache_p-1:0] dma_data_v_lo;
  logic [num_cache_p-1:0] dma_data_yumi_li;

  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_cache #(
      .addr_width_p(cache_addr_width_lp)
      ,.data_width_p(data_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.sets_p(sets_p)
    ) cache (
      .clk_i(clk)
      ,.reset_i(reset)

      ,.cache_pkt_i(cache_pkt[i])
      ,.v_i(link_to_cache_v_lo[i])
      ,.ready_o(link_to_cache_ready_li[i])

      ,.data_o(link_to_cache_data_li[i])
      ,.v_o(link_to_cache_v_li[i])
      ,.yumi_i(link_to_cache_yumi_lo[i])
  
      ,.dma_pkt_o(dma_pkt[i])
      ,.dma_pkt_v_o(dma_pkt_v_lo[i])
      ,.dma_pkt_yumi_i(dma_pkt_yumi_li[i])

      ,.dma_data_i(dma_data_li[i])
      ,.dma_data_v_i(dma_data_v_li[i])
      ,.dma_data_ready_o(dma_data_ready_lo[i])

      ,.dma_data_o(dma_data_lo[i])
      ,.dma_data_v_o(dma_data_v_lo[i])
      ,.dma_data_yumi_i(dma_data_yumi_li[i])
    
      ,.v_we_o()
    );
  end
 
  // cache_to_dram_ctrl
  //
  eAppCmd app_cmd;
  logic [link_addr_width_p+4-1:0] app_addr;
  logic app_en;
  logic app_rdy;

  logic app_wdf_wren;
  logic app_wdf_rdy;
  logic [dram_ctrl_data_width_p-1:0] app_wdf_data;
  logic [(dram_ctrl_data_width_p>>3)-1:0] app_wdf_mask;
  logic app_wdf_end;

  logic app_rd_data_valid;
  logic [dram_ctrl_data_width_p-1:0] app_rd_data;
  logic app_rd_data_end;

  bsg_cache_to_dram_ctrl #(
    .num_cache_p(num_cache_p)
    ,.addr_width_p(cache_addr_width_lp)
    ,.data_width_p(data_width_p)
    ,.block_size_in_words_p(block_size_in_words_p)
  
    ,.dram_ctrl_data_width_p(dram_ctrl_data_width_p)
    ,.dram_ctrl_burst_len_p(dram_ctrl_burst_len_p)
  ) cache_to_dram_ctrl (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.dma_pkt_i(dma_pkt)
    ,.dma_pkt_v_i(dma_pkt_v_lo)
    ,.dma_pkt_yumi_o(dma_pkt_yumi_li)

    ,.dma_data_o(dma_data_li)
    ,.dma_data_v_o(dma_data_v_li)
    ,.dma_data_ready_i(dma_data_ready_lo)

    ,.dma_data_i(dma_data_lo)
    ,.dma_data_v_i(dma_data_v_lo)
    ,.dma_data_yumi_o(dma_data_yumi_li)

    ,.app_cmd_o(app_cmd)
    ,.app_addr_o(app_addr)
    ,.app_en_o(app_en)
    ,.app_rdy_i(app_rdy)
    
    ,.app_wdf_wren_o(app_wdf_wren)
    ,.app_wdf_rdy_i(app_wdf_rdy)
    ,.app_wdf_data_o(app_wdf_data)
    ,.app_wdf_mask_o(app_wdf_mask)
    ,.app_wdf_end_o(app_wdf_end)

    ,.app_rd_data_valid_i(app_rd_data_valid)
    ,.app_rd_data_i(app_rd_data)
    ,.app_rd_data_end_i(app_rd_data_end)
  );

  // dram_ctrl
  //
  logic ddr_ck_p;
  logic ddr_ck_n;
  logic ddr_cke;
  logic ddr_we_n;
  logic ddr_cs_n;
  logic ddr_ras_n;
  logic ddr_cas_n;
  logic [15:0] ddr_addr;
  logic [2:0] ddr_ba;

  logic [(dfi_data_width_p>>4)-1:0] dm_o; // [1:0]
  logic [(dfi_data_width_p>>4)-1:0] dqs_p_oe_n;
  logic [(dfi_data_width_p>>4)-1:0] dqs_p_o;
  logic [(dfi_data_width_p>>4)-1:0] dqs_p_i;

  logic [(dfi_data_width_p>>1)-1:0] dq_oe_n; // [15:0]
  logic [(dfi_data_width_p>>1)-1:0] dq_o;
  logic [(dfi_data_width_p>>1)-1:0] dq_i;

  bsg_dmc #(
    .UI_ADDR_WIDTH(link_addr_width_p+4)
    ,.UI_DATA_WIDTH(dram_ctrl_data_width_p)
    ,.DFI_DATA_WIDTH(dfi_data_width_p)
  ) dram_ctrl (
    .sys_rst(~reset) // ACTIVE LOW !!!

    ,.app_addr(app_addr>>1) // half address
    ,.app_cmd(app_cmd)
    ,.app_en(app_en)
    ,.app_rdy(app_rdy)

    ,.app_wdf_wren(app_wdf_wren)
    ,.app_wdf_data(app_wdf_data)
    ,.app_wdf_mask(app_wdf_mask)
    ,.app_wdf_end(app_wdf_end)
    ,.app_wdf_rdy(app_wdf_rdy)

    ,.app_rd_data_valid(app_rd_data_valid)
    ,.app_rd_data(app_rd_data)
    ,.app_rd_data_end(app_rd_data_end)

    ,.app_ref_req(1'b0)
    ,.app_ref_ack()
    ,.app_zq_req(1'b0)
    ,.app_zq_ack()
    ,.app_sr_req(1'b0)
    ,.app_sr_active()

    ,.init_calib_complete()

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

    ,.ddr_dm_oen_o()
    ,.ddr_dm_o(dm_o)
    ,.ddr_dqs_p_oen_o(dqs_p_oe_n)
    ,.ddr_dqs_p_ien_o()
    ,.ddr_dqs_p_o(dqs_p_o)
    ,.ddr_dqs_p_i(dqs_p_i)
    ,.ddr_dqs_n_oen_o()
    ,.ddr_dqs_n_ien_o()
    ,.ddr_dqs_n_o()
    ,.ddr_dqs_n_i()
    ,.ddr_dq_oen_o(dq_oe_n)
    ,.ddr_dq_o(dq_o)
    ,.ddr_dq_i(dq_i)

    ,.ui_clk(clk)
    ,.dfi_clk_2x(dfi_clk_2x)
    ,.dfi_clk(dfi_clk)

    ,.ui_clk_sync_rst()
    ,.device_temp()
  );
  
  // dram model
  //

  wire [15:0] dq_int;
  wire [1:0] dqs_int;

  for (genvar i = 0; i < 16; i++) begin
    assign dq_int[i] = dq_oe_n[i] ? 1'bz : dq_o[i];
  end

  assign dq_i = dq_int;

  for (genvar i = 0; i < 2; i++) begin
    assign dqs_int[i] = dqs_p_oe_n[i] ? 1'bz : dqs_p_o[i];
  end

  assign dqs_p_i = dqs_int;

  mobile_ddr dram_model (
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

  initial begin
    wait(&done_lo);
    for (integer i = 0; i < 100; i++) begin
      @(posedge clk);
    end
    $display("************ FINISHED *************");
    $finish;
  end

endmodule
