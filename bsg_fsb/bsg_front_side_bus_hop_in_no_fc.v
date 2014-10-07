// bsg_front_side_bus_hop_in
//
// this implements the front side bus
// input side. it does *not* have backwards
// flow control, since nodes are supposed
// to have enough buffering to accept
// all incoming packets.
//

module bsg_front_side_hop_in

  #(parameter width_p="inv")

   (input clk_i
    , input reset_i

    , input                   v_i
    , input [width_p-1:0]  data_i

    // 0 is to the next switch
    // 1 is to the local switch

    , output [1:0]               v_o
    , output [1:0] [width_p-1:0] data_o

    // from next switch
    , input  ready_i
    );

   logic               v_r;
   logic [width_p-1:0] data_r;

   // fixme: trade logic/speed for power
   // and avoid fake transitions

   assign v_o   [0] = v_r;
   assign data_o[0] = data_r;

   // to local node
   assign    v_o[1] = v_r; // & is_me
   assign data_o[1] = data_r;

   always @(posedge clk_i)
     begin
        // nullify valid bit on reset
        v_r    <= reset_i ? v_i: 1'b0;
        data_r <= data_o;
     end

endmodule

