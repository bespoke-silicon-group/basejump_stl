/**
 *  testbench.v
 */

module testbench();

  // parameters
  //
  parameter num_cache_p = 4;
  parameter data_width_p = 32;
  parameter addr_width_p = 32;
  parameter sets_p = 512;
  parameter block_size_in_words_p = 8;

  parameter x_cord_width_p = 2;
  parameter y_cord_width_p = 1;
  parameter load_id_width_p = 1;

  parameter link_sif_width_lp = `bsg_manycore_link_sif_width(addr_width_p,data_width_p,x_cord_width_p,y_cord_width_p,load_id_width_p);

  // clock and reset
  //
  logic clk, reset;

  bsg_nonsynth_clock_gen #(
    .cycle_time_p(100)
  ) clock_gen (
    .o(clk)
  );

  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(4)
    ,.reset_cycles_hi_p(4)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
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
      ,.addr_width_p(addr_width_p)
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
        .addr_width_p(addr_width_p)
        ,.data_width_p(data_width_p)
        ,.load_id_width_p(load_id_width_p)
        ,.x_cord_width_p(x_cord_width_p)
        ,.y_cord_width_p(y_cord_width_p)
      ) node_w_tieoff (
        ,.clk_i(clk)
        ,.reset_i(reset)
    
        ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::W])
        ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::W])
      );
    end

    bsg_manycore_link_sif_tieoff #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.load_id_width_p(load_id_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
    ) node_n_tieoff (
      ,.clk_i(clk)
      ,.reset_i(reset)
    
      ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::N])
      ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::N])
    );

    if (i == num_cache_p-1) begin
      bsg_manycore_link_sif_tieoff #(
        .addr_width_p(addr_width_p)
        ,.data_width_p(data_width_p)
        ,.load_id_width_p(load_id_width_p)
        ,.x_cord_width_p(x_cord_width_p)
        ,.y_cord_width_p(y_cord_width_p)
      ) node_e_tieoff (
        ,.clk_i(clk)
        ,.reset_i(reset)
    
        ,.link_sif_i(router_link_sif_lo[i][bsg_noc_pkg::E])
        ,.link_sif_o(router_link_sif_li[i][bsg_noc_pkg::E])
      );
    end
  end

  // master nodes
  //
  logic [num_cache_p-1:0] finished;  

  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_test_node_master #(
      .id_p(i)
      ,.addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.sets_p(sets_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.load_id_width_p(load_id_width_p)
    ) master (
      .clk_i(clk)
      ,.reset_i(reset)
    
      ,.link_sif_i(proc_link_sif_lo[i])
      ,.link_sif_o(proc_link_sif_li[i]) 
    
      ,.finish_o(finished[i])
    );
  end

  // manycore link to cache
  //
  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_manycore_link_to_cache #(
      .addr_width_p()
      ,.data_width_p()
      ,.x_cord_width_p()
      ,.y_cord_width_p()
      ,.dram_addr_width_p()
    ) manycore_link_to_cache (
      .clk_i(clk)
      ,.reset_i(reset)

      ,.my_x_i()
      ,.my_y_i()
      ,.link_sif_i()
      ,.link_sif_o()

      ,.cache_pkt_o()
      ,.v_o()
      ,.ready_i()

      ,.data_i()
      ,.v_i()
      ,.yumi_o()
    ); 
  end


  // cache
  //
  for (genvar i = 0; i < num_cache_p; i++) begin
    bsg_cache #(
      .addr_width_p(addr_width_p)
      ,.data_width_p(data_width_p)
      ,.block_size_in_words_p(block_size_in_words_p)
      ,.sets_p(sets_p)
    ) cache (
      .clk_i(clk)
      ,.reset_i(reset)

      ,.cache_pkt_i()
      ,.v_i()
      ,.ready_o()

      ,.data_o()
      ,.v_o()
      ,.yumi_i()
  
      ,.dma_pkt_o()
      ,.dma_pkt_v_o()
      ,.dma_pkt_yumi_i()

      ,.dma_data_i()
      ,.dma_data_v_i()
      ,.dma_data_ready_o()

      ,.dma_data_o()
      ,.dma_data_v_o()
      ,.dma_data_yumi_i()
    
      ,.v_we_o()
    );
  end
 
  // cache_to_dram_ctrl
  //
  bsg_cache_to_dram_ctrl #(
  ) cache_to_dram_ctrl (
    .clk_i(clk)
    ,.reset_i(reset)
  );

  // dram_ctrl
  //
  localparam UI_ADDR_WIDTH = 30;
  localparam UI_DATA_WIDTH = 128;
  localparam DFI_DATA_WIDTH = 32;
  dmc #(
    .UI_ADDR_WIDTH(UI_ADDR_WIDTH)
    ,.UI_DATA_WIDTH(UI_DATA_WIDTH)
    ,.DFI_DATA_WIDTH(DFI_DATA_WIDTH)
  ) dram_ctrl (
    .sys_rst(~reset) // ACTIVE LOW !!!

    ,.app_addr()
    ,.app_cmd()
    ,.app_en()
    ,.app_rdy()
    ,.app_wdf_wren()
    ,.app_wdf_data()
    ,.app_wdf_mask()
    ,.app_wdf_end()

    ,.app_rd_data_valid()
    ,.app_rd_data()
    ,.app_rd_data_end()
    ,.app_ref_req()
    ,.app_req_ack()
    ,.app_zq_req()
    ,.app_zq_ack()
    ,.app_sr_req()
    ,.app_sr_active()

    ,.init_calib_complete()

    ,.ddr_ck_p()
    ,.ddr_ck_n()
    ,.ddr_cke()
    ,.ddr_ba()
    ,.ddr_addr()
    ,.ddr_cs_n()
    ,.ddr_ras_n()
    ,.ddr_cas_n()
    ,.ddr_we_n()
    ,.ddr_reset_n()
    ,.ddr_odt()

    ,.dm_oe_n()
    ,.dm_o()
    ,.dqs_p_oe_n()
    ,.dqs_p_ie_n()
    ,.dqs_p_o()
    ,.dqs_p_i()
    ,.dqs_n_oe_n()
    ,.dqs_n_ie_n()
    ,.dqs_n_o()
    ,.dqs_n_i()
    ,.dq_oe_n
    ,.dq_o()
    ,.dq_i()

    ,.ui_clk()
    ,.dfi_clk_2x()
    ,.dfi_clk()

    ,.ui_clk_sync_rst()
    ,.device_temp()
  );
  
  // dram model
  //
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
    wait(&finished);
    $display("************ FINISHED *************");
    $finish;
  end

endmodule
