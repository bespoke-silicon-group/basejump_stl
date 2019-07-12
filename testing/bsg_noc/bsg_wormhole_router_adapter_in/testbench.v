module testbench();
 
  `include "bsg_noc_links.vh"

  parameter x_cord_width_p = 2;
  parameter y_cord_width_p = 2;
  parameter max_payload_width_p = 17;
  parameter max_num_flit_p = 3;
  localparam len_width_lp = `BSG_SAFE_CLOG2(max_num_flit_p);
  localparam max_packet_width_lp = (max_payload_width_p+len_width_lp+y_cord_width_p+x_cord_width_p);
  localparam flit_width_lp =
    (max_packet_width_lp/max_num_flit_p)+((max_packet_width_lp%max_num_flit_p) == 0 ? 0 : 1);

    
  

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

  logic [max_packet_width_lp-1:0] data_li;
  logic v_li, ready_lo;
  logic [flit_width_lp-1:0] data_lo;
  logic v_lo, ready_li;

  `declare_bsg_ready_and_link_sif_s(flit_width_lp, bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s link_lo, link_li;

  assign data_lo = link_lo.data;
  assign v_lo    = link_lo.v;

  assign link_li.v = '0;
  assign link_li.data = '0;
  assign link_li.ready_and_rev = ready_li;

  bsg_wormhole_router_adapter_in #(
    .max_num_flit_p(max_num_flit_p)
    ,.max_payload_width_p(max_payload_width_p)
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p) 
  ) adapter (
    .clk_i(clk)
    ,.reset_i(reset)
    
    ,.data_i(data_li)
    ,.v_i(v_li)
    ,.ready_o(ready_lo)

    ,.link_o(link_lo)
    ,.link_i(link_li)
  );

  logic [flit_width_lp-1:0] fifo_data_lo;
  logic fifo_yumi_li;
  logic fifo_v_lo;
  logic fifo_ready_lo;

  bsg_fifo_1r1w_small #(
    .width_p(flit_width_lp)
    ,.els_p(16)
  ) fifo_out (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i(v_lo)
    ,.data_i(data_lo)
    ,.ready_o(fifo_ready_lo)

    ,.data_o(fifo_data_lo)
    ,.v_o(fifo_v_lo)
    ,.yumi_i(fifo_yumi_li)
  );
  assign ready_li = fifo_ready_lo;

  logic [flit_width_lp-1:0] fifo_data_lo;
  logic fifo_yumi_li;
  logic fifo_v_lo;
  logic fifo_ready_lo;

  bsg_fifo_1r1w_small #(
    .width_p(flit_width_lp)
    ,.els_p(16)
  ) fifo_out (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.v_i(v_lo)
    ,.data_i(data_lo)
    ,.ready_o(fifo_ready_lo)

    ,.data_o(fifo_data_lo)
    ,.v_o(fifo_v_lo)
    ,.yumi_i(fifo_yumi_li)
  );
  assign ready_li = fifo_ready_lo;

  parameter rom_addr_width_p = 10;
  logic [rom_addr_width_p-1:0] rom_addr;
  logic [max_packet_width_lp+4-1:0] rom_data;
  logic done;
  logic tr_ready_lo;

  bsg_fsb_node_trace_replay #(
    .ring_width_p(max_packet_width_lp)
    ,.rom_addr_width_p(rom_addr_width_p)
  ) tr (
    .clk_i(clk)
    ,.reset_i(reset)
    ,.en_i(1'b1)

    ,.v_i(fifo_v_lo)
    ,.data_i({{(max_packet_width_lp-flit_width_lp){1'b0}}, fifo_data_lo})
    ,.ready_o(tr_ready_lo)
  
    ,.v_o(v_li)
    ,.data_o(data_li)
    ,.yumi_i(v_li & ready_lo)

    ,.rom_addr_o(rom_addr)
    ,.rom_data_i(rom_data)

    ,.done_o(done)
    ,.error_o()
  );

  assign fifo_yumi_li = fifo_v_lo & tr_ready_lo;

  bsg_trace_rom #(
    .width_p(max_packet_width_lp+4)
    ,.addr_width_p(rom_addr_width_p)
  ) rom (
    .addr_i(rom_addr)
    ,.data_o(rom_data)
  );

  initial begin
    wait(done);
    //for (integer i =0; i < 1000; i++) begin
    //  @(posedge clk);
    //end
    $finish;
  end 

endmodule
