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
// 4. assert reset on the recv side of the module (to set default on receive side value)
// 5. after resets are dropped, optionally start updating values on bsg_tag_s bus.
//
// * FAILSAFE
//
// 0. wire bsg_tag_i.en low to disconnect bsg_tag
// 1. assert recv_reset_i on the recv side of the module to install defaults
// 2. proceed without use of bsg_tag
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
//
// note: operation of bsg_tag_i.en is only valid if there
// are no attempts to transmit data on bsg_tag at the same time
// otherwise it is a CDC violation.

module bsg_tag_client
   import bsg_tag_pkg::bsg_tag_s;
 #(width_p="inv", default_p="inv")
   (
    input bsg_tag_s bsg_tag_i

    , input                recv_clk_i

    , input                recv_reset_i   // default: wired to 0
                                          // use to reset output data to a known state
                                          // can we be used either to avoid having
                                          // to send data on the bsg_tag_chain
                                          // or in conjunction with recv_en_i
                                          // to allow the data to be set without
                                          // an operational bsg_tag

    , output               recv_new_r_o   // optional; notifies of new value
    , output [width_p-1:0] recv_data_r_o
    );

   localparam debug_level_lp = 0;
   
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

   wire send_now = op_r_r & no_op;

   logic [width_p-1:0] tag_data_r, recv_data_r;
   logic               tag_toggle_r;

   // shift in new state
   always @(posedge bsg_tag_i.clk)
     begin
        if (shift_op)
          tag_data_r   <= { param_r, tag_data_r[width_p-1:1] };
     end

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

   wire  recv_new = (recv_toggle_r ^ recv_toggle_n) & bsg_tag_i.en;

   logic recv_new_r;

   always_ff @(posedge recv_clk_i)
     begin
        recv_toggle_r <= recv_toggle_n;

        if (recv_reset_i)
          begin
             recv_data_r   <= width_p ' (default_p);
             if (debug_level_lp > 1) $display("## bsg_tag_client (recv) RESET (%m)");
          end
        else
          // CDC (fixme use RPG groups)
          if (recv_new)
            begin
               recv_data_r <= tag_data_r;
               if (debug_level_lp > 1) $display("## bsg_tag_client (recv) RECEIVING %b (%m)",tag_data_r);
            end

        // goes high for one cycle after reset (en is high)

        recv_new_r    <= recv_new | recv_reset_i;
     end

   // the recv_en_i signal has to come after the flop
   // so this works even when the clock is not working

   assign recv_new_r_o  = recv_new_r & bsg_tag_i.en;
   assign recv_data_r_o = recv_data_r;

endmodule
