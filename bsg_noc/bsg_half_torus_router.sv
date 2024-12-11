`include "bsg_defines.sv"
`include "bsg_noc_links.svh"


module bsg_half_torus_router
  import bsg_noc_pkg::*;
  #(parameter `BSG_INV_PARAM(width_p)
    , `BSG_INV_PARAM(x_cord_width_p)
    , `BSG_INV_PARAM(y_cord_width_p)

    , `BSG_INV_PARAM(base_x_cord_p)
    , `BSG_INV_PARAM(num_tiles_x_p)

    , parameter use_credits_p=0
    , parameter XY_order_p = 1

    , parameter num_vc_p=2
    , parameter dims_p=2
    , localparam sw_dirs_lp=(dims_p*2)+1
    , localparam vc_dirs_lp=7

    , parameter int fifo_els_p[sw_dirs_lp-1:0] = '{2,2,2,2,2}

    // link width;
    , localparam vc_link_width_lp=`bsg_vc_link_sif_width(width_p,num_vc_p)
    , localparam link_width_lp=`bsg_ready_and_link_sif_width(width_p)
  )
  (
    input clk_i
    , input reset_i

    , input        [link_width_lp-1:0] proc_link_i
    , output logic [link_width_lp-1:0] proc_link_o

    , input        [S:N][link_width_lp-1:0] ver_link_i
    , output logic [S:N][link_width_lp-1:0] ver_link_o

    , input        [E:W][vc_link_width_lp-1:0] hor_link_i
    , output logic [E:W][vc_link_width_lp-1:0] hor_link_o

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
  );

  // casting ports;
  `declare_bsg_vc_link_sif_s(width_p,num_vc_p,bsg_vc_link_sif_s);
  `declare_bsg_ready_and_link_sif_s(width_p,bsg_link_sif_s);
  bsg_vc_link_sif_s [1:0] hor_link_in, hor_link_out;
  bsg_link_sif_s [1:0] ver_link_in, ver_link_out;
  bsg_link_sif_s proc_link_in, proc_link_out;
  assign hor_link_in = hor_link_i;
  assign hor_link_o = hor_link_out;
  assign ver_link_in = ver_link_i;
  assign ver_link_o = ver_link_out;
  assign proc_link_in = proc_link_i;
  assign proc_link_o = proc_link_out;

  // virtual channels interface;
  logic [vc_dirs_lp-1:0] vc_v_lo, vc_yumi_li;
  logic [vc_dirs_lp-1:0][width_p-1:0] vc_data_lo;
  logic [vc_dirs_lp-1:0][vc_dirs_lp-1:0] vc_dir_sel_lo;
  logic [vc_dirs_lp-1:0][sw_dirs_lp-1:0] sw_dir_sel_lo;


  // Proc input FIFO;
  logic fifo_ready_lo;

  bsg_fifo_1r1w_small #(
    .width_p(width_p)
    ,.els_p(fifo_els_p[0])
  ) proc_fifo0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i           (proc_link_in.v)
    ,.data_i        (proc_link_in.data)
    ,.ready_param_o (fifo_ready_lo)

    ,.v_o           (vc_v_lo[0])
    ,.data_o        (vc_data_lo[0])
    ,.yumi_i        (vc_yumi_li[0])
  );

  if (use_credits_p) begin: cr
    bsg_dff_reset #(
      .width_p(1)
      ,.reset_val_p(0)
    ) dff0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.data_i(vc_yumi_li[0])
      ,.data_o(proc_link_out.ready_and_rev)
    );

    `ifndef BSG_HIDE_FROM_SYNTHESIS
    always_ff @ (negedge clk_i) begin
      if (reset_i == 1'b0) begin
        if (proc_link_in.v) begin
          assert(fifo_ready_lo) else $error("Trying to enqueu when there is no FIFO space.");
        end
      end
    end
    `endif
  end
  else begin
    assign proc_link_out.ready_and_rev = fifo_ready_lo;
  end

  bsg_half_torus_router_decode #(
    .x_cord_width_p(x_cord_width_p)
    ,.y_cord_width_p(y_cord_width_p)
    ,.XY_order_p(XY_order_p)
    ,.vc_id_p(0)
    ,.num_vc_p(num_vc_p)
    ,.base_x_cord_p(base_x_cord_p)
    ,.num_tiles_x_p(num_tiles_x_p)
    ,.from_p(0)
  ) proc_decode0 (
    .dest_x_i       (vc_data_lo[0][0+:x_cord_width_p])
    ,.dest_y_i      (vc_data_lo[0][x_cord_width_p+:y_cord_width_p])
    ,.my_x_i        (my_x_i)
    ,.my_y_i        (my_y_i)
    ,.sw_dir_sel_o  (sw_dir_sel_lo[0])
    ,.vc_dir_sel_o  (vc_dir_sel_lo[0])
  );


  // Horizontal VC;
  for (genvar i = 0; i < 2; i++) begin: vc
    bsg_half_torus_router_vc #(
      .width_p(width_p)
      ,.x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.XY_order_p(XY_order_p)
      ,.num_vc_p(num_vc_p)
      ,.fifo_els_p(fifo_els_p[i+1])

      ,.base_x_cord_p(base_x_cord_p)
      ,.num_tiles_x_p(num_tiles_x_p)

      ,.from_p(i+1)
    ) vc0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_i     (hor_link_in[i].v)
      ,.data_i  (hor_link_in[i].data)
      ,.ready_o (hor_link_out[i].ready_and_rev)

      ,.v_o           (vc_v_lo[1+(num_vc_p*i)+:num_vc_p])
      ,.vc_dir_sel_o  (vc_dir_sel_lo[1+(num_vc_p*i)+:num_vc_p])
      ,.sw_dir_sel_o  (sw_dir_sel_lo[1+(num_vc_p*i)+:num_vc_p])
      ,.data_o        (vc_data_lo[1+(num_vc_p*i)+:num_vc_p])
      ,.yumi_i        (vc_yumi_li[1+(num_vc_p*i)+:num_vc_p])
      
      ,.my_x_i(my_x_i)
      ,.my_y_i(my_y_i)
    );
  end


  // Vertical channels;
  for (genvar i = 0; i < 2; i++) begin: ver
    bsg_fifo_1r1w_small #(
      .width_p(width_p)
      ,.els_p(fifo_els_p[3+i])
    ) ver_fifo0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_i           (ver_link_in[i].v)
      ,.data_i        (ver_link_in[i].data)
      ,.ready_param_o (ver_link_out[i].ready_and_rev)

      ,.v_o           (vc_v_lo[5+i])
      ,.data_o        (vc_data_lo[5+i])
      ,.yumi_i        (vc_yumi_li[5+i])
    );

    bsg_half_torus_router_decode #(
      .x_cord_width_p(x_cord_width_p)
      ,.y_cord_width_p(y_cord_width_p)
      ,.XY_order_p(XY_order_p)
      ,.vc_id_p(0)
      ,.num_vc_p(num_vc_p)
      ,.base_x_cord_p(base_x_cord_p)
      ,.num_tiles_x_p(num_tiles_x_p)
      ,.from_p(i+3)
    ) ver_decode0 (
      .dest_x_i       (vc_data_lo[5+i][0+:x_cord_width_p])
      ,.dest_y_i      (vc_data_lo[5+i][x_cord_width_p+:y_cord_width_p])
      ,.my_x_i        (my_x_i)
      ,.my_y_i        (my_y_i)
      ,.sw_dir_sel_o  (sw_dir_sel_lo[5+i])
      ,.vc_dir_sel_o  (vc_dir_sel_lo[5+i])
    );
  end


  // allocator;
  logic [sw_dirs_lp-1:0][width_p-1:0] xbar_data_li;
  logic [sw_dirs_lp-1:0][sw_dirs_lp-1:0] xbar_sel_li;
  logic [vc_dirs_lp-1:0] alloc_link_v_lo, alloc_link_ready_li;

  bsg_half_torus_router_alloc #(
    .width_p(width_p)
    ,.num_vc_p(num_vc_p)
    ,.XY_order_p(XY_order_p)
  ) alloc0 (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    // VC side;
    ,.vc_v_i(vc_v_lo)
    ,.vc_data_i(vc_data_lo)
    ,.vc_dir_sel_i(vc_dir_sel_lo)
    ,.sw_dir_sel_i(sw_dir_sel_lo)
    ,.vc_yumi_o(vc_yumi_li)

    // crossbar;
    ,.xbar_data_o(xbar_data_li)
    ,.xbar_sel_o(xbar_sel_li)

    // output link side;
    ,.link_v_o(alloc_link_v_lo)
    ,.link_ready_i(alloc_link_ready_li)
  );


  // crossbar;
  logic [sw_dirs_lp-1:0][width_p-1:0] xbar_data_lo;
  bsg_torus_router_xbar #(
    .width_p(width_p)
    ,.XY_order_p(XY_order_p)
  ) xbar0 (
    .data_i   (xbar_data_li)
    ,.data_o  (xbar_data_lo)
    ,.sel_i   (xbar_sel_li)
  );


  // connect output links;
  assign proc_link_out.v = alloc_link_v_lo[0];
  assign proc_link_out.data = xbar_data_lo[0];
  assign alloc_link_ready_li[0] = proc_link_in.ready_and_rev;

  // hor;
  for (genvar i = 0; i < 2; i++) begin
    assign hor_link_out[i].v = alloc_link_v_lo[1+(num_vc_p*i)+:num_vc_p];
    assign hor_link_out[i].data = xbar_data_lo[1+i];
    assign alloc_link_ready_li[1+(num_vc_p*i)+:num_vc_p] = hor_link_in[i].ready_and_rev; 
  end

  // ver;
  for (genvar i = 0; i < 2; i++) begin
    assign ver_link_out[i].v = alloc_link_v_lo[5+i];
    assign ver_link_out[i].data = xbar_data_lo[3+i];
    assign alloc_link_ready_li[5+i] = ver_link_in[i].ready_and_rev; 
  end

endmodule
