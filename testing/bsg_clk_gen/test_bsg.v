`define WIDTH_P ?   // unused for now...

`include "config_defs.v"

module test_bsg;

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

  // Vectors to send down config_net to program the clock generator
  //
  logic [39:0] vector;
  logic [5:0]  ctrl;
  logic [7:0]  ds_value;
  
  // Clock generator signals
  //
  config_s    cfg;
  logic       async_rst;
  logic       sync_rst;
  logic       ext_clk;
  logic [1:0] clk_sel;
  logic       clk_o;
  
  // Config net configuration clock. Instead of turning this clock off
  // and on to send packets through config_net, we instead set a bit
  // stream of 0's to signify no data.
  //
  bsg_nonsynth_clock_gen #(1000) cfg_clk_gen (cfg.cfg_clk);
  
  // Exteral clock which gets passed through the clock generator
  //
  bsg_nonsynth_clock_gen #(250) ext_clk_gen (ext_clk);
  
  // DEVICE UNDER TEST --> BSG Clk Gen
  //
  bsg_clk_gen #(.downsample_width_p(8),.cnode_id_p(8'b00000000)) DUT
    (.config_i(cfg)
    ,.async_rst_i(async_rst)
    ,.reset_i(sync_rst)
    ,.ext_clk_i(ext_clk)
    ,.select_i(clk_sel)
    ,.clk_o(clk_o)
    );
  
  // All testing happens here
  //
  initial
    begin

      cfg.cfg_bit = 1'b0;
      async_rst = 1'b0;
      sync_rst = 1'b0;
      clk_sel = 2'b00;

      $display("                                                           ");
      $display("***********************************************************");
      $display("*                                                         *");
      $display("*                  SIMULATION BEGIN                       *");
      $display("*                                                         *");
      $display("***********************************************************");
      $display("                                                           ");

      /*******************************************************************/
      /*                                                                 */
      /*                        BOOT SEQUENCE                            */
      /*                                                                 */
      /*******************************************************************/
  
      // perform an async reset. should see life in the clock generator
      //
      #1000;
      async_rst = 1'b1;
      #1000;
      async_rst = 1'b0;
  
      // will stall if the generator doesn't boot
      //
      clk_sel = 2'b00;
      for (integer i = 0; i < 10; i++)
          @(posedge clk_o);

      // Reset sequence for config net
      //
      @(negedge cfg.cfg_clk);
      cfg.cfg_bit = 1'b1;
      for (integer i = 0; i < 10; i++)
          @(posedge cfg.cfg_clk);
      @(negedge cfg.cfg_clk);
      cfg.cfg_bit = 1'b0;

      // syncronous reset for downsampler and config net output registers
      //
      @(negedge clk_o);
      sync_rst = 1'b1;
      @(negedge clk_o);
      sync_rst = 1'b0;

      // will stall if the downsampler doesn't get reset properly
      //
      clk_sel = 2'b01;
      for (integer i = 0; i < 10; i++)
          @(posedge clk_o);

      // quick check to make sure the external clock pass-though is working
      //
      clk_sel = 2'b10;
      for (integer i = 0; i < 10; i++)
        begin
          @(clk_o);
          assert(clk_o == ext_clk);
        end

      clk_sel = 2'b11;
      for (integer i = 0; i < 10; i++)
        begin
          @(clk_o);
          assert(clk_o == ext_clk);
        end

      // end boot sequence, let's start testing!
      //
      $display("Clock generator is alive... begin testing!");

      /*******************************************************************/
      /*                                                                 */
      /*                     INCREASE CLOCK SPEED                        */
      /*                                                                 */
      /*******************************************************************/

      clk_sel = 2'b00;      // look at the raw clock generator
      per_old = 2**32;      // make large for first test to pass

      // go through each clock speed setting
      for (integer i = 0; i < 2**6; i++)
        begin

          $display("Clock Setting -- %b", i[5:0]);

          // create the config_net packet to send
          //
          ctrl = i[5:0];
          vector = {12'b0_0_00000000_0_0, ctrl, 22'b0_0_00000000_0_00101000_0_10};

          // send the packet through config_net
          //
          @(negedge cfg.cfg_clk);
          for (integer i = 0; i < 40; i++)
            begin
              cfg.cfg_bit = vector[i];
              @(posedge cfg.cfg_clk);
            end
          @(negedge cfg.cfg_clk);
          cfg.cfg_bit = 1'b0;

          // wait a few clock cycles to make sure the packet propagates
          // and the syncronizer registers have been passed
          //
          for (integer j = 0; j < 5; j++)
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
            $display("Passed: old per=%-d -- new per=%-d", per_old, per_new);
          else
            $display("***FAILED: old per=%-d -- new per=%-d", per_old, per_new);

          // Shift for next iteration
          //
          per_old = per_new;

        end

      /*******************************************************************/
      /*                                                                 */
      /*                     INCREASE DOWNSAMPLE                         */
      /*                                                                 */
      /*******************************************************************/

      clk_sel = 2'b01;      // look at the downsampled clock

      // go through each downsample amount
      for (integer i = 0; i < 2**8; i++)
        begin

          $display("Downsample Value -- %b", i[7:0]);

          // create the config_net packet to send
          //
          ds_value = i[7:0];
          vector = {3'b000, ds_value[7:1], 1'b0, ds_value[0], 28'b1111110_0_00000000_0_00101000_0_10};

          // send the packet through config_net
          //
          @(negedge cfg.cfg_clk);
          for (integer i = 0; i < 40; i++)
            begin
              cfg.cfg_bit = vector[i];
              @(posedge cfg.cfg_clk);
            end
          @(negedge cfg.cfg_clk);
          cfg.cfg_bit = 1'b0;

          // wait a few clock cycles to make sure the packet propagates
          //
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
          assert(per_new == per_old*(i+1)*2)
            $display("Passed: per=%-d -- expected per=%-d*%-d=%-d", per_new, per_old, (i+1)*2, per_old*(i+1)*2);
          else
            $display("***FAILED: per=%-d -- expected per=%-d*%-d=%-d", per_new, per_old, (i+1)*2, per_old*(i+1)*2);

        end

      $display("                                                           ");
      $display("***********************************************************");
      $display("*                                                         *");
      $display("*                 SIMULATION FINISHED                     *");
      $display("*                                                         *");
      $display("***********************************************************");
      $display("                                                           ");
      $finish;

    end
  
  // Count the number of timescale ticks that occur throughout simulation
  //
  always #1 ticks = ticks + 1'b1;

endmodule
