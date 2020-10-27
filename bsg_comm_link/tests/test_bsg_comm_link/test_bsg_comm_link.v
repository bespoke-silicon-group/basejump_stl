
`include "bsg_defines.v"

`include "test_assembler_defines.v"

module test_bsg_comm_link;

`include "test_bsg_clock_params.v"


   // number of bits width of a channel
   // must be >= 3; with channel_width = 3
   // calibration will be limited

   localparam channel_width_lp         = `CHANNEL_WIDTH;
   localparam num_channels_lp          = `NUM_CHANNELS;

   // this is the number of bytes that a ring packet is
   localparam ring_bytes_lp            = `RING_BYTES;

   localparam iterations_lp            = `ITERATIONS;

   localparam verbose_lp  = 1;

   // most flexible configuration for assembler
   // any subset of channels (4,3,2,1) may be used
   localparam channel_mask_lp          = (1 << num_channels_lp) - 1;

   genvar                      i,j;

   // *************************************************
   // independent clocks and reset
   //
   //

   logic [1:0] core_clk;
   logic [1:0] io_master_clk;

   test_bsg_clock_gen #(.cycle_time_p(core_0_period_lp))  c0_clk    (.o(     core_clk[0]));
   test_bsg_clock_gen #(.cycle_time_p(core_1_period_lp))  c1_clk    (.o(     core_clk[1]));

   initial
     $display("%m creating clocks",core_0_period_lp, core_1_period_lp, io_master_0_period_lp, io_master_1_period_lp);

   test_bsg_clock_gen #(.cycle_time_p(io_master_0_period_lp)) i0_clk (.o(io_master_clk[0]));
   test_bsg_clock_gen #(.cycle_time_p(io_master_1_period_lp)) i1_clk (.o(io_master_clk[1]));


   logic async_reset;

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

   // Defines for Core Zero and One

   wire [1:0]                                core_reset_in;
   wire [1:0]                                core_calib_reset;

   wire [1:0]                                core_valid_out;
   wire [ring_bytes_lp*channel_width_lp-1:0] core_data_out [1:0];
   wire [1:0]                                core_yumi_out;

   wire [1:0]                                core_valid_in;
   wire [ring_bytes_lp*channel_width_lp-1:0] core_data_in  [1:0];
   wire [1:0]                                core_ready_in;

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


   // CORE ZERO Send (speaking valid/ready protocol)
   // core_ready signal will be held low by comm_link
   // module until calibration is done.

   assign core_valid_out[0] = ~core_reset_in[0];

   test_bsg_data_gen #(.channel_width_p(channel_width_lp)
                       ,.num_channels_p(ring_bytes_lp)
                       ) tbdg_send
   (.clk_i(core_clk[0]      )
    ,.reset_i(core_reset_in[0]) // this is a core, so should be woken up
                                // when cores wakeup
    ,.yumi_i (core_yumi_out[0])
    ,.o      (core_data_out[0])
    );

   // CORE ZERO Receive (speaking valid/yumi protocol)
   //

   // always eat the data
   assign core_ready_in[0] = 1'b1;


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


   logic  [1:0]                  core_async_reset, core_async_reset_r;

   bsg_two_fifo #( .width_p(channel_width_lp*ring_bytes_lp)) core_one_fifo
     (.clk_i(core_clk[1])

      ,.reset_i(core_reset_in[1])

      ,.ready_o(core_ready_in[1])
      ,.v_i    (core_valid_in[1])
      ,.data_i (core_data_in [1])

      ,.v_o   (core_valid_out[1])
      ,.data_o(core_data_out [1])
      ,.yumi_i(core_yumi_out [1])
      );

   always @(posedge io_master_clk[1])
     begin
        core_async_reset_r[1] <= core_async_reset[1];
        if (~core_async_reset[1] & core_async_reset_r[1])
          begin
             $display("            _                                       ");
             $display("           (_)                                  _   ");
             $display(" _____  ___ _  ____     ____ _____  ___ _____ _| |_ ");
             $display("(____ |/___) |/ ___)   / ___) ___ |/___) ___ (_   _)");
             $display("/ ___ |___ | ( (___   | |   | ____|___ | ____| | |_ ");
             $display("\\_____(___/|_|\\____)  |_|   |_____|___/|_____)  \\__)");
             $display("                                                    ");
          end
     end


   //************************************************************
   //  CORE 1 (input side)
   //   ______ _____  ______  _______     ______              __
   //  / _____) ___ \(_____ \(_______)   / __   |     _      /  |
   // | /    | |   | |_____) )_____     | | //| |   _| |_   /_/ |
   // | |    | |   | (_____ (|  ___)    | |// | |  (_   _)    | |
   // | \____| |___| |     | | |_____   |  /__| |    |_|      | |
   //  \______)_____/      |_|_______)   \_____/              |_|
   //
   //************************************************************

   // external signals
   logic [num_channels_lp-1:0]  io_clk_tline  [1:0], io_valid_tline [1:0];
   logic [channel_width_lp-1:0] io_data_tline [1:0] [num_channels_lp-1:0];
   logic [num_channels_lp-1:0]  token_clk_tline                     [1:0];
   wire [1:0]                  slave_reset_tline;


   //************************************************************
   // BREAK PCB WIRES HERE.
   //
   // modify these lines to test stuck-at faults due to assembly
   // issues or just even bad silicon.
   //
   // watch this crazy thing adapt to faults!
   //

   // A. to FPGA

   // always @(io_data_tline[1][0]) force io_data_tline[1][0][channel_width_lp-1] = 1; // 0
   // always @(io_data_tline[1][0]) force io_data_tline[1][1][channel_width_lp-1] = 1; // 1
   // always @(io_data_tline[1][0]) force io_data_tline[1][2][channel_width_lp-1] = 1; // 2
   // always @(io_data_tline[1][0]) force io_data_tline[1][3][channel_width_lp-1] = 1; // 3

   // always @(io_data_tline[1][0]) force io_data_tline[0][0][channel_width_lp-1] = 1;
   // always @(io_data_tline[1][0]) force io_data_tline[0][1][channel_width_lp-1] = 1; // 1
   // always @(io_data_tline[1][0]) force io_data_tline[0][2][channel_width_lp-2] = 1; // 2

   // B. to ASIC

   // also: test contamination of calibration code
   // always @(io_data_tline[1][0]) force io_data_tline[0][3][channel_width_lp-1] = 0; //  3
   // always @(io_data_tline[1][0]) force io_valid_tline[0][3] = 1;  //  3

   for (i = 0; i < 2; i++)
     begin : core

        wire [ring_bytes_lp*channel_width_lp-1:0] core_node_data_lo [0:0];
        wire [ring_bytes_lp*channel_width_lp-1:0] core_node_data_li [0:0];

        // type translation
        assign core_data_in     [i] = core_node_data_lo[0];
        assign core_node_data_li[0] = core_data_out    [i];

        // convention: for signals going between cores
        // the "from core" is used as the index.

        bsg_comm_link #(.channel_width_p  (channel_width_lp)
                        , .core_channels_p   (ring_bytes_lp)
                        , .link_channels_p (num_channels_lp)
                        , .nodes_p(1)
                        , .channel_mask_p(channel_mask_lp)
                        , .master_p(!i)
                        , .master_to_slave_speedup_p(master_to_slave_speedup_lp)
                        , .snoop_vec_p(1'b1)           // ignore packet formats
                        , .enabled_at_start_vec_p(1'b1) // enable at start
                        , .master_bypass_test_p(5'b1_1_1_1_1)
                        ) comm_link
          (.core_clk_i           (core_clk        [i] )
           , .async_reset_i      ( (i ? slave_reset_tline[0] : async_reset) )
           , .core_calib_reset_r_o(core_calib_reset [i] )

           , .io_master_clk_i    (io_master_clk   [i] )

           // in from core
           , .core_node_v_i(core_valid_out [i])
           , .core_node_data_i(core_node_data_li)
           , .core_node_yumi_o(core_yumi_out[i])

           // out to core
           , .core_node_v_o(core_valid_in    [i])
           , .core_node_data_o(core_node_data_lo)
           , .core_node_ready_i(core_ready_in [i])

           // ignore enable and reset.
           , .core_node_en_r_o()
           , .core_node_reset_r_o(core_reset_in[i])

           // in from i/o
           , .io_valid_tline_i(      io_valid_tline [!i])
           , .io_data_tline_i(        io_data_tline [!i])
           , .io_clk_tline_i(          io_clk_tline [!i])  // clk
           , .io_token_clk_tline_o( token_clk_tline [i] )  // clk

           // out to i/o
           , .im_valid_tline_o(io_valid_tline[i])
           , .im_data_tline_o(  io_data_tline[i])
           , .im_clk_tline_o(    io_clk_tline[i])             // clk

           , .im_slave_reset_tline_r_o ( slave_reset_tline[i])
           , .token_clk_tline_i(token_clk_tline[!i])          // clk

           // use core_calib_reset instead!
           , .core_async_reset_danger_o (core_async_reset      [i] )
           );
     end

   localparam cycle_counter_width_lp=32;

   // create some counters to track the four clocks in the system
   logic [cycle_counter_width_lp-1:0] core_ctr[1:0];
   logic [cycle_counter_width_lp-1:0] io_ctr  [1:0];

   // valid only in testbench code: reset violation

   for (i = 0; i < 2; i=i+1)
     begin
	bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
	my_core_ctr (.clk_i(core_clk[i]), .reset_i(core_calib_reset[i]), .ctr_r_o(core_ctr[i]));

	bsg_cycle_counter #(.width_p(cycle_counter_width_lp))
	my_io_ctr   (.clk_i(io_master_clk[i]), .reset_i(core_calib_reset[i]), .ctr_r_o(io_ctr[i]));

        test_bsg_comm_link_checker
            #(.channel_width_p(channel_width_lp)
              ,.num_channels_p(num_channels_lp)
              ,.ring_bytes_p  (ring_bytes_lp)
              ,.verbose_p     (verbose_lp)
              ,.iterations_p  (iterations_lp)
              ,.core_0_period_p(core_0_period_lp)
              ,.core_1_period_p(core_1_period_lp)
              ,.io_master_0_period_p(io_master_0_period_lp)
              ,.io_master_1_period_p(io_master_1_period_lp)
              ,.cycle_counter_width_p(cycle_counter_width_lp)
	      ,.node_num_p(i)
              ) checker
            (.clk           (core_clk[i])
             ,.valid_in(core_valid_in[i])
             ,.ready_in(core_ready_in[i])
             ,.data_in (core_data_in[i] )
             ,.data_out(core_data_out[i])
             ,.yumi_out(core_yumi_out[i])
             ,.async_reset(core_async_reset[i])
             ,.slave_reset_tline(slave_reset_tline[i])
             ,.io_valid_tline(io_valid_tline[i])
             ,.io_data_tline (io_data_tline[i])
	     ,.core_ctr(core_ctr)
	     ,.io_ctr(io_ctr)
             );
     end

 endmodule

