`include "bsg_defines.v"

module bsg_fsb_to_htif_connector
  import bsg_fsb_pkg::RingPacketType;

   #(parameter htif_width_p
     ,parameter fsb_width_p=$size(RingPacketType)
     ,parameter destid_p="inv"
     )
   (input clk_i
    ,input  reset_i

    ,input  fsb_v_i
    ,input  [fsb_width_p-1:0] fsb_data_i
    ,output fsb_ready_o

    ,output fsb_v_o
    ,output [fsb_width_p-1:0] fsb_data_o
    ,input  fsb_yumi_i

    // FROM htif
    ,input  htif_v_i
    ,input  [htif_width_p-1:0] htif_data_i
    ,output htif_ready_o

    // TO htif
    ,output htif_v_o
    ,output [htif_width_p-1:0] htif_data_o
    ,input  htif_ready_i
    );

   RingPacketType pkt_in = fsb_data_i;
   RingPacketType pkt_out;

   assign fsb_data_o = pkt_out;

   assign htif_v_o    = fsb_v_i;

   // toss the rest
   assign htif_data_o = pkt_in.data[htif_width_p-1:0];
   assign fsb_ready_o = htif_ready_i;

   bsg_two_fifo #(.width_p(htif_width_lp)
                  )
   (.clk_i    (clk_i  )
    ,.reset_i (reset_i)

    ,.v_i     ( htif_v_i     )
    ,.data_i  ( htif_data_i  )
    ,.ready_o ( htif_ready_o )

    ,.v_o     ( fsb_v_o    )
    ,.data_o  ( pkt_out.data[htif_width_p-1:0] )
    ,.yumi_i  ( fsb_yumi_i )

    );

   assign pkt_out.srcid  = 4'b0; // fixme
   assign pkt_out.destid = destid_p;
   assign pkt_out.cmd    = 1'b0;
   assign pkt_out.opcode = 7'b0;
   assign pkt_out.data[63:htif_width_p] = '0;

endmodule





