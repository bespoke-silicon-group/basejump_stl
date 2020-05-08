module top();
   localparam width_lp = 32;
   localparam els_lp = 4;
   localparam bit [width_lp-1:0] arr_lp [els_lp-1:0] = '{3, 2, 1, 0};

   // TODO: Read from somewhere
   parameter lc_cycle_time_p = 1000000;

   bsg_nonsynth_dpi_clock_gen
     #(.cycle_time_p(lc_cycle_time_p)
       )
   core_clk_gen
     (.o(core_clk));

   bsg_nonsynth_dpi_rom
     #(.els_p(els_lp)
       ,.width_p(width_lp)
       ,.arr_p(arr_lp))
   rom
     ();

   
endmodule

