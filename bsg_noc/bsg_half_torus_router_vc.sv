`include "bsg_defines.sv"
`include "bsg_noc_links.svh"

module bsg_half_torus_router_vc
  #(parameter `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(x_cord_width_p)
    , `BSG_INV_PARAM(y_cord_width_p)
    , `BSG_INV_PARAM(XY_order_p)
    , `BSG_INV_PARAM(num_vc_p)
    , `BSG_INV_PARAM(fifo_els_p)

    , `BSG_INV_PARAM(base_x_cord_p)
    , `BSG_INV_PARAM(num_tiles_x_p)

    , `BSG_INV_PARAM(from_p)

    , parameter dims_p=2
    , localparam sw_dirs_lp=(dims_p*2)+1
    , localparam vc_dirs_lp=7
  )
  (
    input clk_i
    , input reset_i

    , input [num_vc_p-1:0] v_i
    , input [width_p-1:0] data_i
    , output logic [num_vc_p-1:0] ready_o

    , output logic [num_vc_p-1:0] v_o
    , output logic [num_vc_p-1:0][vc_dirs_lp-1:0] vc_dir_sel_o
    , output logic [num_vc_p-1:0][sw_dirs_lp-1:0] sw_dir_sel_o
    , output logic [num_vc_p-1:0][width_p-1:0] data_o
    , input [num_vc_p-1:0] yumi_i

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
  );


  // VC FIFO;
  logic [num_vc_p-1:0] fifo_v_lo, fifo_yumi_li;
  logic [num_vc_p-1:0][width_p-1:0] fifo_data_lo;

  for (genvar i = 0; i < num_vc_p; i++) begin: vc
    bsg_fifo_1r1w_small #(
      .width_p(width_p)
      ,.els_p(fifo_els_p)
    ) fifo0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_i     (v_i[i])
      ,.data_i  (data_i)
      ,.ready_param_o (ready_o[i])

      ,.v_o     (fifo_v_lo[i])
      ,.data_o  (fifo_data_lo[i])
      ,.yumi_i  (fifo_yumi_li[i])
    );
  end


  // VC Decode;
  for (genvar i = 0; i < num_vc_p; i++) begin: dec
    bsg_half_torus_router_decode #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.XY_order_p(XY_order_p)
      ,.vc_id_p(i)
      ,.num_vc_p(num_vc_p)
      ,.base_x_cord_p(base_x_cord_p)
      ,.num_tiles_x_p(num_tiles_x_p)
      ,.from_p(from_p)
    ) dec0 (
      .dest_x_i           (fifo_data_lo[i][0+:x_cord_width_p])
      ,.dest_y_i          (fifo_data_lo[i][x_cord_width_p+:y_cord_width_p])
      ,.my_x_i            (my_x_i)
      ,.my_y_i            (my_y_i)
      ,.sw_dir_sel_o      (sw_dir_sel_o[i])
      ,.vc_dir_sel_o      (vc_dir_sel_o[i])
    );
  end



  // connect outputs;
  assign v_o = fifo_v_lo;
  assign data_o = fifo_data_lo;
  assign fifo_yumi_li = yumi_i;



endmodule
