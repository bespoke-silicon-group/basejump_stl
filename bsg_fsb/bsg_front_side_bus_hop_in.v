// mbt 9/8/2014
//
// bsg_front_side_bus_hop_in
//
// This implements the front side bus
// input side. In normal use, nodes
// must always keep their ready_i lines
// high and admit any data that arrives.
// Otherwise deadlock is likely, especially
// if multiple nodes are in use at once.
//
// This means in practice that every node
// needs an input buffer and must have
// some out-of-band mechanism for making
// sure that the buffer does not overflow.
//
// Although it is tempting
// to omit flow control and reduce
// this to a chain of registers,
// it creates a large overhead for
// doing simple, high bandwidth stream tests,
// which are one of the easiest ways
// to stress test the system.
// So we add the flow control.
// Let the hardware designer beware.


`include "bsg_defines.v"

module bsg_front_side_bus_hop_in

  #(parameter     width_p="inv"
    , parameter fan_out_p=2
    )

   (input clk_i
    , input reset_i

    // from previous hop
    , output              ready_o
    , input                   v_i
    , input [width_p-1:0]  data_i

    // 0 is to the next hop
    // 1 is to the local switch

    , output [fan_out_p-1:0]                   v_o
    , output [fan_out_p-1:0] [width_p-1:0]  data_o
    , input  [fan_out_p-1:0]               ready_i
    );

   logic [fan_out_p-1:0] sent_r, sent_n;

   genvar 		 i;

   logic [fan_out_p-1:0]    v_o_tmp;
   logic [width_p-1:0]   data_o_tmp;

   wire                fifo_v, fifo_yumi;

   bsg_two_fifo #(.width_p(width_p)) fifo
     (.clk_i    (clk_i)
      ,.reset_i (reset_i)
      ,.data_i  (data_i)
      ,.data_o  (data_o_tmp)
      ,.v_o     (fifo_v)
      ,.yumi_i  (fifo_yumi)
      ,.ready_o (ready_o)
      ,.v_i     (v_i)
      );

   for (i = 0; i < fan_out_p; i = i+1)
     begin
        assign data_o[i] = data_o_tmp;
	assign v_o   [i] =    v_o_tmp[i];

        // we have data and we haven't sent it
        assign v_o_tmp[i] = fifo_v & ~sent_r[i];

        always_ff @(posedge clk_i)
          if (reset_i)
            sent_r[i] <= 1'b0;
          else
            sent_r[i] <= sent_n[i] & ~fifo_yumi;

        always_comb
          begin
             sent_n[i] = sent_r[i];

             // if we have data,
             if (v_o_tmp[i] & ready_i[i])
               sent_n[i] = 1'b1;

          end // always_comb
      end

   assign fifo_yumi = & sent_n;

endmodule

