`define WIDTH_P ?   // unused for now...

`include "bsg_tag.vh"

module test_bsg;

   import bsg_tag_pkg::bsg_tag_s;

   localparam bsg_num_adgs_lp  = 2;
   localparam bsg_ds_width_lp  = 8;
   localparam bsg_tag_els_lp  = 2;

   `declare_bsg_clk_gen_osc_tag_payload_s(bsg_num_adgs_lp)
   `declare_bsg_clk_gen_ds_tag_payload_s(bsg_ds_width_lp)

   localparam max_payload_length_lp    = `BSG_MAX($bits(bsg_clk_gen_osc_tag_payload_s),$bits(bsg_clk_gen_ds_tag_payload_s));
   localparam lg_max_payload_length_lp = $clog2(max_payload_length_lp+1);

   `declare_bsg_tag_header_s(bsg_tag_els_lp,lg_max_payload_length_lp)

  // Enable VPD dump file
  //
  initial
    begin
      $vcdpluson;
      $vcdplusmemon;
    end

  // Used to count ticks between clock edges
  //
  longint     ticks     = 0;
  longint     t1        = 0;
  longint     per_old   = 0;
  longint     per_new   = 0;
  longint    min_per   = 0;

  // Count the number of timescale ticks that occur throughout simulation
  //
  always #1 ticks = ticks + 1'b1;

  // Clock generator signals
  //

  logic       async_osc_reset;
  logic       sync_rst;
  logic       ext_clk;
  logic [1:0] clk_sel;
  logic       clk_o;

   wire       bsg_tag_clk;
   logic      bsg_tag_gate;
   logic      bsg_tag_data;

   bsg_nonsynth_clock_gen #(1000) cfg_clk_gen (bsg_tag_clk);

   // Exteral clock which gets passed through the clock generator
   //
   bsg_nonsynth_clock_gen #(250) ext_clk_gen (ext_clk);

   bsg_tag_s [1:0] tags;

   logic      TMS;

   bsg_tag_master #(.els_p(bsg_tag_els_lp)
                    ,.lg_width_p(lg_max_payload_length_lp)
                    ) btm
     (.clk_i       (bsg_tag_clk & ~bsg_tag_gate)
      ,.data_i     (bsg_tag_data)
      ,.en_i       (TMS)
      ,.clients_r_o(tags)
      );

  bsg_clk_gen #(.downsample_width_p(bsg_ds_width_lp), .num_adgs_p(bsg_num_adgs_lp)) DUT
    (.bsg_osc_tag_i(tags[0])
     ,.bsg_ds_tag_i(tags[1])
     ,.async_osc_reset_i(async_osc_reset)

    ,.ext_clk_i(ext_clk)
    ,.select_i(clk_sel)
    ,.clk_o(clk_o)
    );

   bsg_tag_header_s ds_tag_header;
   bsg_tag_header_s osc_tag_header;
   bsg_clk_gen_osc_tag_payload_s osc_tag_payload;
   bsg_clk_gen_ds_tag_payload_s ds_tag_payload;

   localparam osc_pkt_size_lp = $bits(bsg_tag_header_s)+$bits(bsg_clk_gen_osc_tag_payload_s)+1+1;
   wire [osc_pkt_size_lp-1:0] osc_pkt = { 1'b0, osc_tag_payload, osc_tag_header,1'b1 };

   localparam ds_pkt_size_lp  = $bits(bsg_tag_header_s)+$bits(bsg_clk_gen_ds_tag_payload_s)+1+1;
   wire [ds_pkt_size_lp-1:0]  ds_pkt  = { 1'b0, ds_tag_payload, ds_tag_header,1'b1 };

  // All testing happens here
  //
  initial
    begin
       bsg_tag_gate = 0;

       $display("                                                           ");
       $display("***********************************************************");
       $display("*                                                         *");
       $display("*                  SIMULATION BEGIN                       *");
       $display("*                                                         *");
       $display("***********************************************************");
       $display("                                                           ");

       $display("## INFO 0: detaching bsg_tag chain receive sides");
       TMS = 0;

       /*******************************************************************/
       /*                                                                 */
       /*                        BOOT SEQUENCE                            */
       /*                                                                 */
       /*******************************************************************/

       $display("## INFO 1: performing async reset on oscillator (clk_sel=0)");

       // perform an async reset. should see life in the clock generator
       //
       #1000;
       async_osc_reset = 1'b1;
       #10000;
       async_osc_reset = 1'b0;

       $display("## INFO 2: testing for live oscillator (clk_sel=0)");
       // will stall if the generator doesn't boot
      //
       clk_sel = 2'b00;
       for (integer i = 0; i < 10; i++)
         @(posedge clk_o);

       $display("## PASS 0: Counted 10 clock positive edges (clk_sel=0)");

       $display("## INFO 3b: beginning bsg_tag master reset transmit ");

       // reset zero's counter
       @(negedge bsg_tag_clk);
       bsg_tag_data = 1'b1;

       // transmit lots of zeros
       @(negedge bsg_tag_clk);
       bsg_tag_data = 1'b0;

       for (integer i = 0; i < `bsg_tag_reset_len(bsg_tag_els_lp,lg_max_payload_length_lp); i=i+1)
         @(negedge bsg_tag_clk);

       $display("## INFO 3e: end bsg_tag master reset transmit");

       $display("## INFO 4b: begin bsg_tag_client reset transmit for oscillator");

       osc_tag_header.nodeID         = 0;
       osc_tag_header.data_not_reset = 0;
       osc_tag_header.len            = $size(osc_tag_payload);

       // stream of ones will reset bsg_tag_client node
       osc_tag_payload     = { $bits(osc_tag_payload) {1'b1} };

       for (integer i = 0; i < osc_pkt_size_lp; i=i+1)
         begin
            @(negedge bsg_tag_clk);
            bsg_tag_data = osc_pkt[i];
         end

       $display("## INFO 4e: end bsg_tag_client reset transmit for oscillator ");

       // put things back in stable state
       @(negedge bsg_tag_clk);
       bsg_tag_data = 1'b0;

       $display("## INFO 5: attaching recv side of nodes to bsg_tag (TMS=1)");
       // at this point, we can enable bsg_tag
       TMS = 1;

       $display("## INFO 6: testing for live oscillator (clk_sel=%b)",clk_sel);
       // will stall if the generator isn't working anymore
      //
       clk_sel = 2'b00;
       for (integer i = 0; i < 10; i++)
         @(posedge clk_o);

       $display("## PASS 1: Counted 10 clock positive edges (clk_sel=0)");

       $display("## INFO 7b: begin bsg_tag_client reset transmit for downsampler");

       ds_tag_header.nodeID  = 1;
       ds_tag_header.data_not_reset  = 0;
       ds_tag_header.len   = $bits(ds_tag_payload);
       ds_tag_payload      = { $bits(ds_tag_payload) {1'b1} };

       for (integer i = 0; i < $bits(ds_pkt_size_lp); i=i+1)
         begin
            @(negedge bsg_tag_clk);
            bsg_tag_data = ds_pkt[i];
         end

       $display("## INFO 7e: end bsg_tag_client reset transmit for downsampler ");
       $display("## INFO 8s: begin resetting downsampler and using val=0 ");

       ds_tag_header.data_not_reset = 1;
       ds_tag_payload.reset = 1;
       ds_tag_payload.val = 0;

       for (integer i = 0; i < $bits(ds_pkt_size_lp); i=i+1)
         begin
            @(negedge bsg_tag_clk);
            bsg_tag_data = ds_pkt[i];
         end

       ds_tag_payload.reset = 0;

       for (integer i = 0; i < $bits(ds_pkt_size_lp); i=i+1)
         begin
            @(negedge bsg_tag_clk);
            bsg_tag_data = ds_pkt[i];
         end

       $display("## INFO 8e: begin resetting downsampler and using val=0 ");

      $display("## INFO 9: Testing downsampler generates a clock (clk_sel=01)");

      // will stall if the downsampler doesn't get reset properly
      //
      clk_sel = 2'b01;
      for (integer i = 0; i < 10; i++)
          @(posedge clk_o);

      $display("## PASS 9:  downsampler appears to generate a clock (clk_sel=01)");

      $display("## INFO 10: Testing external clock pass-through (clk_sel=10)");

      // quick check to make sure the external clock pass-though is working
      //
      clk_sel = 2'b10;
      for (integer i = 0; i < 10; i++)
        begin
          @(clk_o);
          assert(clk_o == ext_clk);
        end

      $display("## PASS 10: external clock appears to work (clk_sel=01)");

      // end boot sequence, let's start testing!
      //
      $display("## PASS 11: Clock generator is alive... begin testing!");

      /*******************************************************************/
      /*                                                                 */
      /*                     INCREASE CLOCK SPEED                        */
      /*                                                                 */
      /*******************************************************************/

      clk_sel = 2'b00;      // switch to raw clock generator
      per_old = 2**32;      // make large for first test to pass
       min_per = per_old;

       $write("Setting:");
       for (integer i = 0; i < 1<< $bits(bsg_clk_gen_osc_tag_payload_s); i++)
         $write   ("%6d", i);
       $write("\nPeriod :");

      // go through each clock speed setting
      for (integer i = 0; i < 1 << $bits(bsg_clk_gen_osc_tag_payload_s); i++)
        begin
           osc_tag_header.data_not_reset = 1;
           osc_tag_payload = i;

           for (integer j = 0; j < osc_pkt_size_lp; j=j+1)
             begin
                @(negedge bsg_tag_clk);
                bsg_tag_data = osc_pkt[j];
             end

          // wait a few clock cycles to make sure the packet propagates
          // and the syncronizer registers have been passed
          //
          for (integer j = 0; j < 4; j++)
              @(posedge bsg_tag_clk);
          for (integer j = 0; j < 4; j++)
              @(posedge clk_o);

          // Measure the clock period
          //
          @(posedge clk_o);
          t1 = ticks;
          @(posedge clk_o);
          per_new = ticks - t1;

          // Make sure the period is now less than it was.
          //
          // We actually should expect that the new clock period is strictly
          // less than the old one, but the FDT stage of the clock generator
          // uses loading capacitance to affect the speed which is not modeled
          // in RTL therefore changes in the FDT will show up as identical
          // periods.
          //
          assert(per_new <= per_old)
            $write("%6d",per_new);
           // $display("Passed: old per=%-d -- new per=%-d", per_old, per_new);
          else
            $display("\n***FAILED: old per=%-d -- new per=%-d", per_old, per_new);


          // Shift for next iteration
          //
          per_old = per_new;
          if (per_new < min_per)
            min_per = per_new;
        end

      /*******************************************************************/
      /*                                                                 */
      /*                     INCREASE DOWNSAMPLE                         */
      /*                                                                 */
      /*******************************************************************/

      clk_sel = 2'b01;      // look at the downsampled clock

      // go through each downsample amount
      for (integer i = 0; i < (1 << bsg_ds_width_lp) ; i++)
        begin

           if (i[$bits(bsg_clk_gen_osc_tag_payload_s)-1:0] == 0)
             $write("\nDwnsmpl:");

           ds_tag_header.data_not_reset = 1;
           ds_tag_payload.val = i;

           for (integer j = 0; j < ds_pkt_size_lp; j=j+1)
             begin
                @(negedge bsg_tag_clk);
                bsg_tag_data = ds_pkt[j];
             end

          // wait a few clock cycles to make sure the packet propagates
          // through synchronizers

          for (integer j = 0; j < 4; j++)
              @(posedge bsg_tag_clk);
          for (integer j = 0; j < 3; j++)
              @(posedge clk_o);

          // Measure the clock period
          //
          @(posedge clk_o);
          t1 = ticks;
          @(posedge clk_o);
          per_new = ticks - t1;

          // Make sure the period is now the correct downsampled factor of the
          // original clock period
          //

           assert(per_new == min_per*(i+1)*2)
             $write("%6d",per_new);
           //$display("Passed: per=%-d -- expected per=%-d*%-d=%-d", per_new, per_old, (i+1)*2, per_old*(i+1)*2);
           else
             $display("***FAILED: per=%-d -- expected per=%-d*%-d=%-d", per_new, min_per, (i+1)*2, min_per*(i+1)*2);
        end // for (integer i = 0; i < (1 << bsg_ds_width_lp) ; i++)

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
