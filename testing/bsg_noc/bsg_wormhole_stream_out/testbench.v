module testbench();
 
  `include "bsg_noc_links.vh"

  import bsg_noc_pkg::*;
  import bsg_wormhole_router_pkg::*;

  // Sync with trace gen
  localparam hdr_width_p = 32;
  localparam cord_width_p = 5;
  localparam len_width_p = 3;
  localparam flit_width_p = 32;
  localparam pr_data_width_p = 8;
  localparam wh_hdr_width_p = cord_width_p + len_width_p;
  localparam pr_hdr_width_p = hdr_width_p - wh_hdr_width_p;
  localparam hdr_flits_p = hdr_width_p / flit_width_p;
  localparam data_width_p = flit_width_p*(2**len_width_p-hdr_flits_p+1);
  localparam data_flits_p = data_width_p / flit_width_p;

  localparam ring_width_p = 1+`BSG_MAX(`BSG_MAX(pr_hdr_width_p, pr_data_width_p), flit_width_p);
  localparam rom_data_width_p = 4 + ring_width_p;
  localparam rom_addr_width_p = 32;

  logic clk;
  bsg_nonsynth_clock_gen #(
    .cycle_time_p(1000)
  ) clock_gen (
    .o(clk)
  );

  logic reset;
  bsg_nonsynth_reset_gen #(
    .num_clocks_p(1)
    ,.reset_cycles_lo_p(4)
    ,.reset_cycles_hi_p(4)
  ) reset_gen (
    .clk_i(clk)
    ,.async_reset_o(reset)
  );

  `declare_bsg_ready_and_link_sif_s(flit_width_p, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_lo, link_li;

  logic [hdr_width_p-1:0] hdr_lo;
  logic hdr_v_lo, hdr_ready_and_li;
  logic [pr_data_width_p-1:0] data_lo;
  logic data_v_lo, data_ready_and_li;
  bsg_wormhole_stream_out #(
    .flit_width_p(flit_width_p)
    ,.cord_width_p(cord_width_p)
    ,.len_width_p(len_width_p)
    ,.pr_hdr_width_p(pr_hdr_width_p)
    ,.pr_data_width_p(pr_data_width_p)
    ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.link_data_i(link_li.data)
    ,.link_v_i(link_li.v)
    ,.link_ready_and_o(link_lo.ready_and_rev)

    ,.hdr_o(hdr_lo)
    ,.hdr_v_o(hdr_v_lo)
    ,.hdr_ready_and_i(hdr_ready_and_li)

    ,.data_o(data_lo)
    ,.data_v_o(data_v_lo)
    ,.data_ready_and_i(data_ready_and_li)
     );
  wire [cord_width_p-1:0] cord_lo = link_lo.data[0+:cord_width_p];
  wire [len_width_p-1:0] len_lo = link_lo.data[cord_width_p+:len_width_p];

  bsg_ready_and_link_sif_s [E:W] trace_link_li, trace_link_lo;
  bsg_wormhole_router
   #(.flit_width_p(flit_width_p)
     ,.dims_p(1)
     ,.cord_markers_pos_p('{5,0})
     ,.len_width_p(len_width_p)
     )
   router
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.link_i({trace_link_li, link_lo})
     ,.link_o({trace_link_lo, link_li})
     ,.my_cord_i('0)
     );

  logic [10:0] backpressure_cnt;
  always_ff @(posedge clk)
    if (reset)
      backpressure_cnt <= '0;
    else
      backpressure_cnt <= backpressure_cnt + 1'b1;

  wire backpressure = |{backpressure_cnt[0+:4]};

  logic [ring_width_p-1:0] fifo_data_li;
  logic fifo_v_li, fifo_ready_lo, fifo_pressure_ready_lo;

  assign fifo_pressure_ready_lo = ~backpressure & fifo_ready_lo;

  assign fifo_data_li = hdr_v_lo ? hdr_lo : data_lo;
  assign fifo_v_li = hdr_v_lo | data_v_lo;
  assign hdr_ready_and_li = fifo_pressure_ready_lo;
  assign data_ready_and_li = fifo_pressure_ready_lo;

  logic [ring_width_p-1:0] tr_data_li;
  logic tr_v_li, tr_ready_lo;
  bsg_fifo_1r1w_small
   #(.width_p(ring_width_p)
     ,.els_p(32)
     )
   out_fifo
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.data_i(fifo_data_li)
     ,.v_i(fifo_pressure_ready_lo & fifo_v_li)
     ,.ready_o(fifo_ready_lo)

     ,.data_o(tr_data_li)
     ,.v_o(tr_v_li)
     ,.yumi_i(tr_ready_lo & tr_v_li)
     );

  logic [rom_addr_width_p-1:0] rom_addr;
  logic [rom_data_width_p-1:0] rom_data;
  logic [ring_width_p-1:0] tr_data_lo;
  logic tr_v_lo, tr_yumi_li;
  logic tr_done;
  bsg_trace_replay #(
    .payload_width_p(ring_width_p)
    ,.rom_addr_width_p(rom_addr_width_p)
  ) trace_replay (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.en_i(1'b1)

    ,.v_i(tr_v_li)
    ,.data_i(tr_data_li)
    ,.ready_o(tr_ready_lo)

    ,.v_o(tr_v_lo)
    ,.data_o(tr_data_lo)
    ,.yumi_i(tr_yumi_li)

    ,.rom_addr_o(rom_addr)
    ,.rom_data_i(rom_data)

    ,.done_o(tr_done)
    ,.error_o()
    );

  bsg_trace_rom #(
    .width_p(rom_data_width_p)
    ,.addr_width_p(rom_addr_width_p)
  ) trace_rom (
    .addr_i(rom_addr)
    ,.data_o(rom_data)
  );

  logic [1:0] direction_hash;
  always_ff @(posedge clk)
    if (reset)
      direction_hash <= '0;
    else if (~|rom_data)
      direction_hash <= direction_hash + 1'b1;

  always_comb
    begin
      if (direction_hash % 2 == '0)
        begin
          trace_link_li[E].v = tr_v_lo;
          trace_link_li[E].data = tr_data_lo[0+:flit_width_p];
          trace_link_li[E].ready_and_rev = '0;
          tr_yumi_li = trace_link_lo[E].ready_and_rev & trace_link_li[E].v;

          trace_link_li[W] = '0;
        end
      else
        begin
          trace_link_li[W].v = tr_v_lo;
          trace_link_li[W].data = tr_data_lo[0+:flit_width_p];
          trace_link_li[W].ready_and_rev = '0;
          tr_yumi_li = trace_link_lo[W].ready_and_rev & trace_link_li[W].v;

          trace_link_li[E] = '0;
        end
    end

  assign link_lo.v = 1'b0;
  assign link_lo.data = '0;

initial 
  begin
    $assertoff();
    @(posedge clk)
    @(negedge reset)
    $asserton();

    @(tr_done);
    $finish();
  end

endmodule
