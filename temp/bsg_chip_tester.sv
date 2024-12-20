
`include "bsg_chip_defines.svh"
`include "bsg_tag.svh"

module bsg_chip_tester
 import bsg_chip_pkg::*;
 import bsg_chip_test_pkg::*;
 import bsg_tag_pkg::*;
 #(parameter `BSG_INV_PARAM(tag_els_p)
   , parameter `BSG_INV_PARAM(tag_lg_width_p)
   , parameter `BSG_INV_PARAM(tag_lg_els_p)
   , parameter `BSG_INV_PARAM(gateway_tag_local_els_p)
   , parameter `BSG_INV_PARAM(gateway_tag_node_id_offset_p)
   , parameter `BSG_INV_PARAM(asic_tag_local_els_p)
   , parameter `BSG_INV_PARAM(asic_tag_node_id_offset_p)

   , parameter `BSG_INV_PARAM(tag_rom_str_p)
   , parameter `BSG_INV_PARAM(tag_rom_data_width_p)
   , parameter `BSG_INV_PARAM(tag_rom_addr_width_p)
   , parameter `BSG_INV_PARAM(tag_rom_payload_width_p)

   , parameter `BSG_INV_PARAM(test_rom_str_p)
   , parameter `BSG_INV_PARAM(test_rom_data_width_p)
   , parameter `BSG_INV_PARAM(test_rom_addr_width_p)
   , parameter `BSG_INV_PARAM(test_rom_payload_width_p)
   )
  (
    output bit gateway_clk_o
    , output bit gateway_reset_o

    , output bit gateway_tag_clk_o
    , output bit gateway_tag_en_o
    , output bit gateway_tag_data_o
    , output logic [tag_lg_els_p-1:0] gateway_tag_node_id_offset_o
    , output bsg_tag_s [gateway_tag_local_els_p-1:0] gateway_tag_lines_o

    , output bit asic_clk_A_o
    , output bit asic_clk_B_o
    , output bit asic_clk_C_o
    , output bit asic_clk_D_o
    , output bit asic_rt_clk_o

    , output bit asic_tag_clk_o
    , output bit asic_tag_en_o
    , output bit asic_tag_data_o
    , output logic [tag_lg_els_p-1:0] asic_tag_node_id_offset_o
    , output bsg_tag_s [asic_tag_local_els_p-1:0] mirror_tag_lines_o

    , output logic [test_rom_payload_width_p-1:0] test_data_o
    , output logic test_v_o
    , input test_yumi_i

    , input [test_rom_payload_width_p-1:0] test_data_i
    , input test_v_i
    , output logic test_ready_and_o

    , output logic tag_done_o
    , output logic tag_error_o
    , output logic test_done_o
    , output logic test_error_o
    );

  //////////////////////////////////////////////////
  // Clock generation
  //////////////////////////////////////////////////
  localparam gateway_clk_period_lp = 1000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(gateway_clk_period_lp))
   gateway_clk_gen
    (.o(gateway_clk_o));

  localparam clk_A_period_lp = 6000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(clk_A_period_lp))
   clk_A_gen
    (.o(asic_clk_A_o));

  localparam clk_B_period_lp = 7000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(clk_B_period_lp))
   clk_B_gen
    (.o(asic_clk_B_o));

  localparam clk_C_period_lp = 8000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(clk_C_period_lp))
   clk_C_gen
    (.o(asic_clk_C_o));

  localparam clk_D_period_lp = 10000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(clk_D_period_lp))
   clk_D_gen
    (.o(asic_clk_D_o));

  localparam rt_clk_period_lp = 50000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(rt_clk_period_lp))
   rt_clk_gen
    (.o(asic_rt_clk_o));

  bit tag_clk_lo;
  localparam tag_clk_period_lp = 5000;
  bsg_nonsynth_clock_gen
   #(.cycle_time_p(tag_clk_period_lp))
   tag_clk_gen
    (.o(tag_clk_lo));

  //////////////////////////////////////////////////
  // Reset generation
  //////////////////////////////////////////////////
  localparam async_resetl_lp = 5;
  localparam async_reseth_lp = 20;
  bit async_reset_lo;
  bsg_nonsynth_reset_gen
   #(.num_clocks_p(2)
     ,.reset_cycles_lo_p(async_resetl_lp)
     ,.reset_cycles_hi_p(async_reseth_lp)
     )
   async_reset_gen
    (.clk_i({tag_clk_lo, gateway_clk_o})
     ,.async_reset_o(async_reset_lo)
     );
  assign gateway_reset_o = async_reset_lo;

  //////////////////////////////////////////////////
  // Tag generation
  //////////////////////////////////////////////////
  wire tag_trace_clk_lo = tag_clk_lo;
  wire tag_trace_reset_lo = async_reset_lo;
  wire tag_trace_en_lo = ~async_reset_lo;

  logic [tag_rom_addr_width_p-1:0] tag_rom_addr_li;
  logic [tag_rom_data_width_p-1:0] tag_rom_data_lo;
  bsg_nonsynth_test_rom_plusargs
   #(.data_width_p(tag_rom_data_width_p)
     ,.addr_width_p(tag_rom_addr_width_p)
     ,.plusargs_str_p(tag_rom_str_p)
     )
   tag_rom
    (.addr_i(tag_rom_addr_li), .data_o(tag_rom_data_lo));

  logic [tag_num_masters_gp-1:0] tag_trace_en_r_lo;
  logic [tag_max_payload_width_gp-1:0] tag_trace_data_li;
  logic tag_trace_v_li, tag_trace_ready_and_lo;
  logic tag_trace_data_lo;
  logic tag_trace_v_lo, tag_trace_yumi_li;
  logic tag_trace_done_lo, tag_trace_error_lo;
  bsg_tag_trace_replay
   #(.rom_addr_width_p(tag_rom_addr_width_gp)
     ,.rom_data_width_p(tag_rom_data_width_gp)
     ,.num_masters_p(tag_num_masters_gp)
     ,.num_clients_p(tag_num_clients_gp)
     ,.max_payload_width_p(tag_max_payload_width_gp)
     )
   tag_trace_replay
    (.clk_i(tag_trace_clk_lo)
     ,.reset_i(tag_trace_reset_lo)
     ,.en_i(tag_trace_en_lo)

     ,.rom_addr_o(tag_rom_addr_li)
     ,.rom_data_i(tag_rom_data_lo)

     ,.valid_i(1'b0)
     ,.data_i('0)
     ,.ready_o()

     ,.tag_data_o(tag_trace_data_lo)
     ,.en_r_o(tag_trace_en_r_lo)
     ,.valid_o(tag_trace_v_lo)
     ,.yumi_i(tag_trace_yumi_li)

     ,.done_o(tag_trace_done_lo)
     ,.error_o(tag_trace_error_lo)
    );
  assign tag_trace_yumi_li = tag_trace_v_lo;

  assign gateway_tag_clk_o = tag_trace_done_lo ? 1'b1 : tag_clk_lo;
  assign gateway_tag_en_o = tag_trace_en_r_lo[1] & tag_trace_v_lo;
  assign gateway_tag_data_o = gateway_tag_en_o ? tag_trace_data_lo : 1'b0;
  assign gateway_tag_node_id_offset_o = gateway_tag_node_id_offset_p;

  wire gateway_tag_clk_li = tag_clk_lo;
  wire gateway_tag_data_li = gateway_tag_en_o ? gateway_tag_data_o : 1'b0;
  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.local_els_p(gateway_tag_local_els_p)
     ,.lg_width_p(tag_lg_width_p)
     )
   gateway_btm
    (.clk_i(gateway_tag_clk_o)
     ,.data_i(gateway_tag_data_o)
     ,.node_id_offset_i(gateway_tag_node_id_offset_o)
     ,.clients_o(gateway_tag_lines_o)
     );

  assign asic_tag_clk_o = tag_trace_done_lo ? 1'b1 : ~tag_clk_lo;
  assign asic_tag_en_o = tag_trace_en_r_lo[0] & tag_trace_v_lo;
  assign asic_tag_data_o = asic_tag_en_o ? tag_trace_data_lo : 1'b0;
  assign asic_tag_node_id_offset_o = asic_tag_node_id_offset_p;

  bsg_tag_master_decentralized
   #(.els_p(tag_els_p)
     ,.lg_width_p(tag_lg_width_p)
     ,.local_els_p(asic_tag_local_els_p)
     )
   mirror_btm
    (.clk_i(asic_tag_clk_o)
     ,.data_i(asic_tag_data_o)
     ,.node_id_offset_i(asic_tag_node_id_offset_o)
     ,.clients_o(mirror_tag_lines_o)
     );

  //////////////////////////////////////////////////
  // Test generation
  //////////////////////////////////////////////////
  wire test_trace_clk_li = gateway_clk_o;
  wire test_trace_reset_li = async_reset_lo;
  wire test_trace_en_li = ~async_reset_lo & tag_trace_done_lo;

  logic [test_rom_addr_width_p-1:0] test_rom_addr_li;
  logic [test_rom_data_width_p-1:0] test_rom_data_lo;
  bsg_nonsynth_test_rom_plusargs
   #(.data_width_p(test_rom_data_width_p)
     ,.addr_width_p(test_rom_addr_width_p)
     ,.plusargs_str_p(test_rom_str_p)
     )
   test_rom
    (.addr_i(test_rom_addr_li), .data_o(test_rom_data_lo));

  logic test_trace_done_lo, test_trace_error_lo;  
  bsg_trace_replay
   #(.payload_width_p(test_rom_payload_width_p)
     ,.rom_addr_width_p(test_rom_addr_width_p)
     ,.debug_p(2)
     )
   test_trace_replay
    (.clk_i(test_trace_clk_li)
     ,.reset_i(test_trace_reset_li)
     ,.en_i(test_trace_en_li)

     ,.rom_addr_o(test_rom_addr_li)
     ,.rom_data_i(test_rom_data_lo)

     ,.data_o(test_data_o)
     ,.v_o(test_v_o)
     ,.yumi_i(test_yumi_i)

     ,.data_i(test_data_i)
     ,.v_i(test_v_i)
     ,.ready_o(test_ready_and_o)

     ,.done_o(test_trace_done_lo)
     ,.error_o(test_trace_error_lo)
     );

  //////////////////////////////////////////////////
  // Testbench functionality
  //////////////////////////////////////////////////
`ifdef ASSERT_ENABLE
    initial
      begin
        $assertoff();
        @(posedge gateway_clk_o);
        @(posedge tag_trace_done_lo);
        $asserton();
      end
`endif

`ifdef TRACE_ENABLE
    integer ret;
    // Unsupported by xcelium
    //string dumpfile;
    logic [63:0] dumpfile;
    initial begin
      ret = $value$plusargs("bsg_trace", dumpfile);
      if (ret != 0)
        begin
          $shm_open(dumpfile);
          @(posedge gateway_clk_o);
          $shm_probe(testbench, "AC");
          //$shm_probe(testbench.dut, "AC");
        end
    end
`endif

  logic startup;
  initial
    begin
      startup = 1'b0;
      @(negedge async_reset_lo);
      startup = 1'b1;
    end

  assign tag_done_o = startup && tag_trace_done_lo;
  assign tag_error_o = startup && tag_trace_error_lo;
  assign test_done_o = startup && test_trace_done_lo;
  assign test_error_o = startup && test_trace_error_lo;

endmodule

