// MBT 8-27-14
//
// This is the "whole enchilada" for full-duplex DDR calibrated
// communication over multiple source-synchronous channels :
//
//    - bsg_assembler_in
//    - bsg_assembler_out
//    - source_synchronous_in
//    - source_synchronous_out
//    - bsg_source_sync_channel_control_slave
//    - bsg_source_sync_channel_control_master
//    - bsg_source_sync_channel_control_master_master
//
// ** CLOCKS
//
// There are many clocks in this module, and synchronizer
// conventions must be obeyed when mixing signals in
// different domains. Moreover, they need to be generated
// as clocks in physical design.
//
// We use the following conventions for signals:
//
// core_                    : synchronous to core clock domain
// im_                      : synchronous to the io_master_clk (for output channels)
// io_ [link_channels_p]    : synchronous to one of N input channel clocks,
//                            each potentially with a different freq/phase
// token_ [link_channels_p] : synchronous to one of N incoming token clocks
//
//    signals in the core clock domain begin with core_
//    signals in the channel's clock domains begin with channel_
//
//
// ** RESETS
//
// All resets in this module are synchronous.
// Care has been made to synchronize all of the resets.
// See notes below for token reset.

/*
  Reset is the hardest part about this module.

  Here is the reset timeline:

FPGA:
  async_reset 0'd for 16  [C0,C1,M0,M1] cycles.  <test_bsg_comm_link>
  async_reset 1'd for 256 [C0,C1,M0,M1] cycles.  <test_bsg_comm_link>
  async_reset 0'd

 bsg_comm_link:
    async_reset --> CO CO -> core_reset (C0)
    async_reset --> M0 M0 -> im_reset   (MO)

   MO:
      im_start_calibration_n goes high
      master_lg_wait_after_reset_p M0 cycles after im_reset goes lo <bsg_comm_link>,
      causing start_i is asserted on master_master.
      1 M0 cycle later, prepare_o goes high in master_master
             -> im_channel_reset -> token_reset
           (prepare_o goes low after master_calib_prepare_cycles_p)
       1 M0 cycle later
         a. im_slave_reset_tline_r_o goes high ----> ASIC async_reset_i (slave)
         b. out_ctr_r in master starts at zero
      2^master_lg_token_width_p cycles later, token act goes high (QQ)
      2^master_lg_token_width_p cycles later, token act goes lo (ZZ)

   im_channel_reset -> {M0,I0n,IOn} -> io_reset (I0n) --> token_bypass (BB)

  IOn:


ASIC:

     ASIC async_reset_i {C1,C1}'d --> core_reset (C1)
     ASIC async_reset_i {M1,M1}'d --> im_reset (M1)
                                     = token_reset = im_channel_reset
     async_reset_i {In,In}'d --> io_reset (I1n)= token_bypass

    M1:

      1 M1 cycle later
      slave enters sBegin state
      out_ctr_r is zeroed

     (2^slave_lg_token_width_p) M1 cycles later, token bit goes high. (XX)
     (2^slave_lg_token_width_p) M1 cycles later, token bit goes low. (YY)

     I1n:
       1 In cycle later, token_bypass is enabled (QQ)


    C1:
     A few cycles later, the fifos in the core are reset.

 Race condition tests:
     (BB) master token bypass must go high after ASIC token_reset
          when prepare signal goes high:
            master: prepare->M0->ASIC reset_hi->M1->M1->token_reset
                    prepare->M0->I0n->I0n->token_bypass
            since IOn = M1/2 (DDR); we know we are always safe.
     (QQ) token_bypass must enabled before token bit goes hi from FPGA
        if we do not do this, we could fail to properly reset
        the token signal.
          --> Since I1n = 2 M0, this case is easy; basically around 6 M0
              i.e. 2^master_lg_token_width_p > 6. A bigger constraint
              is we want to slow things down by the token decimation factor.
              :: simple solution; make sure master_lg_token_width_p >= 5
     (ZZ) token act must have time to go hi and then lo before token_bypass goes low
     before async_reset_i goes low. This means lg_token_width_p is too
     long relative to prepare_cycles.
              :: Make sure prepare_cycles >> 2**(master_lg_token_width_p+1)

     (XX) ASIC token_activation must go high after FPGA token_reset hi
       --> currently token_reset goes high before ASIC_reset is even asserted
           so this is always satisfied.
           :: keep slave_lg_token_width_p = 5 (or at least the decimation factor)
     (YY) ASIC token_activation must complete before FPGA token_reset goes lo
       --> master_calib_prepare_cycles_p x M0 > (3+2^slave_lg_token_width_p) x M1
       --> master_calib_prepare_cycles_p > (3+2^slave_lg_token_width_p) x (M1 / M0)

     (SS) prepare_hold_cycles. we need to make sure that somehow the changed data
          does not get to wherever before the reset gets to where it needs to go.
          going out of the FPGA, these should be pretty evenly matched in M0 cycles.
          the reset has to go through two M1 latches that the data does not have to.
          so, to be safe 10 + 5*(M1/M0) should be more than adequate.
     (CC) prepare_hold_cycles. we need to make sure that enough cycles have passed
          for the core to reset so that the inputs to the source synchronous
          channels are valid.
          --> master_calib_prepare_cycles >  ~5 * C1/M0

*/

