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

  pr_header_s pr_hdr_li;
  wh_header_s wh_hdr_li;
  logic hdr_v_li, hdr_ready_lo;
  logic [flit_width_p-1:0] data_li;
  logic data_v_li, data_ready_lo;
  bsg_wormhole_stream_in #(
    .flit_width_p(flit_width_p)
    ,.cord_width_p(cord_width_p)
    ,.len_width_p(len_width_p)
    ,.pr_hdr_width_p($bits(pr_header_s))
    ,.pr_data_width_p(flit_width_p)
    ) DUT (
    .clk_i(clk)
    ,.reset_i(reset)

    ,.hdr_i({pr_hdr_li, wh_hdr_li})
    ,.hdr_v_i(hdr_v_li)
    ,.hdr_ready_o(hdr_ready_lo)

    ,.data_i(data_li)
    ,.data_v_i(data_v_li)
    ,.data_ready_o(data_ready_lo)

    ,.link_data_o(link_li.data)
    ,.link_v_o(link_li.v)
    ,.link_ready_i(link_lo.ready_and_rev)
     );

  typedef struct packed {
    logic [data_width_p-1:0] data;
    pr_header_s pr_hdr;
    wh_header_s wh_hdr;
  } wormhole_packet_s;

  wormhole_packet_s test_data_lo;
  logic test_data_v_lo, test_data_yumi_li;
  bsg_wormhole_router_adapter_out #(
    .max_payload_width_p(data_width_p+pad_width_p+msg_width_p)
    ,.len_width_p(len_width_p)
    ,.cord_width_p(cord_width_p)
    ,.flit_width_p(flit_width_p)
  ) adapter (
    .clk_i(clk)
    ,.reset_i(reset)
    
    ,.link_i(link_li)
    ,.link_o(link_lo)

    ,.packet_o(test_data_lo)
    ,.v_o(test_data_v_lo)
    ,.yumi_i(test_data_yumi_li)
  );

  initial begin
    wh_hdr_li = '0;
    pr_hdr_li = '0;
    hdr_v_li = '0;

    data_li = '0;
    data_v_li = '0;

    test_data_yumi_li = '0;
    @(posedge clk);
    @(negedge reset);

    wh_hdr_li = '{len: 2'h3, cord: 'h1};
    pr_hdr_li = '{pad: '0, msg: 4'h3};
    hdr_v_li = 1'b1;
    @(posedge clk);
    hdr_v_li = 1'b0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    data_li = 32'hef;
    data_v_li = 1'b1;
    @(posedge clk);
    data_li = 32'hbe;
    data_v_li = 1'b1;
    @(posedge clk);
    data_v_li = '0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    $finish;
    //data_yumi_li = data_v_lo;
    //hdr_yumi_li = hdr_v_lo;
    //@(posedge clk);
    //$finish;
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
