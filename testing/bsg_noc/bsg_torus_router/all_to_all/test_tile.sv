`include "bsg_defines.sv"


module test_tile
  import test_pkg::*;
  import bsg_noc_pkg::*;
  #(parameter `BSG_INV_PARAM(x_cord_width_p)
    , `BSG_INV_PARAM(y_cord_width_p)
    , `BSG_INV_PARAM(num_tiles_x_p)
    , `BSG_INV_PARAM(num_tiles_y_p)
    , `BSG_INV_PARAM(base_x_cord_p)
    , `BSG_INV_PARAM(base_y_cord_p)
    , `BSG_INV_PARAM(data_width_p)
    , `BSG_INV_PARAM(num_vc_p)

    , localparam link_sif_width_lp = `test_link_sif_width(data_width_p,x_cord_width_p,y_cord_width_p,num_vc_p)
  )
  (
    input clk_i
    , input reset_i

    , input [S:W][link_sif_width_lp-1:0] link_i
    , output [S:W][link_sif_width_lp-1:0] link_o

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
  
    , output logic done_o
  );


  // Cast links;
  `declare_test_link_sif_s(data_width_p,x_cord_width_p,y_cord_width_p,num_vc_p);
  test_link_sif_s [S:P] link_li, link_lo;
  assign link_li[S:W] = link_i;
  assign link_o = link_lo[S:W];

  test_packet_s packet_lo, packet_li;
  assign link_li[P].data = packet_li;
  assign packet_lo = link_lo[P].data;

  // Instantiate router;
  bsg_torus_router #(
    .width_p(`test_packet_width(data_width_p,x_cord_width_p,y_cord_width_p))
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)

    ,.num_tiles_x_p(num_tiles_x_p)
    ,.base_x_cord_p(base_x_cord_p)
    ,.num_tiles_y_p(num_tiles_y_p)
    ,.base_y_cord_p(base_y_cord_p)
  ) router0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.link_i(link_li)
    ,.link_o(link_lo)
    ,.my_x_i(my_x_i)
    ,.my_y_i(my_y_i)
  );

  // my id;
  localparam num_tiles_lp = (num_tiles_x_p*num_tiles_y_p);
  wire [data_width_p-1:0] my_id = data_width_p'(my_x_i+(my_y_i*num_tiles_x_p));


  // Sender;
  logic [x_cord_width_p-1:0] curr_x_r, curr_x_n;
  logic [y_cord_width_p-1:0] curr_y_r, curr_y_n;
  integer send_count_r, send_count_n;
  assign packet_li.x_cord = curr_x_r;
  assign packet_li.y_cord = curr_y_r;
  assign packet_li.data = my_id;


  always_comb begin
    send_count_n = send_count_r;
    curr_x_n = curr_x_r;
    curr_y_n = curr_y_r;
    link_li[P].v[0] = 1'b0;
    link_li[P].v[1] = 1'b0; // always zero;
    
    if (send_count_r != num_tiles_lp) begin
      link_li[P].v = 1'b1;
      if (link_lo[P].ready_and_rev[0]) begin
        curr_x_n = (curr_x_r == num_tiles_x_p-1)
          ? '0
          : (curr_x_r + 1);
        curr_y_n = (curr_x_r == num_tiles_x_p-1)
          ? (curr_y_r + 1)
          : curr_y_r;
        send_count_n = send_count_r + 1;
      end
    end
  end


  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      curr_x_r <= '0;
      curr_y_r <= '0;
      send_count_r <= '0;
    end
    else begin
      curr_x_r <= curr_x_n;
      curr_y_r <= curr_y_n;
      send_count_r <= send_count_n;
    end
  end


  // Receiver;
  logic [num_tiles_lp-1:0] received_r, received_n;
  assign link_li[P].ready_and_rev[0] = 1'b1;
  assign link_li[P].ready_and_rev[1] = 1'b1;
  assign received_n = link_lo[P].v << packet_lo.data;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      received_r <= 1'b0;
    end
    else begin
    
      for (integer i = 0; i < num_tiles_lp; i++) begin
        if (received_n[i]) begin
          received_r[i] <= 1'b1;
          $display("(x,y)=(%0d,%0d) receiving id = %0d.", my_x_i, my_y_i, packet_lo.data);
        end
      end

      // assert #1;
      assert(~link_lo[P].v[1]) else $error("[BSG_ERROR] packet should not arrive at VC1.");

      // assert #2;
      if (link_lo[P].v[0]) begin
        assert((packet_lo.x_cord == my_x_i) && (packet_lo.y_cord == my_y_i)) else
          $error("[BSG_ERROR] wrong packet (%0d, %0d) arrived at (%0d, %0d).",
            packet_lo.x_cord, packet_lo.y_cord, my_x_i, my_y_i);
      end


    end
  end

  assign done_o = &received_r;


endmodule
