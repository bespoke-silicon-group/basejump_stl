// bsg_wormhole_broadcast
//
// Implements a 1-D broadcast for wormhole style messages
// As with bsg_wormhole_router, the low bits are the coordinate bits
// and the next lowest bits are the length of the packet.
// If the coordinate bits are all 1's, the data gets broadcasted
// to all nodes. If the coordinate bits are 0, it goes to the local node
// (located at index 0 of the output signals). If the coordinate bits
// are neither 0 nor all 1's, then the coordinate is decremented and the packet
// is forwarded to the next node (located at index 1).
//
// NOTE: A key requirement for this module is that the endpoints
// must always be able to sink their incoming data independent
// of stall conditions on other networks, for example that those
// endpoints might be trying to send data on. Since the stalls
// of multiple nodes are coupled, it is problematic if they may
// have some other stall condition that is also coupled. For example
// imagine if the nodes are connected by a second network, and forward progress
// of the first network depends on the second network. The second network
// may have its own stall dependences, forming a cycle with the dependence
// chain through the first network.
//
// A 2D broadcast network could be created by instantiating an X wormhole broadcast network
// and then a bunch of Y wormhole networks (creating a kind of fishbone topology), and a small
// packet translation facilitate that shifts a Y coordinate from the upper header bits into the 
// lowest coordinate bits. As long as the second networks are all sinking their traffic independently
// of each other, this would not deadlock.

module bsg_wormhole_broadcast
	#(parameter `BSG_INV_PARAM(flit_width_p)  // naming is consistent with bsg_wormhold_concentrator_in
    , `BSG_INV_PARAM(len_width_p)
    , `BSG_INV_PARAM(cord_width_p)
    )
  (input clk_i
   , input reset_i

   , input v_i
   , input [flit_width_p-1:0] data_i
   , output ready_and_o

   , output [1:0] v_o
   , output [1:0][flit_width_p-1:0] data_o
   , input  [1:0] ready_and_i
   );

   wire v_lo, yumi_li;
   wire [flit_width_p-1:0] data_lo;

   logic [flit_width_p-1:0] data_lo_mod;
   
   bsg_two_fifo #(.width_p(flit_width_p)) twofer
     (.clk_i(clk_i)
      ,.reset_i(reset_i)

      ,.v_i(v_i)
      ,.data_i(data_i)
      ,.ready_param_o(ready_and_o)

      ,.v_o(v_lo)
      ,.data_o(data_lo)
      ,.yumi_i(yumi_li)
      );

   wire expecting_header_r_lo;
   logic [1:0] dest_vec_decode, dest_vec_r, dest_vec_byp;
   logic [1:0] pending_n, pending_r, pending_byp;

   bsg_wormhole_router_packet_parser #(.payload_len_bits_p(len_width_p)) pp
   (.clk_i                (clk_i)
    ,.reset_i             (reset_i)
    ,.fifo_v_i            (v_lo)
    ,.fifo_payload_len_i  (data_lo[cord_width_p+:len_width_p])
    ,.fifo_yumi_i         (yumi_li)
    ,.expecting_header_r_o(expecting_header_r_lo)
    );
   
   // decode destination vector
   always_comb 
     begin
	case (data_lo[cord_width_p-1:0])
	  cord_width_p'(0) :       dest_vec_decode = 2'b01;
	  { cord_width_p { 1'b1 }}:  dest_vec_decode = 2'b11;
	  default:                   dest_vec_decode = 2'b10;
	endcase // case (data_lo[cord_width_p-1:0])

	// if the data is not valid, zero it out
	if (!v_lo)
	  dest_vec_decode = 2'b00;
     end

   assign dest_vec_byp = expecting_header_r_lo ? dest_vec_decode : dest_vec_r;

   always_ff @(posedge clk_i)
     if (reset_i)
       dest_vec_r <= '0;
     else if (expecting_header_r_lo & yumi_li)
       dest_vec_r <= dest_vec_decode;
   
   always_comb
     begin
	data_lo_mod = data_lo;

	// modify header, decrement coordinate
	if (expecting_header_r_lo && dest_vec_decode == 2'b10)
	  data_lo_mod[0+:cord_width_p] = data_lo[0+:cord_width_p]-1'b1;
     end

   assign data_o = { data_lo_mod, data_lo };

   // whether there was a stall on the last cycle
   wire stall_r = | pending_r;

   assign pending_byp = stall_r ? pending_r : dest_vec_byp;
   assign pending_n = pending_byp & (~ready_and_i | ~ {v_lo,v_lo} );

   assign v_o = pending_byp & {v_lo, v_lo };
   
   always_ff @(posedge clk_i)
     if (reset_i)
       pending_r <= 2'b0;
     else
       // record unsucessful transfers or succesful transfer
       pending_r <= pending_n;

   // we yumi if there is nothing pending
   assign yumi_li = ~(|pending_n) & v_lo;
   
`ifndef BSG_HIDE_FROM_SYNTHESIS
   always @(negedge clk_i)
     $display("%t v_lo=%b v_o=%b ready_and_i=%b expecting_header_r_lo=%b yumi_li=%b pending_r=%b pending_n=%b dest_vec_r=%b dest_vec_byp=%b dest_vec_decode=%b"
	      ,$time,v_lo,v_o,ready_and_i,expecting_header_r_lo,yumi_li,pending_r,pending_n,dest_vec_r,dest_vec_byp,dest_vec_decode);
`endif
   
endmodule


