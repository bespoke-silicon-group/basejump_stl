`include "bsg_defines.sv"
`include "bsg_noc_links.svh"



module bsg_torus_router
  #(parameter `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(x_cord_width_p)
    , `BSG_INV_PARAM(y_cord_width_p)

    , `BSG_INV_PARAM(base_x_cord_p)
    , `BSG_INV_PARAM(base_y_cord_p)
    , `BSG_INV_PARAM(num_tiles_x_p)
    , `BSG_INV_PARAM(num_tiles_y_p)

    , parameter XY_order_p = 1
    , parameter full_torus_p = 1

    , parameter num_vc_p=2
    , parameter dims_p=2
    , localparam dirs_lp=(dims_p*2)+1
    , localparam dir_id_width_lp=`BSG_SAFE_CLOG2(dirs_lp)
    , localparam vc_id_width_lp=`BSG_SAFE_CLOG2(num_vc_p)


    , parameter int fifo_els_p[dirs_lp-1:0] = '{2,2,2,2,2}
    , parameter use_credits_p = {dirs_lp{1'b0}}
    , localparam vc_link_width_lp=`bsg_vc_link_sif_width(width_p,num_vc_p)
  )
  ( 
    input clk_i
    , input reset_i

    , input        [dirs_lp-1:0][vc_link_width_lp-1:0] link_i
    , output logic [dirs_lp-1:0][vc_link_width_lp-1:0] link_o

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
  );


  // Casting ports;
  `declare_bsg_vc_link_sif_s(width_p,num_vc_p,bsg_vc_link_sif_s);
  bsg_vc_link_sif_s [dirs_lp-1:0] link_in, link_out;
  assign link_in = link_i;
  assign link_o = link_out;


  // virtual channels;
  logic [dirs_lp-1:0][num_vc_p-1:0] vc_v_lo, vc_yumi_li;
  logic [dirs_lp-1:0][num_vc_p-1:0][width_p-1:0] vc_data_lo;
  logic [dirs_lp-1:0][num_vc_p-1:0][num_vc_p-1:0] vc_sel_lo;
  logic [dirs_lp-1:0][num_vc_p-1:0][vc_id_width_lp-1:0] vc_sel_id_lo;
  logic [dirs_lp-1:0][num_vc_p-1:0][dirs_lp-1:0] dir_sel_lo;
  logic [dirs_lp-1:0][num_vc_p-1:0][dir_id_width_lp-1:0] dir_sel_id_lo;

  for (genvar i = 0; i < dirs_lp; i++) begin: vc
    bsg_torus_router_vc #(
      .width_p(width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.XY_order_p(XY_order_p)
      ,.num_vc_p(num_vc_p)
      ,.full_torus_p(full_torus_p)
      ,.fifo_els_p(fifo_els_p[i])
      ,.use_credits_p(use_credits_p[i])

      ,.base_x_cord_p(base_x_cord_p)
      ,.base_y_cord_p(base_y_cord_p)
      ,.num_tiles_x_p(num_tiles_x_p)
      ,.num_tiles_y_p(num_tiles_y_p)

      ,.from_p(i)
    ) vc0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_i(link_in[i].v)
      ,.data_i(link_in[i].data)
      ,.ready_o(link_out[i].ready_and_rev)

      ,.v_o(vc_v_lo[i])
      ,.vc_sel_o(vc_sel_lo[i])
      ,.vc_sel_id_o(vc_sel_id_lo[i])
      ,.dir_sel_o(dir_sel_lo[i])
      ,.dir_sel_id_o(dir_sel_id_lo[i])
      ,.data_o(vc_data_lo[i])
      ,.yumi_i(vc_yumi_li[i])
      
      ,.my_x_i(my_x_i)
      ,.my_y_i(my_y_i)
    );
  end


  // allocator;
  logic [dirs_lp-1:0][width_p-1:0] xbar_data_li;
  logic [dirs_lp-1:0][dirs_lp-1:0] xbar_sel_li;
  logic [dirs_lp-1:0][num_vc_p-1:0] alloc_link_v_lo, alloc_link_ready_li;

  bsg_torus_router_alloc #(
    .width_p(width_p)
    ,.num_vc_p(num_vc_p)
  ) alloc0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    // VC side;
    ,.vc_v_i(vc_v_lo)
    ,.vc_data_i(vc_data_lo)
    ,.vc_sel_i(vc_sel_lo)
    ,.vc_sel_id_i(vc_sel_id_lo)
    ,.dir_sel_i(dir_sel_lo) 
    ,.dir_sel_id_i(dir_sel_id_lo)
    ,.vc_yumi_o(vc_yumi_li)

    // crossbar;
    ,.xbar_data_o(xbar_data_li)
    ,.xbar_sel_o(xbar_sel_li)

    // output link side;
    ,.link_v_o(alloc_link_v_lo)
    ,.link_ready_i(alloc_link_ready_li)
  );


  // crossbar;
  logic [dirs_lp-1:0][width_p-1:0] xbar_data_lo;
  bsg_torus_router_xbar #(
    .width_p(width_p)
  ) xbar0 (
    .data_i   (xbar_data_li)
    ,.data_o  (xbar_data_lo)
    ,.sel_i   (xbar_sel_li)
  );


  // connect output links;
  for (genvar i = 0; i < dirs_lp; i++) begin
    assign link_out[i].v = alloc_link_v_lo[i];
    assign link_out[i].data = xbar_data_lo[i];
    assign alloc_link_ready_li[i] = link_in[i].ready_and_rev; 
  end

endmodule


`BSG_ABSTRACT_MODULE(bsg_torus_router)
