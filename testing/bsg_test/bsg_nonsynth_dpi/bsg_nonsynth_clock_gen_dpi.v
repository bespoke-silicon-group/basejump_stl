module bsg_nonsynth_clock_gen_dpi
/*verilator lint_off WIDTH*/
  #(parameter longint cycle_time_p=64'd0
/*verilator lint_on WIDTH*/
    ,parameter name_p = "bsg_nonsynth_clock_gen_dpi"
    )
   (
    output bit o
    );

   int         id;
   string      hierarchy;
   
   import "DPI-C" function int bsg_nonsynth_clock_gen_register(input longint cycle_time_p, input string hierarchy);
   localparam longint cycle_time_lp = {32'b0, cycle_time_p[31:0]};
   
   

   initial begin
      $display("BSG INFO: bsg_nonsynth_clock_gen_dpi (initial begin)");
      $display("BSG INFO:     name_p  = %s", name_p);
      $display("BSG INFO:     cycle_time_p  = %d", cycle_time_p);
      hierarchy = $sformatf("%m");
      id = bsg_nonsynth_clock_gen_register(cycle_time_lp, hierarchy);
   end

   export "DPI-C" function set_clk_level;
   function bit set_clk_level(bit clkval);
      o = clkval;
      
      return o;
   endfunction;
endmodule
