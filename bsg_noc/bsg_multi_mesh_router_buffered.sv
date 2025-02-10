/**
 *    bsg_multi_mesh_router_buffered.sv
 *
 */


`include "bsg_defines.sv"
`include "bsg_noc_links.svh"


module bsg_multi_mesh_router_buffered
  import bsg_mesh_router_pkg::*;
  #(parameter `BSG_INV_PARAM(width_p        )
    , parameter `BSG_INV_PARAM(x_cord_width_p )
    , parameter `BSG_INV_PARAM(y_cord_width_p )
    , parameter debug_p       = 0
    , parameter ruche_factor_X_p = 0
    , parameter ruche_factor_Y_p = 0
    , parameter dims_p        = 2
    , parameter dirs_lp       = (2*dims_p)+1
    , parameter stub_p        = { dirs_lp {1'b0}}  // SNEWP
    , parameter XY_order_p    = 1
    , parameter depopulated_p = 1
    , parameter bsg_ready_and_link_sif_width_lp=`bsg_ready_and_link_sif_width(width_p)
    // select whether to buffer the output
    , parameter repeater_output_p = { dirs_lp {1'b0}}  // SNEWP
    // credit interface
    , parameter use_credits_p = {dirs_lp{1'b0}}
    , parameter int fifo_els_p[dirs_lp-1:0] = '{2,2,2,2,2}
  )
  (
    input clk_i
    , input reset_i

    , input  [dirs_lp-2:0][1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
    , output [dirs_lp-2:0][1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o

    , input  [bsg_ready_and_link_sif_width_lp-1:0] proc_link_i
    , output [bsg_ready_and_link_sif_width_lp-1:0] proc_link_o

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
  );


  // Cast local links;
  `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);
  bsg_ready_and_link_sif_s [dirs_lp-1:1][1:0] link_i_cast, link_o_cast;
  assign link_i_cast = link_i;
  assign link_o = link_o_cast;

  bsg_ready_and_link_sif_s [1:0][dirs_lp-1:1] link_i_tp, link_o_tp;
  for (genvar i = 0; i < 2; i++) begin
    for (genvar j = 1; j < dirs_lp; j++) begin
      assign link_i_tp[i][j] = link_i_cast[j][i];
      assign link_o_cast[j][i] = link_o_tp[i][j];
    end
  end


  // proc link cast;
  bsg_ready_and_link_sif_s  proc_link_i_cast, proc_link_o_cast;
  assign proc_link_i_cast = proc_link_i;
  assign proc_link_o = proc_link_o_cast;

   
  // Input FIFOs;
  logic [1:0][dirs_lp-1:1]              fifo_valid_lo, fifo_yumi, fifo_ready_lo;
  logic [1:0][dirs_lp-1:1][width_p-1:0] fifo_data_lo;

  for (genvar i = 0; i < 2; i++) begin: rof1
    for (genvar j = 1; j < dirs_lp; j++) begin: rof2

      if (stub_p[j]) begin: fi

        assign fifo_data_lo   [i][j] = width_p ' (0);
        assign fifo_valid_lo  [i][j] = 1'b0;
        // accept no data from outside of stubbed port
        assign link_o_tp[i][j].ready_and_rev = 1'b0;

      end
      else begin: fi
        bsg_fifo_1r1w_small #(
          .width_p(width_p)
          ,.els_p(fifo_els_p[j])
        ) fifo (
          .clk_i(clk_i)
          ,.reset_i(reset_i)

          ,.v_i           (link_i_tp[i][j].v            )
          ,.data_i        (link_i_tp[i][j].data         )
          ,.ready_param_o (fifo_ready_lo[i][j])

          ,.v_o           (fifo_valid_lo[i][j])
          ,.data_o        (fifo_data_lo[i][j])
          ,.yumi_i        (fifo_yumi [i][j])
        );
      
        if (use_credits_p[1]) begin: cr
          bsg_dff_reset #(
            .width_p(1)
            ,.reset_val_p(0)
          ) dff0 (
            .clk_i(clk_i)
            ,.reset_i(reset_i)
            ,.data_i(fifo_yumi[i][j])
            ,.data_o(link_o_tp[i][j].ready_and_rev)
          );
        
          `ifndef BSG_HIDE_FROM_SYNTHESIS
          always_ff @ (negedge clk_i) begin
            if (~reset_i) begin
              if (link_i_tp[i][j].v) begin
                assert(fifo_ready_lo[i][j])
                  else $error("Trying to enque when there is no space in FIFO, while using credit interface. i =%d", i);
              end
            end
          end
          `endif
        end
        else begin
          assign link_o_tp[i][j].ready_and_rev = fifo_ready_lo[i][j];
        end
      end

    end
  end



  // Proc FIFO;
  logic proc_fifo_ready_lo;
  logic proc_fifo_valid, proc_fifo_yumi;
  logic [width_p-1:0] proc_fifo_data;

  bsg_fifo_1r1w_small #(
    .width_p(width_p)
    ,.els_p(fifo_els_p[0])
  ) fifo (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.v_i           (proc_link_i_cast.v)
    ,.data_i        (proc_link_i_cast.data)
    ,.ready_param_o (proc_fifo_ready_lo)

    ,.v_o           (proc_fifo_valid)
    ,.data_o        (proc_fifo_data )
    ,.yumi_i        (proc_fifo_yumi )
  );
      
  if (use_credits_p[0]) begin: cr
    bsg_dff_reset #(
      .width_p(1)
      ,.reset_val_p(0)
    ) dff0 (
      .clk_i(clk_i)
      ,.reset_i(reset_i)
      ,.data_i(proc_fifo_yumi)
      ,.data_o(proc_link_o_cast.ready_and_rev)
    );
  
  end
  else begin
    assign proc_link_o_cast.ready_and_rev = proc_fifo_ready_lo;
  end

  
  // Decode proc packet;
  logic [y_cord_width_p-1:0] proc_y_dest;
  logic [x_cord_width_p-1:0] proc_x_dest;
  assign {proc_y_dest, proc_x_dest} = proc_fifo_data[y_cord_width_p+x_cord_width_p-1:0];
  wire [y_cord_width_p+x_cord_width_p-1:0] yx_distance = (my_x_i - proc_x_dest) + (my_y_i - proc_y_dest);

  logic [1:0] proc_v_decoded;
  bsg_decode_with_v #(
    .num_out_p(2)
  ) dv0 (
    .i(yx_distance[0])
    ,.v_i(proc_fifo_valid)
    ,.o(proc_v_decoded)
  );

  logic [1:0] proc_router_yumi_lo;
  assign proc_fifo_yumi = |proc_router_yumi_lo;


  // Instantiate routers;
  logic [1:0][dirs_lp-1:0] router_v_lo, router_ready_li;
  logic [1:0][dirs_lp-1:0][width_p-1:0] router_data_lo;

  for (genvar i = 0; i < 2; i++) begin: rtr
    bsg_mesh_router #(
      .width_p          (width_p      )
      ,.x_cord_width_p  (x_cord_width_p)
      ,.y_cord_width_p  (y_cord_width_p)
      ,.ruche_factor_X_p(ruche_factor_X_p)
      ,.ruche_factor_Y_p(ruche_factor_Y_p)
      ,.dims_p          (dims_p)
      ,.XY_order_p      (XY_order_p   )
      ,.depopulated_p   (depopulated_p   )
    ) bmr0 (
      .clk_i
      ,.reset_i

      ,.v_i    ({fifo_valid_lo[i], proc_v_decoded[i]})
      ,.data_i ({fifo_data_lo[i], proc_fifo_data})
      ,.yumi_o ({fifo_yumi[i], proc_router_yumi_lo[i]})

      ,.v_o         (router_v_lo[i])
      ,.data_o      (router_data_lo[i])
      ,.ready_and_i (router_ready_li[i])

      ,.my_x_i
      ,.my_y_i
    );

    // connect local links;
    for (genvar j = 1; j < dirs_lp; j++) begin
      assign link_o_tp[i][j].v = router_v_lo[i][j];
      assign link_o_tp[i][j].data = router_data_lo[i][j];
      assign router_ready_li[i][j] = link_i_tp[i][j].ready_and_rev;
    end
  end


  // Connect Proc Output;
  logic [1:0] proc_grants_lo;
  logic proc_rr_yumi;

  bsg_arb_round_robin #(
    .width_p(2)
  ) proc_rr (
    .clk_i(clk_i)
    ,.reset_i(reset_i)

    ,.reqs_i({router_v_lo[1][0], router_v_lo[0][0]})
    ,.grants_o(proc_grants_lo)
    ,.yumi_i(proc_rr_yumi)
  );

  bsg_mux_one_hot #(
    .els_p(2)
    ,.width_p(width_p)
  ) proc_mux (
    .data_i({router_data_lo[1][0], router_data_lo[0][0]})
    ,.sel_one_hot_i(proc_grants_lo)
    ,.data_o(proc_link_o_cast.data)
  );
  
  assign proc_link_o_cast.v = |{router_v_lo[1][0], router_v_lo[0][0]};
  assign proc_rr_yumi = proc_link_o_cast.v & proc_link_i_cast.ready_and_rev;
  assign router_ready_li[1][0] = proc_grants_lo[1] & proc_link_i_cast.ready_and_rev;
  assign router_ready_li[0][0] = proc_grants_lo[0] & proc_link_i_cast.ready_and_rev;
  



endmodule

`BSG_ABSTRACT_MODULE(bsg_multi_mesh_router_buffered)

