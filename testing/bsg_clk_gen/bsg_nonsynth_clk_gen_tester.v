`include "bsg_tag.vh"
`include "bsg_clk_gen.vh"

`timescale 1ps/1ps

/*

  In IC compiler (or possibly Primetime), here is a different way to time these paths instead
  of running with SDF annotation.

  1. look at arrows in timing report, and read the value off the last arrow.
     does not include the delay of an AND2.

  a. longest path through oscillator (one half clock cycle) not including delay through ADG and gate A1/A2

  report_timing  -from clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A1/Y -to clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A1/A

  b. shortest paths through oscillator

 report_timing    -from clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A2/Y   -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_1__adg/A2/Y   -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/D    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/D   -to clk_gen_core_inst/clk_gen_osc_inst/fdt/A1/Y

  c. more generally :

  report_timing

    -from clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A1/Y

    // course delay element (pick 1)
    -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A1/Y   (slow ADG0)
    -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_0__adg/A2/Y   (fast ADG0)

    // course delay element (pick 1)
     -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_1__adg/A1/Y   (slow ADG1)
    -through clk_gen_core_inst/clk_gen_osc_inst/adg_gen_1__adg/A2/Y   (fast ADG1)

    // course delay tuner (pick 1)
    -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/A  (slowest)
    -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/B
    -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/C
    -through clk_gen_core_inst/clk_gen_osc_inst/cdt/cde/M1/D  (fastest)

    // fine delay tuner (pick 1)
    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/A (slowest)
    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/B
    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/C
    -through clk_gen_core_inst/clk_gen_osc_inst/fdt/M2/D (fastest)

    -to clk_gen_core_inst/clk_gen_osc_inst/fdt/A1/Y
 */

module bsg_nonsynth_clk_gen_tester
  #(parameter num_adgs_p="inv"
    , ds_width_p="inv"
    , tag_els_p="inv"
    )
   (input ext_clk_i
    , output logic bsg_tag_clk_o
    , output logic bsg_tag_en_o
    , output logic bsg_tag_data_o

    , output logic  [1:0] bsg_clk_gen_sel_o
    , output logic bsg_clk_gen_async_reset_o      // async reset (to clock geneartor)

    , input bsg_clk_gen_i
    );

   `declare_bsg_clk_gen_osc_tag_payload_s(num_adgs_p)
   `declare_bsg_clk_gen_ds_tag_payload_s(ds_width_p)

   localparam max_payload_length_lp    = `BSG_MAX($bits(bsg_clk_gen_osc_tag_payload_s),$bits(bsg_clk_gen_ds_tag_payload_s));
   localparam lg_max_payload_length_lp = $clog2(max_payload_length_lp+1);

   `declare_bsg_tag_header_s(tag_els_p,lg_max_payload_length_lp)

   bsg_nonsynth_clock_gen #(10000) cfg_clk_gen (bsg_tag_clk_o);

     // Used to count ticks between clock edges
  //
  longint     ticks     = 0;
  longint     t1        = 0;
  longint     per_old   = 0;
  longint     per_new   = 0;
  longint     min_per   = 0;

  // Count the number of timescale ticks that occur throughout simulation
  //
//  always #10ps ticks = ticks + 1'b1;


   bsg_tag_header_s ds_tag_header;
   bsg_tag_header_s osc_tag_header;
   bsg_clk_gen_osc_tag_payload_s osc_tag_payload;
   bsg_clk_gen_ds_tag_payload_s ds_tag_payload;

   localparam osc_pkt_size_lp = $bits(bsg_tag_header_s)+$bits(bsg_clk_gen_osc_tag_payload_s)+1+1;
   wire [osc_pkt_size_lp-1:0] osc_pkt = { 1'b0, osc_tag_payload, osc_tag_header,1'b1 };

   localparam ds_pkt_size_lp  = $bits(bsg_tag_header_s)+$bits(bsg_clk_gen_ds_tag_payload_s)+1+1;
   wire [ds_pkt_size_lp-1:0]  ds_pkt  = { 1'b0, ds_tag_payload, ds_tag_header,1'b1 };

   localparam check_times_lp = 0;

   longint                    my_ticks_posedge = 0;
   longint                    my_ticks_negedge = 0;
   longint                    last_posedge = -1;
   longint                    last_negedge = -1;
   longint                    cycles_posedge = -1;
   longint                    cycles_negedge = -1;

   always @(posedge bsg_clk_gen_i)
     begin
        if ($time-my_ticks_negedge != last_posedge)
          begin
             if (cycles_posedge != -1)
               $write("## clock_watcher {                                                                                POSEDGE offset (after %-8d cycles) %-7d ps (n/p phase ratio=%2.3f)}\n"
                      ,cycles_posedge, $time-my_ticks_negedge, ( real ' (last_negedge))/(real ' ($time-my_ticks_negedge)));
             cycles_posedge = 0;
             last_posedge = $time-my_ticks_negedge;
          end
        else
          cycles_posedge = cycles_posedge+1;

        my_ticks_posedge = $time;

     end // always @ (posedge bsg_clk_gen_i)

   always @(negedge bsg_clk_gen_i)
     begin
        if ($time-my_ticks_posedge != last_negedge)
          begin
             if (cycles_negedge != -1)
               $write("## clock_watcher { NEGEDGE offset (after %-7d cycles) %-7d ps (p/n phase ratio=%2.3f)}\n"
                      ,cycles_negedge, $time-my_ticks_posedge, ( real ' (last_posedge))/(real ' ($time-my_ticks_posedge)));
             cycles_negedge = 0;
             last_negedge = $time-my_ticks_posedge;
          end
        else
          cycles_negedge = cycles_negedge+1;

        my_ticks_negedge = $time;
     end


   string output_string = "";
   string temp_string = "";

  // All testing happens here
  //
  initial
    begin

       $display("                                                           ");
       $display("***********************************************************");
       $display("*                                                         *");
       $display("*                  SIMULATION BEGIN                       *");
       $display("*                                                         *");
       $display("***********************************************************");
       $display("                                                           ");

       $display("## INFO 0: detaching bsg_tag chain receive sides");
       bsg_tag_en_o = 0;

       /*******************************************************************/
       /*                                                                 */
       /*                        BOOT SEQUENCE                            */
       /*                                                                 */
       /*******************************************************************/

       $display("## INFO 1: performing async reset on oscillator (bsg_clk_gen_sel_o=0)");

       // perform an async reset. should see life in the clock generator
       //
       #100ns;
       bsg_clk_gen_async_reset_o = 1'b1;
       #100ns;
       bsg_clk_gen_async_reset_o = 1'b0;

       $display("## INFO 2: testing for live oscillator (bsg_clk_gen_sel_o=0)");
       // will stall if the generator doesn't boot
      //
       bsg_clk_gen_sel_o = 2'b00;
       for (integer i = 0; i < 10; i++)
         @(posedge bsg_clk_gen_i);

       $display("## PASS 0: Counted 10 clock positive edges (bsg_clk_gen_sel_o=0)");

       $display("## INFO 3b: beginning bsg_tag master reset transmit ");

       // reset zero's counter
       @(negedge bsg_tag_clk_o);
       bsg_tag_data_o = 1'b1;

       // transmit lots of zeros
       @(negedge bsg_tag_clk_o);
       bsg_tag_data_o = 1'b0;

       for (integer i = 0; i < `bsg_tag_reset_len(bsg_tag_els_lp,lg_max_payload_length_lp); i=i+1)
         @(negedge bsg_tag_clk_o);

       $display("## INFO 3e: end bsg_tag master reset transmit");

       $display("## INFO 4b: begin bsg_tag_client reset transmit for oscillator");

       osc_tag_header.nodeID         = 0;
       osc_tag_header.data_not_reset = 0;
       osc_tag_header.len            = $size(osc_tag_payload);

       // stream of ones will reset bsg_tag_client node
       osc_tag_payload     = { $bits(osc_tag_payload) {1'b1} };

       for (integer i = 0; i < osc_pkt_size_lp; i=i+1)
         begin
            @(negedge bsg_tag_clk_o);
            bsg_tag_data_o = osc_pkt[i];
         end

       // let the data percolate through synchronizers etc
       // before attaching lutag

       for (integer i = 0; i < 3; i++)
         begin
            @(posedge bsg_clk_gen_i);
            @(posedge bsg_tag_clk_o);
         end

       $display("## INFO 4e: end bsg_tag_client reset transmit for oscillator ");


       $display("## INFO 5: attaching recv side of nodes to bsg_tag (bsg_tag_en_o=1)");
       // at this point, we can enable bsg_tag
       bsg_tag_en_o = 1;

       $display("## INFO 6: testing for live oscillator (bsg_clk_gen_sel_o=%b)",bsg_clk_gen_sel_o);
       // will stall if the generator isn't working anymore
      //
       bsg_clk_gen_sel_o = 2'b00;
       for (integer i = 0; i < 10; i++)
         @(posedge bsg_clk_gen_i);

       $display("## PASS 1: Counted 10 clock positive edges (bsg_clk_gen_sel_o=0)");

       $display("## INFO 7b: begin bsg_tag_client reset transmit for downsampler");

       ds_tag_header.nodeID  = 1;
       ds_tag_header.data_not_reset  = 0;
       ds_tag_header.len   = $bits(ds_tag_payload);
       ds_tag_payload      = { $bits(ds_tag_payload) {1'b1} };

       for (integer i = 0; i < ds_pkt_size_lp; i=i+1)
         begin
            @(negedge bsg_tag_clk_o);
            bsg_tag_data_o = ds_pkt[i];
         end

       $display("## INFO 7e: end bsg_tag_client reset transmit for downsampler ");
       $display("## INFO 8s: begin resetting downsampler and using val=0 ");

       ds_tag_header.data_not_reset = 1;
       ds_tag_payload.reset = 1;
       ds_tag_payload.val = 0;

       for (integer i = 0; i < ds_pkt_size_lp; i=i+1)
         begin
            @(negedge bsg_tag_clk_o);
            bsg_tag_data_o = ds_pkt[i];
         end

       // we keep the reset asserted for several cycles in each clock
       // domain to allow the data to percolate through the synchronizers
       for (integer i = 0; i < 3; i++)
         begin
            @(posedge bsg_clk_gen_i);
            @(posedge bsg_tag_clk_o);
         end

       ds_tag_payload.reset = 0;

       for (integer i = 0; i < ds_pkt_size_lp; i=i+1)
         begin
            @(negedge bsg_tag_clk_o);
            bsg_tag_data_o = ds_pkt[i];
         end

       // let the data percolate through synchronizers etc
       // before attaching lutag

       for (integer i = 0; i < 3; i++)
         begin
            @(posedge bsg_clk_gen_i);
            @(posedge bsg_tag_clk_o);
         end

       $display("## INFO 8e: end resetting downsampler and using val=0");

      $display("## INFO 9: Testing downsampler generates a clock (bsg_clk_gen_sel_o=01)");

      // will stall if the downsampler doesn't get reset properly
      //
      bsg_clk_gen_sel_o = 2'b01;
      for (integer i = 0; i < 10; i++)
          @(posedge bsg_clk_gen_i);

      $display("## PASS 9:  downsampler appears to generate a clock (bsg_clk_gen_sel_o=01)");

      $display("## INFO 10: Testing external clock pass-through (bsg_clk_gen_sel_o=10)");

      // quick check to make sure the external clock pass-though is working
      //
      bsg_clk_gen_sel_o = 2'b10;
      for (integer i = 0; i < 10; i++)
        begin
          @(posedge bsg_clk_gen_i);
          assert(bsg_clk_gen_i == ext_clk_i);
        end

      $display("## PASS 10: external clock appears to work (bsg_clk_gen_sel_o=01)");

      // end boot sequence, let's start testing!
      //
      $display("## PASS 11: Clock generator is alive... ramping from slowest to fastest");

      /*******************************************************************/
      /*                                                                 */
      /*                     INCREASE CLOCK SPEED                        */
      /*                                                                 */
      /*******************************************************************/

       bsg_clk_gen_sel_o = 2'b00;   // switch to raw clock generator
       per_old = 2**32;             // make large for first test to pass
       min_per = per_old;

       output_string = { output_string, "Setting:" };

       for (integer i = 0; i < 1 << $bits(bsg_clk_gen_osc_tag_payload_s); i++)
         output_string = { output_string, $sformatf("%6d",i) };

       output_string = { output_string, "\nPeriod : " };

      // go through each clock speed setting
      for (integer i = 0; i < 1 << $bits(bsg_clk_gen_osc_tag_payload_s); i++)
        begin
           osc_tag_header.data_not_reset = 1;
           osc_tag_payload = i;

           for (integer j = 0; j < osc_pkt_size_lp; j=j+1)
             begin
                @(negedge bsg_tag_clk_o);
                bsg_tag_data_o = osc_pkt[j];
             end

          // wait a few clock cycles to make sure the packet propagates
          // and the syncronizer registers have been passed
          //
          for (integer j = 0; j < 4; j++)
              @(posedge bsg_tag_clk_o);
          for (integer j = 0; j < 4; j++)
              @(posedge bsg_clk_gen_i);

          // Measure the clock period
          //
          @(posedge bsg_clk_gen_i);
           t1 = $time;
 //ticks;
          @(posedge bsg_clk_gen_i);
           per_new = $time -t1;
// ticks - t1;

          // Make sure the period is now less than it was.
          //
          // We actually should expect that the new clock period is strictly
          // less than the old one, but the FDT stage of the clock generator
          // uses loading capacitance to affect the speed which is not modeled
          // in RTL therefore changes in the FDT will show up as identical
          // periods.
          //

           if (check_times_lp)
             begin
                assert(per_new <= per_old)
                  $write("%6d",per_new);
                // $display("Passed: old per=%-d -- new per=%-d", per_old, per_new);
                else
                  $display("\n***FAILED: old per=%-d -- new per=%-d", per_old, per_new);
             end
           else
             output_string = { output_string, $sformatf   ("%2.3f ", real ' (per_new) / 1000.0) };

          // Shift for next iteration
          //
          per_old = per_new;
          if (per_new < min_per)
            min_per = per_new;
        end // for (integer i = 0; i < 1 << $bits(bsg_clk_gen_osc_tag_payload_s); i++)

       $display(output_string);

       $display("## PASS 12b: BEGIN JAM clock from fastest to slowest");

       // now jam from fastest to slowest

       osc_tag_payload = 0;

       for (integer j = 0; j < osc_pkt_size_lp; j=j+1)
         begin
            @(negedge bsg_tag_clk_o);
            bsg_tag_data_o = osc_pkt[j];
         end

       for (integer j = 0; j < 4; j++)
         @(posedge bsg_tag_clk_o);
       for (integer j = 0; j < 4; j++)
         @(posedge bsg_clk_gen_i);

       $display("## PASS 12e: END JAM clock from fastest to slowest");

       $display("## PASS 13b: BEGIN JAM clock from slowest to fastest");
       // now jam from slowest to fastest

       osc_tag_payload = 6'b111111;

       for (integer j = 0; j < osc_pkt_size_lp; j=j+1)
         begin
            @(negedge bsg_tag_clk_o);
            bsg_tag_data_o = osc_pkt[j];
         end

       for (integer j = 0; j < 10; j++)
         @(posedge bsg_tag_clk_o);
       for (integer j = 0; j < 10; j++)
         @(posedge bsg_clk_gen_i);

       $display("## PASS 13e: END JAM clock from slowest to fastest");

      /*******************************************************************/
      /*                                                                 */
      /*                     INCREASE DOWNSAMPLE                         */
      /*                                                                 */
      /*******************************************************************/

       $display("## PASS 14: Switching to Downsampled clock (bsg_clk_gen_sel_o=%b)",bsg_clk_gen_sel_o);

      bsg_clk_gen_sel_o = 2'b01;      // look at the downsampled clock



      // go through each downsample amount
      for (integer i = 0; i < (1 << ds_width_p) ; i++)
        begin
           if (i[5:0] == 0)
             output_string = { output_string, "\nDwnsmpl: "};

           ds_tag_header.data_not_reset = 1;
           ds_tag_payload.val = i;

           for (integer j = 0; j < ds_pkt_size_lp; j=j+1)
             begin
                @(negedge bsg_tag_clk_o);
                bsg_tag_data_o = ds_pkt[j];
             end

          // wait a few clock cycles to make sure the packet propagates
          // through synchronizers

          for (integer j = 0; j < 4; j++)
              @(posedge bsg_tag_clk_o);
          for (integer j = 0; j < 3; j++)
              @(posedge bsg_clk_gen_i);

          // Measure the clock period
          //
          @(posedge bsg_clk_gen_i);
           t1 = $time;
 // ticks;
          @(posedge bsg_clk_gen_i);
           per_new = $time - t1 ;
//ticks - t1;

          // Make sure the period is now the correct downsampled factor of the
          // original clock period
          //

           if (check_times_lp)
             begin
                assert(per_new == min_per*(i+1)*2)
                  $write("%6d",per_new);
                //$display("Passed: per=%-d -- expected per=%-d*%-d=%-d", per_new, per_old, (i+1)*2, per_old*(i+1)*2);
                else
                  $display("***FAILED: per=%-d -- expected per=%-d*%-d=%-d", per_new, min_per, (i+1)*2, min_per*(i+1)*2);
             end
           else
             begin
                if (per_new >= 999.9*1000.0)
                  output_string = { output_string, $sformatf   ("%5.0f ", real ' (per_new) / 1000.0) };
                else
                  output_string = { output_string, $sformatf   ("%5.1f ", real ' (per_new) / 1000.0) };
             end
        end // for (integer i = 0; i < (1 << ds_width_p) ; i++)

       $display(output_string);

       $display("                                                           ");
       $display("***********************************************************");
       $display("*                                                         *");
       $display("*                 SIMULATION FINISHED                     *");
       $display("*                                                         *");
       $display("***********************************************************");
       $display("                                                           ");
       $finish;


    end // initial begin


endmodule
