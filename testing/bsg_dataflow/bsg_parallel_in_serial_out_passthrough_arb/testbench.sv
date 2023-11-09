module testbench();
 
  `include "bsg_noc_links.svh"

  import bsg_noc_pkg::*;

  // Sync with trace gen
  localparam hdr_width_p = 32;
  localparam cord_width_p = 2;
  localparam len_width_p = 3;
  localparam flit_width_p = 8;
  localparam pr_data_width_p = 16;
  localparam wh_hdr_width_p = cord_width_p + len_width_p;
  localparam pr_hdr_width_p = hdr_width_p - wh_hdr_width_p;
  localparam hdr_flits_p = hdr_width_p / flit_width_p;
  localparam data_width_p = flit_width_p*(2**len_width_p-hdr_flits_p+1);
  localparam data_flits_p = data_width_p / flit_width_p;

  localparam ring_width_p = 1+`BSG_MAX(`BSG_MAX(hdr_width_p, pr_data_width_p), flit_width_p);
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

  bsg_ready_and_link_sif_s out_link_lo, out_link_li;

  `declare_bsg_ready_and_link_sif_s(flit_width_p/4, bsg_narrow_link_sif_s);
  bsg_narrow_link_sif_s narrow_link_li, narrow_link_lo;

  logic [3:0] backpressure_cnt;
  always_ff @(posedge clk)
    if (reset)
      backpressure_cnt <= '0;
    else
      backpressure_cnt <= backpressure_cnt + 1'b1;

  wire backpressure = backpressure_cnt[0];

  bsg_parallel_in_serial_out_passthrough
   #(.width_p(flit_width_p/4), .els_p(4))
   pisop
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.data_i(link_li.data)
     ,.v_i(link_li.v)
     ,.ready_and_o(link_lo.ready_and_rev)

     ,.data_o(narrow_link_lo.data)
     ,.v_o(narrow_link_lo.v)
     ,.ready_and_i(narrow_link_li.ready_and_rev & ~backpressure)
     );

  bsg_serial_in_parallel_out_passthrough
   #(.width_p(flit_width_p/4), .els_p(4))
   sipop
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.data_i(narrow_link_lo.data)
     ,.v_i(narrow_link_lo.v & ~backpressure)
     ,.ready_and_o(narrow_link_li.ready_and_rev)

     ,.data_o(out_link_li.data)
     ,.v_o(out_link_li.v)
     ,.ready_and_i(out_link_lo.ready_and_rev)
     );
  // TODO: Actually set
  assign out_link_lo.ready_and_rev = 1'b1;

  logic [63:0] counter;
  always_ff @(posedge clk)
    if (reset)
      counter <= '0;
    else
      counter <= counter + 1'b1;
  wire select_top   = (counter % 68 == 0);
  wire select_bot   = (counter % 87 == 0);
  wire select_left  = (counter % 44 == 0);
  wire select_right = (counter % 73 == 0);

  logic [flit_width_p-1:0] left_data_li;
  logic left_yumi_lo;
  wire left_v_li = select_left;
  initial
    begin
      left_data_li = '0;

      for (integer i = 70; i < 170; i+=0)
        begin
          left_data_li = i << (cord_width_p);

          @(left_yumi_lo);
          @(negedge clk);
          i += 1'b1;
        end
    end

  logic [flit_width_p-1:0] right_data_li;
  logic right_yumi_lo;
  wire right_v_li = select_right;
  initial
    begin
      right_data_li = '0;

      for (integer i = 10; i < 110; i+=0)
        begin
          right_data_li = i << (cord_width_p);

          @(right_yumi_lo);
          @(negedge clk);
          i += 1'b1;
        end
    end

  logic [flit_width_p-1:0] top_data_li;
  logic top_yumi_lo;
  wire top_v_li = select_top;
  initial
    begin
      top_data_li = '0;

      for (integer i = 25; i < 125; i+=0)
        begin
          top_data_li = i << (cord_width_p);

          @(top_yumi_lo);
          @(negedge clk);
          i += 1'b1;
        end
    end

  logic [flit_width_p-1:0] bot_data_li;
  logic bot_yumi_lo;
  wire bot_v_li = select_bot;
  initial
    begin
      bot_data_li = '0;

      for (integer i = 50; i < 150; i+=0)
        begin
          bot_data_li = i << (cord_width_p);

          @(bot_yumi_lo);
          @(negedge clk);
          i += 1'b1;
        end
    end

  bsg_ready_and_link_sif_s [S:P] router_link_li, router_link_lo;
  bsg_mesh_router_buffered
   #(.width_p(flit_width_p)
     ,.x_cord_width_p(1)
     ,.y_cord_width_p(cord_width_p-1)
     ,.dirs_lp(5)
     )
   router
    (.clk_i(clk)
     ,.reset_i(reset)

     ,.link_i(router_link_li)
     ,.link_o(router_link_lo)

     ,.my_x_i('0)
     ,.my_y_i('0)
     );

  assign router_link_li[S].data = bot_data_li;
  assign router_link_li[N].data = top_data_li;
  assign router_link_li[E].data = right_data_li;
  assign router_link_li[W].data = left_data_li;
  assign router_link_li[P].data = '0;

  assign router_link_li[S].v = bot_v_li;
  assign router_link_li[N].v = top_v_li;
  assign router_link_li[E].v = right_v_li;
  assign router_link_li[W].v = left_v_li;
  assign router_link_li[P].v = '0;

  assign router_link_li[S].ready_and_rev ='0;
  assign router_link_li[N].ready_and_rev ='0;
  assign router_link_li[E].ready_and_rev ='0;
  assign router_link_li[W].ready_and_rev ='0;
  assign router_link_li[P].ready_and_rev = link_lo.ready_and_rev;

  assign bot_yumi_lo = router_link_lo[S].ready_and_rev & router_link_li[S].v;
  assign top_yumi_lo = router_link_lo[N].ready_and_rev & router_link_li[N].v;
  assign right_yumi_lo = router_link_lo[E].ready_and_rev & router_link_li[E].v;
  assign left_yumi_lo = router_link_lo[W].ready_and_rev & router_link_li[W].v;

  assign link_li.data = router_link_lo[P].data;
  assign link_li.v = router_link_lo[P].v;

  initial 
    begin
      $assertoff();
      @(posedge clk)
      @(negedge reset)
      $asserton();
    end

endmodule
