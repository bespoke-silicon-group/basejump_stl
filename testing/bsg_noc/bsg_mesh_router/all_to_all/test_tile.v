// (sender)   Each tile sends a packet to every tile.
// (receiver) The tile assert done_o, when it has received packets from everyone.


module test_tile
  import test_pkg::*;
  import bsg_noc_pkg::*;
  #(parameter dims_p=2
    , parameter x_cord_width_p=4
    , parameter y_cord_width_p=3
    , parameter num_tiles_x_p=16
    , parameter num_tiles_y_p=8
    , parameter data_width_p=32
    , parameter ruche_factor_X_p=0
    , parameter ruche_factor_Y_p=0
    , parameter XY_order_p=1
    , parameter dirs_lp=(dims_p*2)+1

    , parameter link_sif_width_lp = `test_link_sif_width(data_width_p,x_cord_width_p,y_cord_width_p)
  )
  (
    input clk_i
    , input reset_i
    
    , input  [dirs_lp-1:W][link_sif_width_lp-1:0] link_i
    , output [dirs_lp-1:W][link_sif_width_lp-1:0] link_o
    
    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i

    , output logic done_o
  );


  typedef int fifo_els_arr_t[dirs_lp-1:0];

  function fifo_els_arr_t get_fifo_els();
    fifo_els_arr_t retval;
    for (int i = 0; i < dirs_lp; i++) begin
      retval[i] = 2;
    end

    return retval;
  endfunction


  localparam num_tiles_lp = num_tiles_x_p*num_tiles_y_p;


  `declare_test_link_sif_s(data_width_p,x_cord_width_p,y_cord_width_p);
  test_link_sif_s [dirs_lp-1:P] link_li;
  test_link_sif_s [dirs_lp-1:P] link_lo;
  assign link_li[dirs_lp-1:W] = link_i;
  assign link_o = link_lo[dirs_lp-1:W];

  test_packet_s packet_lo;
  test_packet_s packet_li;
  assign link_li[P].data = packet_li;
  assign packet_lo = link_lo[P].data;

  bsg_mesh_router_buffered #(
    .width_p(`test_packet_width(data_width_p,x_cord_width_p,y_cord_width_p))
    ,.x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.ruche_factor_X_p(ruche_factor_X_p)
    ,.ruche_factor_Y_p(ruche_factor_Y_p)
    ,.dims_p(dims_p)
    ,.fifo_els_p(get_fifo_els())
    ,.XY_order_p(XY_order_p)
  ) router (
    .clk_i(clk_i)
    ,.reset_i(reset_i)
    
    ,.link_i(link_li)
    ,.link_o(link_lo)
    
    ,.my_x_i(my_x_i)
    ,.my_y_i(my_y_i)
  );

  wire [data_width_p-1:0] my_id = (data_width_p)'(my_x_i+(my_y_i*num_tiles_x_p));


  // sender
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
    link_li[P].v = 1'b0;

    if (send_count_r != num_tiles_lp) begin
      link_li[P].v = 1'b1;
      if (link_lo[P].ready_and_rev) begin
        curr_x_n = (curr_x_r == num_tiles_x_p-1)
          ? '0
          : (curr_x_r + 1);
        curr_y_n = (curr_x_r == num_tiles_x_p-1)
          ? curr_y_r + 1
          : curr_y_r;
        send_count_n = send_count_r + 1;
      end
    end
    else begin
      link_li[P].v = 1'b0;
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





  // receiver
  logic [num_tiles_lp-1:0] v_r, v_n;
  assign link_li[P].ready_and_rev = 1'b1;
  assign v_n = link_lo[P].v << packet_lo.data;

  always_ff @ (posedge clk_i) begin
    if (reset_i) begin
      v_r <= '0;
    end
    else begin
      for (integer i = 0; i < num_tiles_lp; i++) begin: l
        if (v_n[i]) begin
          v_r[i] <= 1'b1;
          $display("(x,y)=(%2d,%2d) receiving id=%6d.", my_x_i, my_y_i, packet_lo.data);
        end
      end

      // assert that packet arrived at correct dest.
      if (link_lo[P].v) begin
        assert((packet_lo.x_cord == my_x_i) & (packet_lo.y_cord == my_y_i)) else
          $error("[BSG_ERROR] wrong packet (%0d, %0d) arrived at (%0d, %0d).",
            packet_lo.x_cord, packet_lo.y_cord,
            my_x_i, my_y_i
          );
      end
    end
  end

  assign done_o = &v_r;








endmodule
