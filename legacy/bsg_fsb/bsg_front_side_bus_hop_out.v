// bsg_front_side_hop_out
//
// this implements the front side bus,
// output side. it has backwards flow
// control, since naturally output i/o
// can be a bottleneck.
//
// we do approx round robin between port 0
// and port 1, which is local.
//
// this is a legacy implementation, instead you can look at using
// bsg_router_crossbar_o_by_i, specifically the example 
// contained in https://github.com/bespoke-silicon-group/basejump_stl/tree/master/testing/bsg_noc/bsg_router_crossbar_o_by_i/i2_o1
//

`include "bsg_defines.sv"

module bsg_front_side_bus_hop_out #(parameter `BSG_INV_PARAM(width_p))
  (input clk_i
   , input  reset_i

   // 0 = previous switch
   // 1 = local node

   , input  [1:0]         v_i         // late
   , input  [1:0][width_p-1:0] data_i // late
   , output               ready_o     // to prev switch; early
   , output               yumi_o      // to local node;  late

   // to next switch
   , output               v_o     // early
   , output [width_p-1:0] data_o
   , input                ready_i // late
   );

   wire               fifo_v;
   wire               fifo_ready;

   logic              v1_blocked_r;

   // we select the local port if the remote node is not
   // sending; or if local port was blocked last cycle

   wire               source_sel = ~v_i[0] | v1_blocked_r;


   // local send
   wire yumi_o_tmp  = (fifo_ready & v_i[1]) & source_sel;
   assign yumi_o = yumi_o_tmp;

   // update "local blocked" signal
   // only when the fifo is ready
   //

   always_ff @(posedge clk_i)
     v1_blocked_r <= reset_i
                     ? 1'b0
                     : (fifo_ready
                        ? (v_i[1] & ~source_sel)
                        : v1_blocked_r
                        );

   bsg_two_fifo #(.width_p(width_p)) fifo
     (.clk_i          (clk_i)
      ,.reset_i       (reset_i)
      ,.data_i        (data_i[source_sel])
      ,.data_o        (data_o)
      ,.v_o           (fifo_v)
      ,.yumi_i        (fifo_v & ready_i)
      ,.ready_param_o (fifo_ready)
      ,.v_i           (| v_i)
      );

   assign v_o     =  fifo_v;

   // tell remote note we are ready if there is
   // fifo space, and we are not creating a slot
   // for the local node

   assign ready_o =  fifo_ready & ~v1_blocked_r;





endmodule

`BSG_ABSTRACT_MODULE(bsg_front_side_bus_hop_out)
