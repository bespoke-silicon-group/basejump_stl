//====================================================================
// bsg_fsb_node_async_buffer.v
// 19/05/2018, shawnless.xie@gmail.com
//====================================================================
//
//This module converts the bsg_fsb node  signals between different
//clock domains.
//
//default: FSB  on Right, 
//         NODE on Left

`include "bsg_defines.v"

`ifndef FSB_LEGACY 
module  bsg_fsb_node_async_buffer 
  #(  parameter ring_width_p="inv"
     ,parameter fifo_els_p    = 2
    )
  (  
   /////////////////////////////////////////////
   // signals on the node side
     input L_clk_i
   , input L_reset_i
   // control
   , output L_en_o   // FIXME unused

   // input channel
   , output L_v_o
   , output [ring_width_p-1:0] L_data_o
   , input  L_ready_i

   // output channel
   , input  L_v_i
   , input [ring_width_p-1:0] L_data_i
   , output  L_yumi_o   // late

   /////////////////////////////////////////////
   // signals on the FSB side
   , input R_clk_i
   , input R_reset_i

   // control
   , input R_en_i   // FIXME unused

   // input channel
   , input  R_v_i
   , input [ring_width_p-1:0] R_data_i
   , output R_ready_o

   // output channel
   , output R_v_o
   , output [ring_width_p-1:0] R_data_o
   , input  R_yumi_i   // late
   );

   localparam fifo_lg_size_lp        = `BSG_SAFE_CLOG2( fifo_els_p );

   ////////////////////////////////////////////////////////////////////////////////////////
   // Covert FSB  to NODE  packet signals
   // FSB   == w
   // NODE  == r 
   wire R_w_full_lo  ;
   assign R_ready_o = ~R_w_full_lo ;
   bsg_async_fifo #(.lg_size_p  ( fifo_lg_size_lp          )
                    ,.width_p    ( ring_width_p   )
                    )r2l_fifo
   (
     .w_clk_i   ( R_clk_i    )
    ,.w_reset_i ( R_reset_i  )
    // not legal to w_enq_i if w_full_o is not low.
    ,.w_enq_i   ( (~R_w_full_lo) & R_v_i )
    ,.w_data_i  ( R_data_i  )
    ,.w_full_o  ( R_w_full_lo   )

    // not legal to r_deq_i if r_valid_o is not high.
    ,.r_clk_i   ( L_clk_i      )
    ,.r_reset_i ( L_reset_i    )
    ,.r_deq_i   ( L_v_o & L_ready_i  )
    ,.r_data_o  ( L_data_o     )
    ,.r_valid_o ( L_v_o )
    );

   ////////////////////////////////////////////////////////////////////////////////////////
   // Covert NODE  to FSB packet signals
   // FSB   == r
   // NODE  == w 
   wire   L_w_full_lo  ;
   assign L_yumi_o = (~L_w_full_lo) & L_v_i ;

   bsg_async_fifo #(.lg_size_p  ( fifo_lg_size_lp          )
                    ,.width_p    ( ring_width_p   )
                    )l2r_fifo
   (
     .w_clk_i   ( L_clk_i    )
    ,.w_reset_i ( L_reset_i  )
    // not legal to w_enq_i if w_full_o is not low.
    ,.w_enq_i   ( L_yumi_o   )
    ,.w_data_i  ( L_data_i   )
    ,.w_full_o  ( L_w_full_lo)

    // not legal to r_deq_i if r_valid_o is not high.
    ,.r_clk_i   ( R_clk_i      )
    ,.r_reset_i ( R_reset_i    )
    ,.r_deq_i   ( R_yumi_i     )
    ,.r_data_o  ( R_data_o     )
    ,.r_valid_o ( R_v_o        )
    );

  bsg_sync_sync #(.width_p(1)) fsb_en_sync
   (
      .oclk_i       ( L_clk_i   )   //TODO
    , .iclk_data_i  ( R_en_i    )
    , .oclk_data_o  ( L_en_o    )
    );

endmodule
`else
// |  ____/ ____|  _ \ | |    |  ____/ ____|   /\   / ____\ \   / / 
// | |__ | (___ | |_) || |    | |__ | |  __   /  \ | |     \ \_/ /  
// |  __| \___ \|  _ < | |    |  __|| | |_ | / /\ \| |      \   /   
// | |    ____) | |_) || |____| |___| |__| |/ ____ \ |____   | |    
// |_|   |_____/|____/ |______|______\_____/_/    \_\_____|  |_|    
//                 ______                                           
//                |______|   

