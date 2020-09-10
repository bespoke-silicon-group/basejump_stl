// mbt 11/26/2014
//
// bsg_murn_converter
//
//
// converts between bsg_comm_link interface to fsb nodes
// and murn interface to fsb nodes
//
//
// note: generally speaking, murn switch interfaces
// are valid->retry (e.g switch->switch, switch->block.
// However the path from block to switch
// is retry->valid.
//

`include "bsg_defines.v"

module bsg_murn_converter
  #(parameter nodes_p="inv"
    , parameter ring_width_p="inv"
    )
   (
    input clk_i
    , input [nodes_p-1:0] reset_i

    // to murn node
    , input  [nodes_p-1:0]      v_i
    , output [nodes_p-1:0]      ready_o
    , input  [ring_width_p-1:0] data_i [nodes_p-1:0]

    , output [nodes_p-1:0]      switch_2_blockValid
    , input  [nodes_p-1:0]      switch_2_blockRetry
    , output [ring_width_p-1:0] switch_2_blockData [nodes_p-1:0]

    // from murn node

    , input  [nodes_p-1:0]      block_2_switchValid
    , output [nodes_p-1:0]      block_2_switchRetry
    , input  [ring_width_p-1:0] block_2_switchData [nodes_p-1:0]

    , output [nodes_p-1:0]      v_o
    , input  [nodes_p-1:0]      yumi_i
    , output [ring_width_p-1:0] data_o  [nodes_p-1:0]
    );

   bsg_flow_convert #(.width_p(nodes_p)
                      ,.send_v_and_ready_p(1)
                      ,.recv_v_and_retry_p(1)
                      ) s2b
   (.v_i  (v_i)
    ,.fc_o(ready_o)

    ,.v_o(switch_2_blockValid)
    ,.fc_i(switch_2_blockRetry)
    );

   assign switch_2_blockData = data_i;

   //
   // the ALU module's valid out
   // depends on the incoming retry (e.g. retry->valid)
   // but we need to interface to a valid/yumi.
   // which means we need a 2-element fifo.
   //

   wire [nodes_p-1:0] block_2_switchValid_2;
   wire [nodes_p-1:0] block_2_switchReady;

   bsg_flow_convert #(.width_p(nodes_p)
                      ,.send_retry_then_v_p(1)
                      ,.recv_v_and_ready_p(1)
                      ) b2s
   (.v_i  (block_2_switchValid)
    ,.fc_o(block_2_switchRetry)

    ,.v_o(block_2_switchValid_2)
    ,.fc_i(block_2_switchReady)
    );

   genvar i;

   for (i = 0; i < nodes_p; i++)
     begin : n
        bsg_two_fifo #(.width_p(ring_width_p))
        twofer (.clk_i(clk_i)
                ,.reset_i(reset_i[i])

                ,.ready_o(block_2_switchReady[i])
                ,.data_i (block_2_switchData[i] )
                ,.v_i    (block_2_switchValid[i])

                ,.v_o    (v_o[i]      )
                ,.data_o (data_o[i])
                ,.yumi_i (yumi_i[i]   )
                );
     end

endmodule