`include "bsg_defines.v"

module bsg_comm_link
  #(parameter channel_width_p   = "inv"
    , parameter core_channels_p = "inv"
    , parameter link_channels_p = "inv"
    , parameter nodes_p         = "inv" // how many nodes on the FSB
    , parameter master_p        = "inv" // 1=FPGA,0=ASIC

    // e.g if you have four channels, and you wanted any
    // subset of them to be supported, you would
    // provide 1111. if you only want all four channels
    // to be supported, then you provide 1000.
    //
    // any combination of channels
    , parameter channel_mask_p=(1 << (link_channels_p))-1

    // NB: master_  parameters only apply to the master

    // this is the maximum ratio between master io frequency
    // and the min of: slave io frequency
    //                 slave core frequency
    //                 master core frequency
    //
    // that we want to support.
    // Used only by master.
    , parameter master_to_slave_speedup_p = 100

    // have this node enabled at startup (typ. 0 for ASIC; 1 for FPGA)
    , parameter enabled_at_start_vec_p     = (nodes_p) ' (0)

    // * PARAMETERS
    // * below here mostly can be left alone
    // *
    // *
    // *

    // enable this if comm_link appears on the critical path
    // adds one core cycle of latency in or out
    // and two channel_width_p*link_channels fifos.

    , parameter sbox_pipeline_in_p  = 1'b1
    , parameter sbox_pipeline_out_p = 1'b1

    // made this node see all packets (typ. 0 for ASIC and FPGA)
    , parameter snoop_vec_p               = (nodes_p) ' (0)

    // in testing, use this to disable tests
    , parameter master_bypass_test_p = 5'b00000


    // for DDR at 500 mbps, we make token go at / 8 = 66 mbps
    // this will keep the token clock nice and slow
    // careful: values other than 3 have not been tested.

    , parameter lg_credit_to_token_decimation_p = 3

    // lg of how many cycles to wait to assert token reset
    // also how many cycles to assert it for
    // keep these at 5; bigger is not necessarilybetter.
    // bigger is not necessarily better for token_width
    // keep these at 5, unless token_decimation
    // increases.
    , parameter master_lg_token_width_p = lg_credit_to_token_decimation_p+2
    , parameter slave_lg_token_width_p  = lg_credit_to_token_decimation_p+2

    // time after reset to start calibration process
    , parameter master_lg_wait_after_reset_p = $clog2(1+master_to_slave_speedup_p*128)

    // time to assert reset before calibration code
    , parameter master_calib_prepare_cycles_p
         = master_to_slave_speedup_p
           * 2 * (2**(master_lg_token_width_p+1)+2**(slave_lg_token_width_p+1))

    // time to hold calibration code after reset
    // see derivation in master_master
    , parameter master_lg_out_prepare_hold_cycles_p
         = $clog2(5*master_to_slave_speedup_p+10)

    // fixme: derive value better (we reduced this to 25 from 5000 for simulation)
    // 25 might actually be okay

    , parameter master_calib_timeout_cycles_p = master_to_slave_speedup_p * 25

    )
   (input core_clk_i
    , input async_reset_i

    , input io_master_clk_i

    // into nodes (control)
    , output [nodes_p-1:0] core_node_reset_r_o
    , output [nodes_p-1:0] core_node_en_r_o

   // into nodes (fsb interface)
    , output [nodes_p-1:0] core_node_v_o
    , output [core_channels_p*channel_width_p-1:0] core_node_data_o [nodes_p-1:0]
    , input  [nodes_p-1:0] core_node_ready_i

    // out of nodes (fsb interface)
    , input  [nodes_p-1:0] core_node_v_i
    , input  [core_channels_p*channel_width_p-1:0] core_node_data_i [nodes_p-1:0]
    , output [nodes_p-1:0] core_node_yumi_o

    // use this as a reset signal if you want to wakeup
    // after the comm link has woken up.

    , output                       core_calib_reset_r_o

    // in from i/o
    , input  [link_channels_p-1:0] io_valid_tline_i
    , input  [channel_width_p-1:0] io_data_tline_i [link_channels_p-1:0]
    , input  [link_channels_p-1:0] io_clk_tline_i       // clk
    , output [link_channels_p-1:0] io_token_clk_tline_o // clk

    // out to i/o
    , output [link_channels_p-1:0] im_valid_tline_o
    , output [channel_width_p-1:0] im_data_tline_o [link_channels_p-1:0]
    , output [link_channels_p-1:0] im_clk_tline_o       // clk

    // note: generate by the master (FPGA) and sent to the slave (ASIC)
    // not used by slave (ASIC).
    , output reg                      im_slave_reset_tline_r_o

    , input  [link_channels_p-1:0] token_clk_tline_i    // clk

    // note: this is almost never the right reset to use
    // as it occurs before the channels come up
    // safest thing is to not connect it
    , output core_async_reset_danger_o
    );

   // if we have more than 2X the number of core channels than link channels
   // we should use a channel narrow gadget to simplify the circuit
   // higher multiples are possible but TBD.

   localparam bao_narrow_lp = (
                               ((core_channels_p / 2) >= link_channels_p)
                               & (core_channels_p % 2) == 0
                               ) ? 2 : 1;

   // across all frequency combinations, we need a little over 20 fifo slots
   // so we round up to 32, to allow for delay in the FPGA

   localparam lg_input_fifo_depth_lp = 5;

   // synchronized resets for incoming i/o channels

   wire [link_channels_p-1:0]  io_reset;

   wire [link_channels_p-1:0]  io_calib_done;
   wire                        im_reset;

   wire [link_channels_p-1:0]  im_clk_init;

   wire                        im_slave_reset_tline_n;

   wire                        core_reset_i;

   assign core_async_reset_danger_o = core_reset_i;

   // synchronize core and im resets
   bsg_sync_sync #(.width_p(1)) core_reset_ss
     (.oclk_i(core_clk_i)
      , .iclk_data_i(async_reset_i)
      , .oclk_data_o(core_reset_i)
      );

   bsg_sync_sync #(.width_p(1)) im_reset_ss
     (.oclk_i(io_master_clk_i)
      , .iclk_data_i(async_reset_i)
      , .oclk_data_o(im_reset)
      );

   // register true output signals
   always @(posedge io_master_clk_i)
     im_slave_reset_tline_r_o <= im_slave_reset_tline_n;

   wire [link_channels_p-1:0]  core_asm_to_sso_valid;
   wire [channel_width_p-1:0]  core_asm_to_sso_data [link_channels_p-1:0];
   wire [link_channels_p-1:0]  core_asm_to_sso_ready;

   wire [link_channels_p-1:0]  core_ssi_to_asm_valid;
   wire [channel_width_p-1:0]  core_ssi_to_asm_data [link_channels_p-1:0];
   wire [link_channels_p-1:0]  core_ssi_to_asm_yumi;

   wire [link_channels_p-1:0]  core_asm_to_sso_valid_sbox
                               , core_ssi_to_asm_valid_sbox;

   wire [channel_width_p-1:0]  core_asm_to_sso_data_sbox [link_channels_p-1:0];
   wire [channel_width_p-1:0]  core_ssi_to_asm_data_sbox [link_channels_p-1:0];

   wire [link_channels_p-1:0]  core_asm_to_sso_ready_sbox
                               , core_ssi_to_asm_yumi_sbox;

   // synchronous to im clock
   wire [link_channels_p-1:0]   im_override_en;
   wire [channel_width_p+1-1:0] im_override_valid_data [link_channels_p-1:0];
   wire [link_channels_p-1:0]   im_override_is_posedge, im_infinite_credits_en;

   // synchronous to io clocks
   wire [channel_width_p+1-1:0] io_snoop_valid_data_pos [link_channels_p-1:0];
   wire [channel_width_p+1-1:0] io_snoop_valid_data_neg [link_channels_p-1:0];
   wire [link_channels_p-1:0] 	io_trigger_mode_en, io_trigger_mode_alt_en;

   wire [link_channels_p-1:0]   core_loopback_en;
   wire [link_channels_p-1:0]   core_channel_active, im_channel_active;

   // computed from channel_active signals
   logic [`BSG_MAX(0,$clog2(link_channels_p)-1):0] core_top_active_channel_bao_r, core_top_active_channel_bai_r, core_top_active_channel_n;
   logic [`BSG_MAX(0,$clog2(link_channels_p+1)-1):0] active_channel_count;

   bsg_popcount #(.width_p(link_channels_p)) pop (.i(core_channel_active)
                                                  ,.o(active_channel_count) );


   // how many channels are alive?
   assign core_top_active_channel_n = (| core_channel_active) ? (active_channel_count - 1) : '0;

   // clone this register to keep it off critical paths

   bsg_dff #(.harden_p(1)
             ,.strength_p(4)
             ,.width_p(`BSG_MAX(1,$clog2(link_channels_p)))
            ) core_top_active_channel_bai_r_reg
     (.clock_i(core_clk_i)
      ,.data_i(core_top_active_channel_n)
      ,.data_o(core_top_active_channel_bai_r)
      );

   bsg_dff #(.harden_p(1)
             ,.strength_p(4)
             ,.width_p(`BSG_MAX(1,$clog2(link_channels_p)))
            ) core_top_active_channel_bao_r_reg
     (.clock_i(core_clk_i)
      ,.data_i(core_top_active_channel_n)
      ,.data_o(core_top_active_channel_bao_r)
      );

   localparam tests_p = 5;

   wire im_calib_done, im_calib_done_r;
   wire core_calib_done_prefanout_r;

   bsg_launch_sync_sync #(.width_p(1)) out_to_core_sync_calib_done
     (.iclk_i(io_master_clk_i)
      ,.iclk_reset_i(1'b0)
      ,.oclk_i(core_clk_i)
      ,.iclk_data_i(im_calib_done)
      ,.iclk_data_o(im_calib_done_r)
//      ,.oclk_data_o(core_calib_done_r)
      ,.oclk_data_o(core_calib_done_prefanout_r)
      );

   // generate pipelined reset tree
   wire [5:0]              core_calib_done_vec_r;
   assign core_calib_reset_r_o = ~core_calib_done_vec_r[0];

   genvar                  k;

   for (k = 0; k < 6; k=k+1)
     begin: cr
        bsg_dff #(.harden_p(1)
                  ,.strength_p(4)
                  ,.width_p(1)
                  ) core_calib_reset_fanout_reg
          (.clock_i(core_clk_i)
           ,.data_i(core_calib_done_prefanout_r)
           ,.data_o(core_calib_done_vec_r[k])
           );
     end


   if (master_p)
     begin : mstr
        // counter intuitive; organized by tests then by channel
        wire [tests_p+1-1:0][link_channels_p-1:0] im_test_scoreboard;
        wire [$clog2(tests_p+1)-1:0]              im_test_index;  // + 1; for the "final test"
        wire                                      im_prepare;

        // assert the tline
        assign im_slave_reset_tline_n = im_prepare;

        logic  im_start_calibration_n, im_start_calibration_r;

        // wait a certain number of cycles after global reset to start
        // global calibration

        bsg_wait_after_reset #(.lg_wait_cycles_p(master_lg_wait_after_reset_p)) bwar
          (.clk_i(io_master_clk_i)
           ,.reset_i  (im_reset)
           ,.ready_r_o(im_start_calibration_n)
           );

        always_ff @(posedge io_master_clk_i)
          im_start_calibration_r <= im_start_calibration_n;

        bsg_source_sync_channel_control_master_master
          #(.link_channels_p(link_channels_p)
            ,.tests_p(tests_p)
            ,.prepare_cycles_p(master_calib_prepare_cycles_p)
            ,.timeout_cycles_p(master_calib_timeout_cycles_p)
            ) master_master

            (.clk_i(io_master_clk_i)
             ,.reset_i          (im_reset)
             ,.start_i         (~im_start_calibration_r & im_start_calibration_n )
             ,.test_scoreboard_i(im_test_scoreboard)
             ,.test_index_r_o   (im_test_index     )
             ,.prepare_o        (im_prepare        )
             ,.done_o           (im_calib_done     )
             );

        always_ff @(negedge io_master_clk_i)
          if (im_calib_done & ~im_calib_done_r)
            $display("###### Master calibration COMPLETED with active channels: (%b)."
                     , im_channel_active);
      end // block: mstr
   else // slave
     begin
        // the slave is done calibrating if any of the channels are
        // active. since activation goes high only when im_reset goes
        // low, all channels will all activate at the same time.
        //
        // no waiting for differences in channel clocks is necessary.
        //

        assign im_calib_done          = (|im_channel_active);
        assign im_slave_reset_tline_n = 1'b0;
     end

   wire im_channel_reset, core_channel_reset;

   genvar i,j;

   logic  im_reset_r;

   if (master_p)
     begin : rreg
        always @(posedge io_master_clk_i)
          im_reset_r <= im_reset;
     end

  // create all of the input and output channels
   for (i = 0; i < link_channels_p; i=i+1)
     begin: ch

             bsg_launch_sync_sync #(.width_p(1)) blss_channel_active
               (.iclk_i      (io_master_clk_i)
                ,.iclk_reset_i(im_reset)
                ,.oclk_i      (core_clk_i)
                ,.iclk_data_i (im_channel_active[i])
                ,.iclk_data_o()
                ,.oclk_data_o (core_channel_active[i])
                );

        if (master_p)
          begin :m
             wire [tests_p+1-1:0] im_tests_gather;

             for (j = 0; j < tests_p+1; j=j+1)
               begin : mpa
                  assign mstr.im_test_scoreboard[j][i] = im_tests_gather[j];
               end

             bsg_source_sync_channel_control_master
               #(.width_p(channel_width_p)
                 ,.lg_token_width_p(master_lg_token_width_p)
                 ,.lg_out_prepare_hold_cycles_p(master_lg_out_prepare_hold_cycles_p)
                 ,.bypass_test_p(master_bypass_test_p)
                 ,.tests_lp(tests_p)
                 ) control_master
             (
              .out_clk_i                 (io_master_clk_i)
              ,.out_reset_i              (im_reset)

              ,.out_calibration_state_i  (mstr.im_test_index)
              ,.out_calib_prepare_i      (mstr.im_prepare)

              ,.out_channel_blessed_i    (im_channel_active[i])

              ,.out_override_en_o         (im_override_en          [i])
              ,.out_override_valid_data_o (im_override_valid_data  [i])
              ,.out_override_is_posedge_i (im_override_is_posedge  [i])

              ,.in_clk_i                 (io_clk_tline_i          [i])

              // reset synchronized to io_clk_tline_i
              ,.in_reset_i               (io_reset                [i])
              ,.in_snoop_valid_data_neg_i(io_snoop_valid_data_neg [i])
              ,.in_snoop_valid_data_pos_i(io_snoop_valid_data_pos [i])

              // AWC fixme: incorrect name should be output clocked, not in clocked
              // i.e. should be:
              ,.out_infinite_credits_o (im_infinite_credits_en[i])
              //,.in_infinite_credits_o    (io_infinite_credits_en  [i])

              ,.out_test_pass_r_o        ( im_tests_gather )
              );

             assign im_channel_reset = mstr.im_prepare;

             bsg_launch_sync_sync #(.width_p(1)) io_reset_lss
               (.iclk_i      (io_master_clk_i)
                ,.iclk_reset_i(1'b0)
                ,.oclk_i      (io_clk_tline_i[i])
                ,.iclk_data_i (im_channel_reset)
                ,.iclk_data_o()
                ,.oclk_data_o (io_reset[i])
                );

             // generate core_channel reset from im_channel reset
             bsg_launch_sync_sync #(.width_p(1)) bssi_reset
               (.iclk_i(io_master_clk_i)
                ,.iclk_reset_i(1'b0)
                ,.oclk_i(core_clk_i)
                ,.iclk_data_i(im_channel_reset)
                ,.iclk_data_o()
                ,.oclk_data_o(core_channel_reset)
                );

             assign io_trigger_mode_en     [i]     = 1'b0;
             assign io_trigger_mode_alt_en [i]     = 1'b0;
             assign core_loopback_en       [i]     = 1'b0;

`ifndef SYNTHESIS
             // activate the channel if all of the "real" tests passed
             // MBT: we use triple equals because this handles the X case in simulation
             //      DC of course does not like ===
             assign im_channel_active[i] = (im_tests_gather[tests_p-1:0] === { tests_p {1'b1} });
`else
             assign im_channel_active[i] = (im_tests_gather[tests_p-1:0] == { tests_p {1'b1} });
`endif
             assign im_clk_init            [i]      = im_reset & ~im_reset_r;

          end
        else
          begin : s

             // no launch flop necessary here
             // and we synchronize directly from
             // the async reset for speed
             bsg_sync_sync #(.width_p(1)) io_reset_ss
               (.oclk_i(io_clk_tline_i[i])
                , .iclk_data_i(async_reset_i)
                , .oclk_data_o(io_reset[i])
                );

             assign core_channel_reset = core_reset_i;

             assign im_channel_reset   = im_reset;

             bsg_source_sync_channel_control_slave
               #(.width_p(channel_width_p)
                 ,.lg_token_width_p(slave_lg_token_width_p)
                 )
             control_slave
             (// output channel
              .out_clk_i                  (io_master_clk_i)

              ,.out_reset_i               (im_reset)
              ,.out_clk_init_r_o          (im_clk_init            [i])
              ,.out_override_en_o         (im_override_en         [i])
              ,.out_override_valid_data_o (im_override_valid_data [i])

              // whether the channel is available for I/O assembler, post reset
              ,.out_channel_active_o      (im_channel_active      [i])

              // for input channel
              ,.in_clk_i                     (io_clk_tline_i             [i])

              ,.in_snoop_valid_data_i        (io_snoop_valid_data_pos    [i])
              ,.in_trigger_mode_en_o         (io_trigger_mode_en         [i])
              ,.in_trigger_mode_alt_en_o     (io_trigger_mode_alt_en     [i])

              // AWC fixme: incorrect name should be output clocked, not in clocked
              // i.e. should be:

              ,.out_infinite_credits_o (im_infinite_credits_en[i])
              //,.in_infinite_credits_o        (io_infinite_credits_en     [i])

              // for core control
              ,.core_clk_i                   (core_clk_i                    )
              ,.core_loopback_en_o           (core_loopback_en           [i])
              );
          end


        // The token reset strategy for metastability is different,
        // because clocking the token clock increments a counter. Introducing
        // a synchronizer for the reset requires for us to control the token reset
        // precisely relative to the token clock, which cannot easily be done
        // from another clock domain.
        //
        // Instead, we tie the token reset to the im reset, and avoid
        // metastability by requiring the master reset be asserted for many cycles
        // before going low.
        //
        // During that reset period, we toggle the token clock to clear out state.
        // The token clock should only be toggled again (in normal use) a safe
        // number of cycles after reset goes low.

        wire      token_reset = im_channel_reset;

        bsg_source_sync_output
          #(.lg_start_credits_p(lg_input_fifo_depth_lp)
            ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
            ,.channel_width_p(channel_width_p)
            ) sso
            (.core_clk_i(core_clk_i)
             ,.core_reset_i(core_channel_reset)

             ,.core_data_i (core_loopback_en[i]
                            ? core_ssi_to_asm_data [i]
                            : core_asm_to_sso_data_sbox [i])
             ,.core_valid_i(core_loopback_en[i]
                            ? core_ssi_to_asm_valid[i]
                            : core_asm_to_sso_valid_sbox[i])

             // fixme: any special treatment required for loopback?
             ,.core_ready_o(core_asm_to_sso_ready [i])

             ,.io_master_clk_i(io_master_clk_i)
             ,.io_reset_i     (im_channel_reset)
             ,.io_clk_init_i  (im_clk_init[i])

             ,.io_override_en_i        (im_override_en[i]        )
             ,.io_override_valid_data_i(im_override_valid_data[i])
             ,.io_override_is_posedge_o(im_override_is_posedge[i])

             ,.io_clk_r_o(  im_clk_tline_o     [i])
             ,.io_data_r_o( im_data_tline_o    [i])
             ,.io_valid_r_o(im_valid_tline_o   [i])

              // AWC fixme: incorrect name should be output clocked, not in clocked
              // i.e. should be:
	     ,.io_infinite_credits_i (im_infinite_credits_en[i])
             //,.io_infinite_credits_i (io_infinite_credits_en[i])

             ,.token_clk_i  (token_clk_tline_i [i])
             ,.token_reset_i(token_reset    )
             );

        bsg_launch_sync_sync #(.width_p(1)) im_to_io_calib_done
          (.iclk_i      (io_master_clk_i)
           ,.iclk_reset_i(1'b0)
           ,.oclk_i      (io_clk_tline_i[i])
           ,.iclk_data_i (im_calib_done)
           ,.iclk_data_o()
           ,.oclk_data_o (io_calib_done[i])
           );

        bsg_source_sync_input
          #(.lg_fifo_depth_p(lg_input_fifo_depth_lp)
            ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
            ,.channel_width_p(channel_width_p)
            ) ssi
            // starts on reset lo->hi xition
          (.io_clk_i     (io_clk_tline_i       [i])
           ,.io_data_i   (io_data_tline_i      [i])
           ,.io_valid_i  (io_valid_tline_i     [i])
           ,.io_token_r_o(io_token_clk_tline_o [i])

           // note a small quirk: for the master, we tie reset of the
           // input channel to the calibration being done rather
           // than the channel reset. this is because for the most
           // part the input channel is not used during calibration.

           // for the master, we keep this unit quiet until calibration is done
           // for the slave,  we need to use this unit, but we reset it for each
           // phase of calibration

           ,.io_reset_i(master_p ? ~io_calib_done[i] : io_reset[i])

           // for both master and slave, prepare/reset mode enables token bypass
           // i.e.; we reset the token on every Phase.
           //

           ,.io_token_bypass_i(io_reset[i])

           ,.io_edge_i(2'b11)  // latch on both edges; could change on the fly

           ,.io_snoop_pos_r_o(io_snoop_valid_data_pos[i]) // snoop input channel
                                                          // for establishing calib.
                                                          // state on reset
           ,.io_snoop_neg_r_o(io_snoop_valid_data_neg[i])

           // enable loop-back trigger mode
           ,.io_trigger_mode_en_i    (io_trigger_mode_en    [i])

           // enable loop-back trigger mode: alternate trigger
           ,.io_trigger_mode_alt_en_i(io_trigger_mode_alt_en[i])

           ,.core_clk_i  (core_clk_i)
           ,.core_reset_i(core_channel_reset)

           // core 1 side logical signals
           ,.core_data_o (core_ssi_to_asm_data  [i] )
           ,.core_valid_o(core_ssi_to_asm_valid [i] )
           ,.core_yumi_i (core_loopback_en[i]
                          ? (core_asm_to_sso_ready[i] & core_ssi_to_asm_valid[i])
                          : core_ssi_to_asm_yumi_sbox[i])
           );

        // only used by master; ignore for slave
        // wire           ignore = | io_snoop_valid_data_neg[i];
     end // block: channel


   //***************************************************
   //
   // SBOX, ASSEMBLER AND FRONT SIDE BUS
   //
   //
   // fixme: the code after this point
   // could be factored into another file
   //
   //***************************************************

   bsg_sbox #(.num_channels_p(link_channels_p)
              ,.channel_width_p(channel_width_p)
              ,.pipeline_indir_p(sbox_pipeline_in_p)
              ,.pipeline_outdir_p(sbox_pipeline_out_p)
              ) sbox
     (.clk_i(core_clk_i)
      ,.reset_i(core_reset_i)
      ,.calibration_done_i(core_calib_done_vec_r[1])
      ,.channel_active_i(core_channel_active)

      ,.in_v_i   (core_ssi_to_asm_valid)
      ,.in_data_i(core_ssi_to_asm_data      )
      ,.in_yumi_o(core_ssi_to_asm_yumi_sbox )

      ,.in_v_o   (core_ssi_to_asm_valid_sbox )
      ,.in_data_o(core_ssi_to_asm_data_sbox  )
      ,.in_yumi_i(core_ssi_to_asm_yumi       )

      ,.out_me_v_i    (core_asm_to_sso_valid      )
      ,.out_me_data_i (core_asm_to_sso_data       )
      ,.out_me_ready_o(core_asm_to_sso_ready_sbox )

      ,.out_me_v_o    (core_asm_to_sso_valid_sbox )
      ,.out_me_data_o (core_asm_to_sso_data_sbox  )
      ,.out_me_ready_i(core_asm_to_sso_ready      )
      );

    // outgoing from fsb to nrw
   wire                                       core_nrw_valid_li;
   wire [core_channels_p*channel_width_p-1:0] core_nrw_data_li;
   wire                                       core_nrw_ready_lo;

   // outgoing from nrw to asm
   wire                                         core_asm_valid_li;
   wire [core_channels_p*channel_width_p/bao_narrow_lp-1:0] core_asm_data_li;
   wire                                         core_asm_ready_lo;

   // out to core
   wire                                       core_asm_valid_lo;
   wire [core_channels_p*channel_width_p-1:0] core_asm_data_lo;
   wire                                       core_asm_yumi_li;

   typedef logic [`BSG_MAX($clog2(core_channels_p/bao_narrow_lp),1)-1:0] bsg_comm_link_active_out_vec_t;
   typedef logic [`BSG_MAX($clog2(core_channels_p),1)-1:0]               bsg_comm_link_active_in_vec_t;

   // de-bond channel into multiple individual channels
   bsg_assembler_out #(.width_p(channel_width_p)
                       ,.num_in_p(core_channels_p/bao_narrow_lp)
                       ,.num_out_p(link_channels_p)
                       ,.out_channel_count_mask_p(channel_mask_p)
                       ) bao
     (.clk     (core_clk_i  )
      ,.reset  (core_channel_reset)
      ,.calibration_done_i(core_calib_done_vec_r[2])
      ,.valid_i(core_asm_valid_li)
      ,.data_i (core_asm_data_li )
      ,.ready_o(core_asm_ready_lo)

      // typesafe equivalent to core_channels_p-1
      ,.in_top_channel_i( (bsg_comm_link_active_out_vec_t ' (core_channels_p/bao_narrow_lp))
                          - 1'b1
                          )
      ,.out_top_channel_i(core_top_active_channel_bao_r)

      ,.valid_o(core_asm_to_sso_valid)
      ,.data_o( core_asm_to_sso_data )
      ,.ready_i(core_asm_to_sso_ready_sbox)
      );

   // we will not say that data is available unless
   // calibration is done; keeps interface clean.

   wire                  core_valid_tmp;
   assign core_asm_valid_lo = core_valid_tmp & core_calib_done_vec_r[2];

  // merge them into one bonded channel
   bsg_assembler_in #(.width_p(channel_width_p)
                       ,.num_in_p(link_channels_p)
                       ,.num_out_p(core_channels_p)
                       ,.in_channel_count_mask_p(channel_mask_p)
                       ) bai
   (.clk     (core_clk_i  )
    ,.reset              (core_channel_reset)
    ,.calibration_done_i (core_calib_done_vec_r[3] )
    ,.valid_i(core_ssi_to_asm_valid_sbox)
    ,.data_i (core_ssi_to_asm_data_sbox )
    ,.yumi_o (core_ssi_to_asm_yumi      )

    ,.in_top_channel_i(core_top_active_channel_bai_r)

    // typesafe equivalent to core_channels_p-1
    ,.out_top_channel_i((bsg_comm_link_active_in_vec_t ' (core_channels_p)) - 1'b1)

    ,.valid_o(core_valid_tmp)
    ,.data_o (core_asm_data_lo   )
    ,.yumi_i (core_asm_yumi_li   )
    );

   if (bao_narrow_lp == 2)
     begin: nrw
        bsg_fifo_1r1w_narrowed #(.width_p(channel_width_p*core_channels_p)
                                 ,.els_p(2)
                                 ,.width_out_p(channel_width_p*core_channels_p/bao_narrow_lp)
                                 ) nrw
          (.clk_i(core_clk_i)
           ,.reset_i(~core_calib_done_vec_r[4])

           // from FSB
           ,.v_i    (core_nrw_valid_li)
           ,.data_i (core_nrw_data_li )
           ,.ready_o(core_nrw_ready_lo)

           // to assembler
           ,.v_o   (core_asm_valid_li)
           ,.data_o(core_asm_data_li)
           ,.yumi_i(core_asm_ready_lo & core_asm_valid_li)
           );
     end // block: nrw
                  else
                  begin : not_nrw
                  assign core_asm_valid_li = core_nrw_valid_li;
                  assign core_asm_data_li  = core_nrw_data_li;
        assign core_nrw_ready_lo = core_asm_ready_lo;
     end

   bsg_fsb #(.width_p(channel_width_p*core_channels_p)
             ,.nodes_p(nodes_p)
             ,.enabled_at_start_vec_p(enabled_at_start_vec_p)
             ,.snoop_vec_p(snoop_vec_p)
             ) fsb
     (.clk_i   (core_clk_i)
      ,.reset_i(~core_calib_done_vec_r[5])

      // from assembler
      ,.asm_v_i   (core_asm_valid_lo)
      ,.asm_data_i(core_asm_data_lo )
      ,.asm_yumi_o(core_asm_yumi_li )

      // to assembler
      ,.asm_v_o    (core_nrw_valid_li)
      ,.asm_data_o (core_nrw_data_li )
      ,.asm_ready_i(core_nrw_ready_lo)

      // into nodes
      ,.node_v_o      (core_node_v_o      )
      ,.node_data_o   (core_node_data_o   )
      ,.node_ready_i  (core_node_ready_i  )
      ,.node_en_r_o   (core_node_en_r_o   )
      ,.node_reset_r_o(core_node_reset_r_o)

      // out of nodes
      ,.node_v_i   (core_node_v_i   )
      ,.node_data_i(core_node_data_i)
      ,.node_yumi_o(core_node_yumi_o)
      );

endmodule
