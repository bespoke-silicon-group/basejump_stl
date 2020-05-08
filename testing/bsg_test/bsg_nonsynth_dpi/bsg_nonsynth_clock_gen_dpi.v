module bsg_nonsynth_clock_gen_dpi
  #(parameter real cycle_time_p="inv"
    ,parameter name_p = "bsg_nonsynth_clock_gen_dpi"
    )
   (
    output bit o
    );

   int         id;
   
   initial begin
      $display("BSG INFO: bsg_nonsynth_clock_gen_dpi (initial begin)");
      $display("BSG INFO:     name_p  = %s", name_p);
      $display("BSG INFO:     cycle_time_p  = %f", cycle_time_p);
      id = bsg_nonsynth_clock_gen_init(cycle_time_p);
   end

   function bit ext_tick(bit clkval);
      o = clkval;
   endfunction;


   import "DPI-C" function int bsg_nonsynth_clock_gen_init(input real cycle_time_p);
   import "DPI-C" function bit bsg_nonsynth_clock_gen_tick(input int id);
   function bit tick();
      o = bsg_nonsynth_clock_gen_tick(id);
      return o;
      
   endfunction;

endmodule
