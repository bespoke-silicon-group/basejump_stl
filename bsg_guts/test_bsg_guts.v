`include "test_assembler_defines.v"

module test_bsg_guts;


`include "test_bsg_clock_params.v"

//initial begin
//   $vcdpluson;
//   $vcdplusmemon;
//end

   localparam num_channels_lp          = `NUM_CHANNELS;

//
   localparam channel_width_lp         = 8;

   // this is the number of bytes that a ring packet is
   localparam ring_bytes_lp            = `RING_BYTES;

   localparam iterations_lp            = `ITERATIONS;

   localparam verbose_lp  = 0;

   // *************************************************
   // independent clocks and reset
   //
   //

   logic [1:0] core_clk;
   logic [1:0] io_master_clk;

   test_bsg_clock_gen #(.cycle_time_p(core_0_period_lp))  c0_clk    (.o(     core_clk[0]));
   test_bsg_clock_gen #(.cycle_time_p(core_1_period_lp))  c1_clk    (.o(     core_clk[1]));

   initial
     $display("%m creating clocks",core_0_period_lp, core_1_period_lp,
              io_master_0_period_lp, io_master_1_period_lp);

   test_bsg_clock_gen #(.cycle_time_p(io_master_0_period_lp)) i0_clk (.o(io_master_clk[0]));
   test_bsg_clock_gen #(.cycle_time_p(io_master_1_period_lp)) i1_clk (.o(io_master_clk[1]));

   logic       async_reset;

   localparam core_reset_cycles_hi_lp = 256;
   localparam core_reset_cycles_lo_lp = 16;

   test_bsg_reset_gen
     #(.num_clocks_p(4)
       ,.reset_cycles_lo_p(core_reset_cycles_lo_lp)
       ,.reset_cycles_hi_p(core_reset_cycles_hi_lp)
       ) reset_gen
       (.clk_i({ core_clk, io_master_clk })
        ,.async_reset_o(async_reset)
        );

   logic [num_channels_lp-1:0]  io_clk_tline  [1:0], io_valid_tline [1:0];
   logic [channel_width_lp-1:0] io_data_tline [1:0] [num_channels_lp-1:0];
   logic [num_channels_lp-1:0]  io_token_clk_tline [1:0];
   wire [1:0]                  slave_reset_tline;

   genvar                      i,j;


   localparam cycle_counter_width_lp=32;

   wire [cycle_counter_width_lp-1:0] core_ctr[1:0];
   wire [cycle_counter_width_lp-1:0] io_ctr  [1:0];
   wire [1:0]                        core_calib_reset;

   // how many nodes on each chip
   localparam nodes_lp = 4;

   for (i = 0; i < 2; i++)
     begin: core
	wire [nodes_lp-1:0] 		     done_signals;

        bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
        my_core_ctr (.clk(core_clk[i]), .reset_i(core_calib_reset[i]), .ctr_r_o(core_ctr[i]));

        bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
        my_io_ctr   (.clk(io_master_clk[i]), .reset_i(core_calib_reset[i]), .ctr_r_o(io_ctr[i]));

        bsg_guts #(.num_channels_p(num_channels_lp)
                   ,.master_p(i==0)
                   ,.master_to_slave_speedup_p(master_to_slave_speedup_lp)
                   ,.master_bypass_test_p(5'b11111)
                   ,.enabled_at_start_vec_p(i
                                            ? { (nodes_lp) { 1'b0 } }
                                            : { (nodes_lp) { 1'b1 } })
                   ,.nodes_p(nodes_lp)
                   ) guts
            (.core_clk_i(core_clk[i])
             ,.async_reset_i  (i ? slave_reset_tline[0] : async_reset)
             ,.io_master_clk_i(io_master_clk[i])

             // input from i/o
             ,.io_valid_tline_i    (io_valid_tline    [!i])
             ,.io_data_tline_i     (io_data_tline     [!i])
             ,.io_clk_tline_i      (io_clk_tline      [!i])
             ,.io_token_clk_tline_o(io_token_clk_tline[i]) // clk

             // out to i/o
             , .im_valid_tline_o (io_valid_tline    [i])
             , .im_data_tline_o  (io_data_tline     [i])
             , .im_clk_tline_o   (io_clk_tline      [i])  // clk
             , .token_clk_tline_i(io_token_clk_tline   [!i]) // clk

             , .im_slave_reset_tline_r_o(slave_reset_tline[i])

             , .core_reset_o(core_calib_reset[i])
             );


        for (j = 0; j < nodes_lp; j=j+1)
          begin
             test_bsg_comm_link_checker
                 #(.channel_width_p(channel_width_lp)
                   ,.num_channels_p(num_channels_lp)
                   ,.ring_bytes_p  (10)
		   ,.check_bytes_p (8)
                   ,.verbose_p     (verbose_lp)
                   ,.iterations_p  (iterations_lp)
                   ,.core_0_period_p(core_0_period_lp)
                   ,.core_1_period_p(core_1_period_lp)
                   ,.io_master_0_period_p(io_master_0_period_lp)
                   ,.io_master_1_period_p(io_master_1_period_lp)
                   ,.chip_num_p          (i)
                   ,.node_num_p          (j)
                   ,.cycle_counter_width_p(cycle_counter_width_lp)
                   ) checker
                 (.clk           (     core_clk[i])
                  ,.valid_in(core[i].guts.core_node_v_A    [j])
                  ,.ready_in(core[i].guts.core_node_ready_A[j])
                  ,.data_in (core[i].guts.core_node_data_A [j][ring_bytes_lp*channel_width_lp-1:0])
                  ,.data_out(core[i].guts.core_node_data_B [j][ring_bytes_lp*channel_width_lp-1:0])
                  ,.yumi_out(core[i].guts.core_node_yumi_B [j])
                  ,.async_reset(async_reset)
                  ,.slave_reset_tline(slave_reset_tline[i])
                  ,.io_valid_tline(      io_valid_tline[i])
                  ,.io_data_tline (       io_data_tline[i])
                  ,.core_ctr(core_ctr)
                  ,.io_ctr(io_ctr)
		  ,.done_o(done_signals[j])
                  );
          end

	always @(negedge core_clk[i])
	  if ((& done_signals) == 1'b1)
	    $finish("##");
     end

endmodule