module  bsg_fsb_node_async_buffer 
        import bsg_fsb_pkg::*;
  #(  parameter ring_width_p="inv"
     ,parameter fifo_els_p    = 2
    )
  (  
   /////////////////////////////////////////////
   // signals on the node side
     input L_clk_i
   , input L_reset_i
   // control
   , output L_en_o   // FIXME unused

   // input channel
   , output L_v_o
   , output [ring_width_p-1:0] L_data_o
   , input  L_ready_i

   // output channel
   , input  L_v_i
   , input [ring_width_p-1:0] L_data_i
   , output  L_yumi_o   // late

   /////////////////////////////////////////////
   // signals on the FSB side
   , input R_clk_i
   , input R_reset_i

   // control
   , input R_en_i   // FIXME unused

   // input channel
   , input  R_v_i
   , input [ring_width_p-1:0] R_data_i
   , output R_ready_o

   // output channel
   , output R_v_o
   , output [ring_width_p-1:0] R_data_o
   , input  R_yumi_i   // late
   );

   localparam fifo_lg_size_lp        = `BSG_SAFE_CLOG2( fifo_els_p );

   ////////////////////////////////////////////////////////////////////////////////////////
   // Covert FSB  to NODE  packet signals
   // FSB   == w
   // NODE  == r 
   wire R_w_full_lo  ;
   assign R_ready_o = ~R_w_full_lo ;
   bsg_async_fifo #(.lg_size_p  ( fifo_lg_size_lp          )
                    ,.width_p    ( ring_width_p   )
                    )r2l_fifo
   (
     .w_clk_i   ( R_clk_i    )
    ,.w_reset_i ( R_reset_i  )
    // not legal to w_enq_i if w_full_o is not low.
    ,.w_enq_i   ( (~R_w_full_lo) & R_v_i )
    ,.w_data_i  ( R_data_i  )
    ,.w_full_o  ( R_w_full_lo   )

    // not legal to r_deq_i if r_valid_o is not high.
    ,.r_clk_i   ( L_clk_i      )
    ,.r_reset_i ( L_reset_i    )
    ,.r_deq_i   ( L_v_o & L_ready_i  )
    ,.r_data_o  ( L_data_o     )
    ,.r_valid_o ( L_v_o )
    );

   ////////////////////////////////////////////////////////////////////////////////////////
   // Covert NODE  to FSB packet signals
   // FSB   == r
   // NODE  == w 
   wire   L_w_full_lo  ;
   assign L_yumi_o = (~L_w_full_lo) & L_v_i ;

   bsg_async_fifo #(.lg_size_p  ( fifo_lg_size_lp          )
                    ,.width_p    ( ring_width_p   )
                    )l2r_fifo
   (
     .w_clk_i   ( L_clk_i    )
    ,.w_reset_i ( L_reset_i  )
    // not legal to w_enq_i if w_full_o is not low.
    ,.w_enq_i   ( L_yumi_o   )
    ,.w_data_i  ( L_data_i   )
    ,.w_full_o  ( L_w_full_lo)

    // not legal to r_deq_i if r_valid_o is not high.
    ,.r_clk_i   ( R_clk_i      )
    ,.r_reset_i ( R_reset_i    )
    ,.r_deq_i   ( R_yumi_i     )
    ,.r_data_o  ( R_data_o     )
    ,.r_valid_o ( R_v_o        )
    );

  bsg_sync_sync #(.width_p(1)) fsb_en_sync
   (
      .oclk_i       ( L_clk_i   )   //TODO
    , .iclk_data_i  ( R_en_i    )
    , .oclk_data_o  ( L_en_o    )
    );

endmodule
`endif
