/**
 *    bsg_mesh_router_buffered.v
 *
 */


`include "bsg_defines.v"
`include "bsg_noc_links.vh"


module bsg_mesh_router_buffered
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

    , input  [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_i
    , output [dirs_lp-1:0][bsg_ready_and_link_sif_width_lp-1:0] link_o

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
  );

   `declare_bsg_ready_and_link_sif_s(width_p,bsg_ready_and_link_sif_s);

   bsg_ready_and_link_sif_s [dirs_lp-1:0] link_i_cast, link_o_cast;

   assign link_i_cast =link_i;
   assign link_o = link_o_cast;

   logic [dirs_lp-1:0]              fifo_valid;
   logic [dirs_lp-1:0][width_p-1:0] fifo_data;
   logic [dirs_lp-1:0]              fifo_yumi;

   genvar                           i;

   //synopsys translate_off
   if (debug_p)
     for (i = 0; i < dirs_lp;i=i+1)
       begin
          always_ff @(negedge clk_i)
            $display("%m x=%d y=%d SNEWP[%d] v_i=%b ready_o=%b v_o=%b ready_i=%b %b"
                     ,my_x_i,my_y_i,i,link_i_cast[i].v,link_o_cast[i].ready_and_rev,
                     link_o_cast[i].v,link_i_cast[i].ready_and_rev,link_i[i]);
       end
   //synopsys translate_on

  for (i = 0; i < dirs_lp; i=i+1) begin: rof
    if (stub_p[i]) begin: fi
      assign fifo_data   [i] = width_p ' (0);
      assign fifo_valid  [i] = 1'b0;

      // accept no data from outside of stubbed port
      assign link_o_cast[i].ready_and_rev = 1'b0;

      // synopsys translate_off
      always @(negedge clk_i)
        assert (reset_i !== '0 || ~link_o_cast[i].v) else
          $warning("## stubbed port %x received word %x",i,link_i_cast[i].data);
      // synopsys translate_on
    end
    else begin: fi
      logic fifo_ready_lo;

      bsg_fifo_1r1w_small #(
        .width_p(width_p)
        ,.els_p(fifo_els_p[i])
      ) fifo (
        .clk_i(clk_i)
        ,.reset_i(reset_i)

        ,.v_i     (link_i_cast[i].v            )
        ,.data_i  (link_i_cast[i].data         )
        ,.ready_o (fifo_ready_lo)

        ,.v_o     (fifo_valid[i])
        ,.data_o  (fifo_data [i])
        ,.yumi_i  (fifo_yumi [i])
      );
      
      if (use_credits_p[i]) begin: cr
        bsg_dff_reset #(
          .width_p(1)
          ,.reset_val_p(0)
        ) dff0 (
          .clk_i(clk_i)
          ,.reset_i(reset_i)
          ,.data_i(fifo_yumi[i])
          ,.data_o(link_o_cast[i].ready_and_rev)
        );
        
        // synopsys translate_off
        always_ff @ (negedge clk_i) begin
          if (~reset_i) begin
            if (link_i_cast[i].v) begin
              assert(fifo_ready_lo)
                else $error("Trying to enque when there is no space in FIFO, while using credit interface. i =%d", i);
            end
          end
        end
        // synopsys translate_on

      end
      else begin
        assign link_o_cast[i].ready_and_rev = fifo_ready_lo;      
      end

    end
  end

   // router does not have symmetric interfaces;
   // so we do not use bsg_ready_and_link_sif
   // and manually convert. support for arrays
   // of interfaces in systemverilog would
   // fix this.

   logic [dirs_lp-1:0]              valid_lo;
   logic [dirs_lp-1:0][width_p-1:0] data_lo;
   logic [dirs_lp-1:0]              ready_li;

   for (i = 0; i < dirs_lp; i=i+1)
     begin: rof2
        assign link_o_cast[i].v    = valid_lo[i];

        if (repeater_output_p[i] & ~stub_p[i])
          begin : macro
	     wire [width_p-1:0] tmp;

            // synopsys translate_off
            initial
               begin
                  $display("%m with buffers on %d",i);
               end
            // synopsys translate_on
             bsg_inv #(.width_p(width_p),.vertical_p(i < 3)) data_lo_inv
               (.i (data_lo[i]         )
                ,.o(tmp)
                );

             bsg_inv #(.width_p(width_p),.vertical_p(i < 3)) data_lo_rep
               (.i (tmp)
                ,.o(link_o_cast[i].data)
                );

          end
        else
          assign link_o_cast[i].data = data_lo [i];

        assign ready_li[i] = link_i_cast[i].ready_and_rev;
     end

   bsg_mesh_router #( .width_p      (width_p      )
                      ,.x_cord_width_p(x_cord_width_p)
                      ,.y_cord_width_p(y_cord_width_p)
                      ,.ruche_factor_X_p(ruche_factor_X_p)
                      ,.ruche_factor_Y_p(ruche_factor_Y_p)
                      ,.dims_p        (dims_p)
                      ,.XY_order_p   (XY_order_p   )
                      ,.depopulated_p  (depopulated_p   )
                      ) bmr
   (.clk_i
    ,.reset_i
    ,.v_i    (fifo_valid)
    ,.data_i (fifo_data )
    ,.yumi_o (fifo_yumi )

    ,.v_o   (valid_lo)
    ,.data_o(data_lo)

    // this will be hardwired to 1 by inside of this module
    // if port is stubbed

    ,.ready_i(ready_li)

    ,.my_x_i
    ,.my_y_i
    );


endmodule

`BSG_ABSTRACT_MODULE(bsg_mesh_router_buffered)

