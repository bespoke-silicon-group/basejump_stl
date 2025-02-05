//**********************************************************************
// Reset
//  ______  _______  ______ _______ _______
// (_____ \(_______)/ _____|_______|_______)
//  _____) )_____  ( (____  _____      _
// |  __  /|  ___)  \____ \|  ___)    | |
// | |  \ \| |_____ _____) ) |_____   | |
// |_|   |_|_______|______/|_______)  |_|
//
//**********************************************************************


`include "bsg_defines.sv"

module bsg_nonsynth_reset_gen #(parameter num_clocks_p=1
                                , parameter `BSG_INV_PARAM(reset_cycles_lo_p)
                                , parameter `BSG_INV_PARAM(reset_cycles_hi_p))
   (input bit [num_clocks_p-1:0] clk_i
    , output bit                 async_reset_o);

   genvar i;

   // This module relies on the input clock wires starting at 0 at
   // time 0 and not transitioning from X to 0 at time 0, and causing
   // a spurious negedge. To accomplish this in > VCS 2020, the input
   // must be declared as a bit. Moreover, the expectation is that
   // this module's input comes from a clock generation module that
   // uses bit, such as bsg_nonsynth_clk_gen, AND that the wire
   // between them is a bit.

   // use bit instead of logic to default to 0 initialization value
   // this makes it non-synthesizeable, but also allows X prop mode to work

   bit [num_clocks_p-1:0][$clog2(reset_cycles_lo_p+1)-1:0] ctr_lo_r;
   bit [num_clocks_p-1:0][$clog2(reset_cycles_hi_p+1)-1:0] ctr_hi_r;

   bit [num_clocks_p-1:0] phase_lo_r;
   bit [num_clocks_p-1:0] phase_hi_r;

   wire                                    in_phase_1 = & phase_lo_r;
   wire                                    in_phase_2 = & phase_hi_r;

   for (i = 0; i < num_clocks_p; i=i+1)
     begin : rof
       assign phase_lo_r[i] = (ctr_lo_r[i] == reset_cycles_lo_p[$bits(ctr_lo_r)-1:0]);
       assign phase_hi_r[i] = (ctr_hi_r[i] == reset_cycles_hi_p[$bits(ctr_hi_r)-1:0]);

        always @(negedge clk_i[i])
          if (~phase_lo_r[i])
            ctr_lo_r[i] <= ctr_lo_r[i] + 1'b1;
          else if (~phase_hi_r[i])
            ctr_hi_r[i] <= ctr_hi_r[i] + in_phase_1;
     end

   assign async_reset_o = (in_phase_1 ^ in_phase_2);

   always @(negedge async_reset_o)
     begin
        $display("__________ ___________  _______________________________");
        $display("\\______   \\\\_   _____/ /   _____/\\_   _____/\\__    ___/");
        $display(" |       _/ |    __)_  \\_____  \\  |    __)_   |    |   ");
        $display(" |    |   \\ |        \\ /        \\ |        \\  |    |  1->0 time = ",$stime);
        $display(" |____|_  //_______  //_______  //_______  /  |____|   ");
        $display(" ASYNC  \\/         \\/         \\/         \\/            ");
     end

   always @(posedge async_reset_o)
     begin
        $display("__________ ___________  _______________________________");
        $display("\\______   \\\\_   _____/ /   _____/\\_   _____/\\__    ___/");
        $display(" |       _/ |    __)_  \\_____  \\  |    __)_   |    |   ");
        $display(" |    |   \\ |        \\ /        \\ |        \\  |    |  0->1 time = ",$stime);
        $display(" |____|_  //_______  //_______  //_______  /  |____|   ");
        $display(" ASYNC  \\/         \\/         \\/         \\/            ");
     end

endmodule

`BSG_ABSTRACT_MODULE(bsg_nonsynth_reset_gen)

