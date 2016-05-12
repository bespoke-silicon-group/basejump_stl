module bsg_mesh_router_buffered #(width_p        = -1
                                  ,x_cord_width_p = -1
                                  ,y_cord_width_p = -1
                                  ,debug_p       = 0
                                  ,dirs_lp       = 5
                                  ,stub_p        = { dirs_lp {1'b0}}  // SNEWP
                                  )
   (
    input clk_i
    , input reset_i

    , input [dirs_lp-1:0]              v_i
    , input [dirs_lp-1:0][width_p-1:0] data_i
    , output logic [dirs_lp-1:0]       ready_o

    , output [dirs_lp-1:0]              v_o
    , output [dirs_lp-1:0][width_p-1:0] data_o
    , input  [dirs_lp-1:0]              ready_i

    , input [x_cord_width_p-1:0] my_x_i
    , input [y_cord_width_p-1:0] my_y_i
    );

   logic [dirs_lp-1:0]              fifo_valid;
   logic [dirs_lp-1:0][width_p-1:0] fifo_data;
   logic [dirs_lp-1:0]              fifo_yumi;

   if (debug_p)
     always_ff @(negedge clk_i)
       $display("%m SNEWP v_i=%b ready_o=%b v_o=%b ready_i=%b",v_i,ready_o,v_o,ready_i);

   genvar                           i;

   for (i = 0; i < dirs_lp; i=i+1)
     begin: rof
        if (stub_p[i])
          begin: fi
             assign fifo_data   [i] = width_p ' (0);
             assign fifo_valid  [i] = 1'b0;

             // accept no data from outside of stubbed port
             assign ready_o     [i] = 1'b0;

             // synopsys translate off
             always @(negedge clk_i)
               if (v_o[i])
                 $display("## warning %m: stubbed port %x consumed word %x",i,data_i[i]);
             // synopsys translate on
          end
        else
          begin: fi
             bsg_two_fifo #(.width_p(width_p))
             twofer
               (.clk_i
                ,.reset_i

                ,.v_i     (v_i [i])
                ,.data_i  (data_i  [i])
                ,.ready_o (ready_o [i])

                ,.v_o     (fifo_valid[i])
                ,.data_o  (fifo_data [i])
                ,.yumi_i  (fifo_yumi [i])
                );
          end
     end

   bsg_mesh_router #( .width_p      (width_p      )
                     ,.x_cord_width_p(x_cord_width_p)
                     ,.y_cord_width_p(y_cord_width_p)
                     ,.debug_p      (debug_p      )
                     ,.stub_p       (stub_p       )
                     ) bmr
   (.clk_i
    ,.reset_i
    ,.v_i    (fifo_valid)
    ,.data_i (fifo_data )
    ,.yumi_o (fifo_yumi )

    ,.v_o
    ,.data_o

    // this will be hardwired to 1 by inside of this module
    // if port is stubbed

    ,.ready_i

    ,.my_x_i
    ,.my_y_i
    );


endmodule

