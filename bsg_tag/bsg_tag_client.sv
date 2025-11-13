//
// bsg_tag_client
//
// simple serial on-chip configuration network
//
//
// 8/30/2016
//

// RESET SEMANTICS
//
// * NORMAL USAGE
//
// 0. wire bsg_tag_i.en high
// 1. assert reset on the send side of the module for at least one cycle (via bsg_tag_i)
// 2. clock the send side for one cycle.
// 3. clock the recv side for several cycles (for values to flush through synchronizers)
// 5. after resets are dropped, optionally start updating values on bsg_tag_s bus.
//
//
// * CLOCK GENERATOR NORMAL
//
// 0. follow steps 0-2 in NORMAL USAGE
// 1. pull bsg_tag_i.en low to disconnect bsg_tag
// 2. assert async_reset on clock gen
// 3. deassert async_reset on clock gen (clock starts)
// 4. after a few cycles
// 5. pull bsg_tag_i.en high to attach bsg_tag
//
// * CLOCK GENERATOR FAILSAFE
//
// 0. wire bsg_tag_i.en low
// 1. assert async_reset on clock gen
// 2. deassert async_reset
// 3. go
//


`include "bsg_defines.sv"

module bsg_tag_client
   import bsg_tag_pkg::bsg_tag_s;
 #(parameter `BSG_INV_PARAM(width_p), harden_p=1)
   (
    input bsg_tag_s bsg_tag_i

    , input                recv_clk_i

    , output               recv_new_r_o   // optional; notifies of new value
    , output [width_p-1:0] recv_data_r_o
    );

   localparam debug_level_lp = 1;

   logic   op_r, op_r_r, param_r;

   always_ff @(posedge bsg_tag_i.clk)
     begin
        op_r    <= bsg_tag_i.op;
        param_r <= bsg_tag_i.param;
        op_r_r  <= op_r;
     end

   wire reset_op = ~op_r & param_r;
   wire shift_op = op_r;
   wire no_op    = ~op_r & ~param_r;

   // when this is high, tag_data_r is already transmitting data
   // this control has another cycle of latency in this clock domain
   // before passing into the next, which is important.
   wire send_now = op_r_r & no_op;

   logic [width_p-1:0] tag_data_r, recv_data_r, tag_data_n, tag_data_shift;
   logic               tag_toggle_r;

   // shift in new state
   if (width_p == 1)
     begin : sb
       assign tag_data_shift = { param_r };
     end
   else
     begin : mb
       assign tag_data_shift = { param_r, tag_data_r[width_p-1:1] };
     end

   bsg_mux2_gatestack #(.width_p(width_p),.harden_p(harden_p)) tag_data_mux
     (.i0 (tag_data_r            ) // sel=0
      ,.i1(tag_data_shift        ) // sel=1
      ,.i2({ width_p {shift_op} }) // sel var
      ,.o (tag_data_n)
      );
   
   bsg_dff #(.width_p(width_p), .harden_p(harden_p)) tag_data_reg
	     (.clk_i(bsg_tag_i.clk)
	      ,.data_i(tag_data_n)
	      ,.data_o(tag_data_r)
	      );
   
`ifndef BSG_HIDE_FROM_SYNTHESIS
   if (debug_level_lp > 1)
   always @(negedge bsg_tag_i.clk)
     begin
        if (reset_op & ~(~bsg_tag_i.op & bsg_tag_i.param))
          $display("## bsg_tag_client (send) RESET DEASSERTED (%m)");
        if (~reset_op & (~bsg_tag_i.op & bsg_tag_i.param))
          $display("## bsg_tag_client (send) RESET ASSERTED   (%m)");
        if (send_now)
          $display("## bsg_tag_client (send) SENDING   %b (%m)",tag_data_r);
     end
`endif

   logic recv_toggle_r, recv_toggle_n;

   // cross clock boundary
   bsg_launch_sync_sync  #(.width_p(1)) blss
   (.iclk_i       (bsg_tag_i.clk)
    ,.iclk_reset_i(reset_op)
    ,.iclk_data_i (tag_toggle_r ^ send_now)
    ,.iclk_data_o (tag_toggle_r) // this is the flop that is reset

    ,.oclk_i     (recv_clk_i   )
    ,.oclk_data_o(recv_toggle_n)
    );

   // note: bsg_tag_i.en is wired from off-chip and should be
   // only toggled when there is no attempt to transmit data

   wire  recv_new = (recv_toggle_r ^ recv_toggle_n);

   // we had to add recv_new_r_r to pipeline the receive logic
   // and the fanout to the recv_data_r register at the maximum
   // frequency on the chip (i.e. the clock generator)

   logic recv_new_r, recv_new_r_r;

   always_ff @(posedge recv_clk_i)
     begin
        recv_toggle_r <= recv_toggle_n;
        recv_new_r    <= recv_new;
        recv_new_r_r  <= recv_new_r;
     end

   bsg_dff_en #(.width_p(width_p),.harden_p(harden_p)) recv
        (.clk_i(recv_clk_i)
         ,.en_i(recv_new_r)
         ,.data_i(tag_data_r)
         ,.data_o(recv_data_r)
         );

   // the recv_en_i signal has to come after the flop
   // so this works even when the clock is not working

   assign recv_new_r_o    = recv_new_r_r;
   assign recv_data_r_o   = recv_data_r;

endmodule

`BSG_ABSTRACT_MODULE(bsg_tag_client)
