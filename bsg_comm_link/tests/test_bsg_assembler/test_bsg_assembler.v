// MBT 8-20-2014
//
// Test assembler
//
// We model here two cores that have different clocks and are
// communicating over an I/O channel which has a third clock.
//
// Includes model reset logic with synchronizers and delayed
// communication after reset.
//

// these defines can be overridden by command line parameters

`include "bsg_defines.v"

`include "test_assembler_defines.v"

module test_assembler;

   initial begin
      $vcdpluson;
      $vcdplusmemon;
      end

   // three separate clocks: I/O, and the two cores communicating with each other
   localparam core_0_half_period_lp    = `CORE_0_HALF_PERIOD;
   localparam io_master_half_period_lp = `IO_MASTER_HALF_PERIOD;
   localparam core_1_half_period_lp    = `CORE_1_HALF_PERIOD;

   localparam iterations_lp            = `ITERATIONS;

   // number of bits width of a channel
   localparam channel_width_lp         = `CHANNEL_WIDTH;
   localparam num_channels_lp          = `NUM_CHANNELS;

   // this is the number of bytes that a ring packet is
   localparam ring_bytes_lp            = `RING_BYTES;

   // across all frequency combinations, we need a little over 20 fifo slots
   // so we round up to 32, to allow for delay in the FPGA

   localparam lg_input_fifo_depth_lp = 5;

   // for DDR at 500 mbps, we make token go at / 8 = 66 mbps
   // this will keep the token clock nice and slow

   localparam lg_credit_to_token_decimation_lp=3;



   // *************************************************
   // independent clocks
   //
   //

   logic core_0_clk, core_1_clk, io_master_clk;

   initial core_0_clk = 0;
   always #(core_0_half_period_lp) core_0_clk = ~core_0_clk;


   initial io_master_clk = 0;
   always #(io_master_half_period_lp) io_master_clk = ~io_master_clk;

   initial core_1_clk = 0;
   always #(core_1_half_period_lp) core_1_clk = ~core_1_clk;


   // *************************************************
   // master resets
   //

   logic core_0_reset, core_1_reset;

   localparam core_reset_cycles_hi_lp = 256;
   localparam core_reset_cycles_lo_lp = 16;

   // we model this as if the FPGA is driving this with an unknown clock.
   initial
     begin
        core_0_reset = 0;
        core_1_reset = 0;
        // simple hack to wait based on maximum of clock periods
        repeat (core_reset_cycles_lo_lp)
          begin
             @(negedge core_0_clk);
             @(negedge core_1_clk);
             @(negedge io_master_clk);
          end

        core_0_reset = 1;
        core_1_reset = 1;
        // simple hack to wait based on maximum of clock periods
        repeat (core_reset_cycles_hi_lp)
          begin
             @(negedge core_0_clk);
             @(negedge core_1_clk);
             @(negedge io_master_clk);
          end

        core_0_reset = 0;
        core_1_reset = 0;

        $display("__________ ___________  _______________________________");
        $display("\\______   \\\\_   _____/ /   _____/\\_   _____/\\__    ___/");
        $display(" |       _/ |    __)_  \\_____  \\  |    __)_   |    |   ");
        $display(" |    |   \\ |        \\ /        \\ |        \\  |    |   ");
        $display(" |____|_  //_______  //_______  //_______  /  |____|   ");
        $display("        \\/         \\/         \\/         \\/            ");
     end

   //**********************************************************************
   //  CORE 0 (sender)
   //    ______ _____  ______  _______    _______ _______ ______   _____
   //   / _____) ___ \(_____ \(_______)  (_______|_______|_____ \ / ___ \
   //  | /    | |   | |_____) )_____        __    _____   _____) ) |   | |
   //  | |    | |   | (_____ (|  ___)      / /   |  ___) (_____ (| |   | |
   //  | \____| |___| |     | | |_____    / /____| |_____      | | |___| |
   //   \______)_____/      |_|_______)  (_______)_______)     |_|\_____/
   //
   //**********************************************************************

   wire core_0_reset_sync, io_master_reset_sync, token_reset_sync;

   // reset synchronizer: core clock reset
   bsg_sync_sync #(.width_p(1)) bss_core_reset
     (.oclk_i(core_0_clk)
      ,.iclk_data_i(core_0_reset)
      ,.oclk_data_o(core_0_reset_sync)
      );

   // reset synchronizer: master clock reset
   bsg_sync_sync #(.width_p(1)) bss_io_master_reset
     (.oclk_i(io_master_clk)
      ,.iclk_data_i(core_0_reset)
      ,.oclk_data_o(io_master_reset_sync)
      );

   // reset synchronizer: token reset
   bsg_sync_sync #(.width_p(1)) bss_token_reset
     (.oclk_i(io_master_clk)
      ,.iclk_data_i(core_0_reset)
      ,.oclk_data_o(token_reset_sync)
      );

   logic [channel_width_lp-1:0] core_0_data_r;
   logic core_0_valid_r;

   // wait a certain number of cycles after reset before restarting
   localparam lg_wait_cycles_activate_lp = 4;
   wire  core_reset_ready;

   bsg_wait_after_reset #(.lg_wait_cycles_p(lg_wait_cycles_activate_lp)) bwar
     (.reset_i(core_0_reset_sync)
      ,.clk_i(core_0_clk)
      ,.ready_r_o(core_reset_ready)
      );

   // only start sending after a certain number of cycles
   assign core_0_valid_r = core_reset_ready;

   wire  core_0_assembler_ready;
   wire  core_0_yumi = core_0_assembler_ready & core_0_valid_r;

   // transmit sequence of data values
   always @(posedge core_0_clk)
     if (core_0_reset_sync)
       core_0_data_r <= 0;
     else
       if (core_0_yumi)
         core_0_data_r <= core_0_data_r + 1;


   // ***********************************************
   // TOKEN RESET LOGIC
   //
   // reset logic for clearing output channel's
   // token-clocked logic.
   //

   logic io_override_en;
   logic [channel_width_lp+1-1:0] io_override_valid_data;
   logic                          io_master_reset_sync_r;
   logic [10:0]                   io_reset_counter_r;

   always @(posedge io_master_clk)
     begin
        io_master_reset_sync_r <= io_master_reset_sync;

        // on positive edge of reset, we initialize the counter
        // the counter continuously counts during reset
        // and is zero'd when not in reset
        if (io_master_reset_sync)
          begin
             if (~io_master_reset_sync_r)
               io_reset_counter_r <= 1;
             else
               io_reset_counter_r <= io_reset_counter_r + 1;
          end
        else
          io_reset_counter_r <= 0;
     end

   // this asserts the override data while the reset counter
   // is in its active portion

   always_comb
     begin
        io_override_en = io_master_reset_sync;
        io_override_valid_data = { 0'b0, 0'h00 };

        // for 2^6 cycles, assert the "token reset code"
        if (io_reset_counter_r[10:6] == 5'b00001)
          io_override_valid_data = { 1'b1, 8'h80 };
     end

   // entertainingly, we need to label both sides
   // of the if statement the same thing in order
   // to have the variable top_active_channel
   // resolve later in the file (to xkr.top_active_channel)
   if (num_channels_lp < 2)
     begin: xkr
        wire top_active_channel = 1'b0;
     end
   else
     begin: xkr
        wire [$clog2(num_channels_lp)-1:0] top_active_channel
          = $clog2(num_channels_lp)' (num_channels_lp-1'b1);
     end

   genvar i;

   wire [channel_width_lp-1:0] core_0_send_data [ring_bytes_lp-1:0];

   localparam lg_ring_bytes_lp = $clog2(ring_bytes_lp);

   wire [$max(lg_ring_bytes_lp-1,0):0] ring_bytes
                                       = $max(lg_ring_bytes_lp,1) ' (ring_bytes_lp);

   if (ring_bytes_lp > 1)
     for (i = 0; i < ring_bytes_lp; i++)
       begin
          wire [lg_ring_bytes_lp-1:0] my_id = i[lg_ring_bytes_lp-1:0];
          assign core_0_send_data[i]
            = { my_id, core_0_data_r[0+:channel_width_lp-lg_ring_bytes_lp]};
       end
   else
     assign core_0_send_data[0] = core_0_data_r;

   // ***********************************************
   //
   // out assembler
   //
   //

   wire [num_channels_lp-1:0]  channel_valids;
   wire [num_channels_lp-1:0]  channel_readys;
   wire [channel_width_lp-1:0] channel_datas [num_channels_lp-1:0];

   // de-bond channel into multiple individual channels
   bsg_assembler_out #(.width_p(channel_width_lp)
                       ,.num_in_p(ring_bytes_lp)
                       ,.num_out_p(num_channels_lp)
                       ,.out_channel_count_mask_p(1 << (num_channels_lp-1)) // fixme
                       ) bao
   (.clk(core_0_clk)
    ,.reset(core_0_reset_sync)
    ,.valid_i(core_0_valid_r)
    ,.data_i(core_0_send_data )
    ,.ready_o(core_0_assembler_ready)

    ,.in_top_channel_i(ring_bytes-1'b1)
    ,.out_top_channel_i(xkr.top_active_channel)

    ,.valid_o(channel_valids)
    ,.data_o( channel_datas)
    ,.ready_i(channel_readys)
    );

   // ***********************************************
   // declare signals going out over transmission lines
   // between input and output channel
   //

   wire [num_channels_lp-1:0]  io_clk_tline, io_valid_tline;
   wire [channel_width_lp-1:0] io_data_tline [num_channels_lp-1:0];
   wire [num_channels_lp-1:0]  token_clk_tline;


   // create a bunch of channels
   for (i = 0; i < num_channels_lp; i=i+1)
     begin: bsso
        bsg_source_sync_output
            #(.lg_start_credits_p(lg_input_fifo_depth_lp)
              ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_lp)
              ,.channel_width_p(channel_width_lp)
              ) bsso
            (.core_clk_i(core_0_clk)
             ,.core_reset_i(core_0_reset_sync)

             // core 0 side logical signals
             ,.core_data_i(channel_datas[i])
             ,.core_valid_i(channel_valids[i])
             ,.core_ready_o(channel_readys[i])

             ,.io_master_clk_i(io_master_clk)
             ,.io_reset_i(io_master_reset_sync)

             ,.io_override_en_i(io_override_en)
             ,.io_override_valid_data_i(io_override_valid_data)

             ,.io_clk_r_o(io_clk_tline[i])                // output to other node
             ,.io_data_r_o(io_data_tline[i])              // output to other node
             ,.io_valid_r_o(io_valid_tline[i])            // output to other node

             ,.token_clk_i(token_clk_tline[i])            // input from other node
             // from core 0  // fixme is this signal correctly named?
             ,.token_reset_i(token_reset_sync)
      );

     end

   //************************************************************
   //  CORE 1 (input side)
   //   ______ _____  ______  _______     _____  ______  _______
   //  / _____) ___ \(_____ \(_______)   / ___ \|  ___ \(_______)
   // | /    | |   | |_____) )_____     | |   | | |   | |_____
   // | |    | |   | (_____ (|  ___)    | |   | | |   | |  ___)
   // | \____| |___| |     | | |_____   | |___| | |   | | |_____
   //  \______)_____/      |_|_______)   \_____/|_|   |_|_______)
   //
   //************************************************************

   localparam lg_io_delay_reset_lp = 6;

   wire [num_channels_lp-1:0] io_1_reset_sync;
   wire core_1_reset_sync;

   bsg_sync_sync #(.width_p(1)) bss_core_1_reset
     (.oclk_i(core_1_clk)
      ,.iclk_data_i(core_1_reset)
      ,.oclk_data_o(core_1_reset_sync)
      );


   wire [num_channels_lp-1:0]  core_1_assembler_yumi;
   wire [num_channels_lp-1:0]  core_1_assembler_valid;
   wire [channel_width_lp-1:0] core_1_assembler_data [num_channels_lp-1:0];

   // merged channel
   wire                        core_1_valid, core_1_yumi;
   wire [channel_width_lp*ring_bytes_lp-1:0] core_1_data;

   // create a bunch of channels
   for (i = 0; i < num_channels_lp; i=i+1)
     begin
        bsg_sync_sync #(.width_p(1)) bss_io_1_reset
            (.oclk_i(io_clk_tline[i])
             ,.iclk_data_i(core_1_reset)
             ,.oclk_data_o(io_1_reset_sync[i])
             );

        bsg_source_sync_input
          #(.lg_fifo_depth_p(lg_input_fifo_depth_lp)
            ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_lp)
            ,.channel_width_p(channel_width_lp)
            ) bssi
            (.io_clk_i(io_clk_tline[i])               // input from other node; starts on reset
             ,.io_reset_i(io_1_reset_sync[i])
             ,.io_data_i(io_data_tline[i])      // input from other node
             ,.io_valid_i(io_valid_tline[i])    // input from other node

             ,.io_edge_i(2'b11)                 // latch on both edges

             ,.io_token_r_o(token_clk_tline[i]) // output to other node

             ,.io_snoop_r_o()                // snoop input channel;
                                             // for establishing calibration state
                                             // on reset

             ,.io_trigger_mode_en_i(1'b0)        // enable loop-back trigger mode
             ,.io_trigger_mode_alt_en_i(1'b0)    // enable loop-back trigger mode: alternate trigger

             ,.core_clk_i(core_1_clk)
             ,.core_reset_i(core_1_reset_sync)

             // core 1 side logical signals
             ,.core_data_o(core_1_assembler_data[i])
             ,.core_valid_o(core_1_assembler_valid[i])
             ,.core_yumi_i(core_1_assembler_yumi[i])
             );
     end

   // merge them into one bonded channel
   bsg_assembler_in #(.width_p(channel_width_lp)
                       ,.num_in_p(num_channels_lp)
                       ,.num_out_p(ring_bytes_lp)
                       ,.in_channel_count_mask_p(1 << (num_channels_lp-1)) // fixme
                       ) bai
   (.clk(core_1_clk)
    ,.reset(core_1_reset_sync)
    ,.valid_i(core_1_assembler_valid)
    ,.data_i(core_1_assembler_data)
    ,.yumi_o(core_1_assembler_yumi)

    ,.in_top_channel_i(xkr.top_active_channel)
    ,.out_top_channel_i(ring_bytes-1'b1)

    ,.valid_o(core_1_valid)
    ,.data_o(core_1_data)
    ,.yumi_i(core_1_yumi)
    );

   // consume all data
   assign core_1_yumi = core_1_valid;

   localparam cycle_counter_width_lp=32;

   logic [cycle_counter_width_lp-1:0] core_0_ctr;
   bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
   bcc_core0 (core_0_clk, core_0_reset_sync, core_0_ctr);

   logic [cycle_counter_width_lp-1:0] core_1_ctr;
   bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
   bcc_core1 (core_1_clk, core_1_reset_sync, core_1_ctr);

   logic [cycle_counter_width_lp-1:0] io_ctr;
   bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
   bcc_io (io_master_clk, io_master_reset_sync, io_ctr);


   // non-synthesizable, TEST ONLY
   logic [7:0] core_1_last_n, core_1_last_r = -1;
   logic [5:0] top_bits = 0;

   assign core_1_last_n = core_1_last_r+8'b1;

   wire [ring_bytes_lp*channel_width_lp-1:0] core_1_check_data;

   if (ring_bytes_lp > 1)
     for (i = 0; i < ring_bytes_lp; i++)
       begin
          wire [lg_ring_bytes_lp-1:0] my_id = i[lg_ring_bytes_lp-1:0];
          assign core_1_check_data[channel_width_lp*i+:channel_width_lp]
            = { my_id, core_1_last_n[0+:channel_width_lp-lg_ring_bytes_lp]};
       end
   else
     assign core_1_check_data = core_1_last_n;

   // *******************************************************
   // *
   // * Logging.
   // *
   // * These statements allow you to see, in time, when values
   // * are transmitted and received.
   // *
   // *
   // * For this test, the number of cycles on the slowest clock should
   // * match the number of words
   // * transmitted plus a small constant.
   // *
   // *

   logic [31:0]                       core_1_words_received_r;

   always @(negedge core_1_clk)
     if (core_1_reset_sync)
       core_1_words_received_r <= 0;
     else
       core_1_words_received_r <= core_1_words_received_r + core_1_valid;

   integer                            verbose = 0;

   always @(negedge core_1_clk)
     if (core_1_valid)
       begin
          if (verbose)
            $display("## ", core_0_ctr, io_ctr, core_1_ctr
                     , " ## core 1 recv %d, %x",top_bits,core_1_data);

          assert (core_1_check_data == core_1_data)
            else $error("## transmission error %x, %x"
                        , core_1_check_data, core_1_data);
          core_1_last_r <= core_1_last_n;
          if (core_1_last_n == 8'hff)
            begin
               if (top_bits == iterations_lp)
                 begin
                    $display("## DONE CHANNEL_WIDTH=%1d",channel_width_lp
                             ," RING_BYTES=%2d",ring_bytes_lp
                             ," NUM_CHAN=%1d",num_channels_lp
                             ," C0_HP=%1d",core_0_half_period_lp
                             ," IO_HP=%1d",io_master_half_period_lp
                             ," C1_PD=%1d",core_1_half_period_lp,
                             ," (Cycles Per Word) "
                             , real'(core_0_ctr) / real'(core_1_words_received_r)," "
                             , real'(io_ctr) / real'(core_1_words_received_r), " "
                             , real'(core_1_ctr) / real'(core_1_words_received_r));
                    $finish("##");
                 end
               top_bits = top_bits+1;
            end
       end

   always @(negedge core_0_clk)
     if (core_0_yumi)
       if (verbose)
         $display("## ", core_0_ctr, io_ctr, core_1_ctr
                  , " ## core 0 sent %lx",core_0_send_data);

   for (i = 0; i < num_channels_lp; i=i+1)
     begin
        always @(negedge io_master_clk)
          if (verbose)
            begin
               if (io_valid_tline[i])
                 $display("## ", core_0_ctr, io_ctr, core_1_ctr
                          , " ## channel %1d", i
                          , " (p,n)=(%2d",bsso[i].bsso.bacc1.r_free_credits
                          ,",%2d",bsso[i].bsso.bacc2.r_free_credits,") "
                          ," ## io     xmit %x",io_data_tline[i]);
               else
                 $display("## ", core_0_ctr, io_ctr, core_1_ctr
                          , " ## channel %1d", i, " (p,n)=(%2d"
                          ,bsso[i].bsso.bacc1.r_free_credits
                          ,",%2d",bsso[i].bsso.bacc2.r_free_credits,") ");
            end
     end
endmodule

