module top();
   localparam width_lp = 32;
   localparam debug_lp = 0;

   // These declarations export the functions from the leaf
   // modules. There may be a cleaner way to do this but I haven't
   // found it yet.

   logic     ns_clk, ns_reset, debug_o;
   parameter lc_cycle_time_p = 1000000;

   bsg_nonsynth_dpi_clock_gen
     #(.cycle_time_p(lc_cycle_time_p)
       )
   core_clk_gen
     (.o(ns_clk));

   bsg_nonsynth_dpi_clock_gen
     #(.cycle_time_p(lc_cycle_time_p/2)
       )
   core_clk_gen2
     (.o(ns_clk));

   bsg_nonsynth_reset_gen 
     #(
       .num_clocks_p(1)
       ,.reset_cycles_lo_p(1)
       ,.reset_cycles_hi_p(2)
       ) 
   reset_gen 
     (
      .clk_i(ns_clk)
      ,.async_reset_o(ns_reset)
      );
   
   int           cycle = 0;

   always @(posedge ns_clk) begin
     cycle <= cycle +1;
     if(debug_o)
       $display("BSG DBGINFO: top -- Cycle %d", cycle);
   end
   
   logic [width_lp-1:0] data_i;

   logic [width_lp-1:0] data_o;
   logic                v_o, v_i, ready_o, yumi_i;

   
   bsg_nonsynth_dpi_from_fifo
     #(
       .width_p                        (width_lp)
       ,.debug_p                        (debug_lp))
   f2d_i
     (
      .yumi_o                           (yumi_i)
      ,.debug_o                         (debug_o)

      ,.clk_i                           (ns_clk)
      ,.reset_i                         (ns_reset)
      ,.v_i                             (v_o)
      ,.data_i                          (data_o));

   bsg_nonsynth_dpi_to_fifo
     #(
       .width_p                        (width_lp)
       ,.debug_p                        (debug_lp))
   d2f_i
     (
      .debug_o() 
      ,.v_o(v_i)
      ,.data_o(data_i)

      ,.ready_i(ready_o)
      ,.clk_i(ns_clk)
      ,.reset_i(ns_reset));

   bsg_fifo_1r1w_small_unhardened
     #(.els_p(4)
       ,.width_p(width_lp)
       )
   fifo_i
     (
      .clk_i(ns_clk)
      ,.reset_i(ns_reset)

      ,.v_i(v_i)
      ,.ready_o(ready_o)
      ,.data_i(data_i)

      ,.v_o(v_o)
      ,.data_o(data_o)
      ,.yumi_i(yumi_i));
   
endmodule

