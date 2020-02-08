module testbench();
 
  `include "bsg_noc_links.vh"

  parameter data_width_p = 32;
  parameter flit_width_p = 8;
  parameter cord_width_p = 4;
  parameter len_width_p  = 4;
  parameter msg_width_p  = 4;
  parameter pad_width_p  = 4;

  typedef struct packed {
    logic [pad_width_p-1:0] pad;
    logic [msg_width_p-1:0] msg;
  } pr_header_s;

  typedef struct packed {
    logic [len_width_p-1:0] len;
    logic [cord_width_p-1:0] cord;
  } wh_header_s;

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

  typedef struct packed {
    logic [data_width_p-1:0] data;
    pr_header_s pr_hdr;
    wh_header_s wh_hdr;
  } wormhole_packet_s;

  wormhole_packet_s test_data_li;
  logic test_data_v_li, test_data_ready_lo;
  bsg_wormhole_router_adapter_in #(
    .max_payload_width_p(data_width_p+pad_width_p+msg_width_p)
    ,.len_width_p(len_width_p)
    ,.cord_width_p(cord_width_p)
    ,.flit_width_p(flit_width_p)
  ) adapter (
    .clk_i(clk)
    ,.reset_i(reset)
    
    ,.packet_i(test_data_li)
    ,.v_i(test_data_v_li)
    ,.ready_o(test_data_ready_lo)

    ,.link_o(link_lo)
    ,.link_i(link_li)
  );

  pr_header_s pr_hdr_lo;
  wh_header_s wh_hdr_lo;
  logic hdr_v_lo, hdr_yumi_li;
  logic [flit_width_p-1:0] data_lo;
  logic data_v_lo, data_yumi_li;
  bsg_wormhole_stream_out #(
    .flit_width_p(flit_width_p)
    ,.cord_width_p(cord_width_p)
    ,.len_width_p(len_width_p)
    ,.pr_hdr_width_p($bits(pr_header_s))
    ,.pr_data_width_p(flit_width_p)
    ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.link_data_i(link_lo.data)
    ,.link_v_i(link_lo.v)
    ,.link_ready_o(link_li.ready_and_rev)

    ,.hdr_o({pr_hdr_lo, wh_hdr_lo})
    ,.hdr_v_o(hdr_v_lo)
    ,.hdr_yumi_i(hdr_yumi_li)

    ,.data_o(data_lo)
    ,.data_v_o(data_v_lo)
    ,.data_yumi_i(data_yumi_li)
     );

  initial begin
    hdr_yumi_li = '0;
    data_yumi_li = '0;
    @(posedge clk);
    @(negedge reset);
    test_data_li.data = 32'hbeef;
    test_data_li.pr_hdr.pad = '0;
    test_data_li.pr_hdr.msg = 4'h3;
    test_data_li.wh_hdr.len = 4'h3;
    test_data_li.wh_hdr.cord = 4'h1;
    test_data_v_li = 1'b1;
    @(posedge clk);
    test_data_v_li = 1'b0;
    @(posedge hdr_v_lo);
    @(posedge clk);
    data_yumi_li = data_v_lo;
    @(posedge clk);
    data_yumi_li = data_v_lo;
    @(posedge clk);
    data_yumi_li = data_v_lo;
    @(posedge clk);
    data_yumi_li = data_v_lo;
    hdr_yumi_li = hdr_v_lo;
    @(posedge clk);
    $finish;
    //wait(0);
    //for (integer i =0; i < 1000; i++) begin
    //  @(posedge clk);
    //end
    //$finish;
  end 

initial 
  begin
    $assertoff();
    @(posedge clk)
    @(negedge reset)
    $asserton();
  end

endmodule
