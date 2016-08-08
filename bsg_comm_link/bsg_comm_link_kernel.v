//--------------------------------------------------------------------------
// University of California, San Diego - Bespoke Systems Group
//--------------------------------------------------------------------------
// File: bsg_comm_link_kernel.v
//
// Authors: Michael Taylor - mbtaylor@ucsd.edu
//          Luis Vega - lvgutierrez@eng.ucsd.edu
//
// clocks:
//
// There are many clocks in this module, and synchronizer conventions must
// be obeyed when mixing signals in different domains. Moreover, they need
// to be generated as clocks in physical design.
//
// We use the following conventions for signals:
//
// core_  : synchronous to core_clk_i domain
// im_    : synchronous to io_master_clk_i
// io_    : synchronous to one of N input channel clocks, each potentially
//          with a different freq/phase
// token_ : synchronous to one of N incoming token clocks
//
// resets:
//
// All resets in this module are synchronous. Care has been made to
// synchronize all of the resets. See notes below for token reset.
//--------------------------------------------------------------------------

/*
  bsg_comm_link_kernel reset timeline:

  FPGA:
    - async_reset 0'd for 16  [C0,C1,M0,M1] cycles. <test_bsg_comm_link>
    - async_reset 1'd for 256 [C0,C1,M0,M1] cycles. <test_bsg_comm_link>
    - async_reset 0'd

  bsg_comm_link:
    - async_reset --> CO CO -> core_reset (C0)
    - async_reset --> M0 M0 -> im_reset   (MO)

  MO:
    - im_start_calibration_n goes high

    - master_lg_wait_after_reset_p M0 cycles after im_reset goes low
    <bsg_comm_link>, causing start_i is asserted on master_master.

    - 1 M0 cycle later, prepare_o goes high in master_master
    -> im_channel_reset -> token_reset
    (prepare_o goes low after master_calib_prepare_cycles_p)

    - 1 M0 cycle later
      a. im_slave_reset_tline_r_o goes high ----> ASIC async_reset_i (slave)
      b. out_ctr_r in master starts at zero
      2^master_lg_token_width_p cycles later, token act goes high (QQ)
      2^master_lg_token_width_p cycles later, token act goes lo (ZZ)

    - im_channel_reset -> {M0,I0n,IOn} -> io_reset(I0n) -> token_bypass(BB)

  ASIC:
    - async_reset_i {C1,C1}'d -> core_reset(C1)
    - async_reset_i {M1,M1}'d -> im_reset(M1)=token_reset=im_channel_reset
    - async_reset_i {In,In}'d -> io_reset(I1n)=token_bypass

  M1:
    - 1 M1 cycle later
    - slave enters sBegin state
    - out_ctr_r is zeroed
    - (2^slave_lg_token_width_p) M1 cycles later, token bit goes high. (XX)
    - (2^slave_lg_token_width_p) M1 cycles later, token bit goes low. (YY)

  I1n:
    - 1 In cycle later, token_bypass is enabled (QQ)

  C1:
    - A few cycles later, the fifos in the core are reset.

  Race condition tests:

    - (BB) master token bypass must go high after ASIC token_reset
      when prepare signal goes high:
        * master: prepare->M0->ASIC reset_hi->M1->M1->token_reset
                  prepare->M0->I0n->I0n->token_bypass
                  since IOn = M1/2 (DDR); we know we are always safe.

    - (QQ) token_bypass must enabled before token bit goes hi from FPGA if
      we do not do this, we could fail to properly reset the token signal.
        * Since I1n = 2 M0, this case is easy; basically around 6 M0
          i.e. 2^master_lg_token_width_p > 6. A bigger constraint
          is we want to slow things down by the token decimation factor.
          :: simple solution; make sure master_lg_token_width_p >= 5

    - (ZZ) token act must have time to go hi and then lo before
      token_bypass goes low before async_reset_i goes low. This means
      lg_token_width_p is too long relative to prepare_cycles.
      :: Make sure prepare_cycles >> 2**(master_lg_token_width_p+1)

    - (XX) ASIC token_activation must go high after FPGA token_reset hi
      * currently token_reset goes high before ASIC_reset is even asserted
        so this is always satisfied.
        :: keep slave_lg_token_width_p = 5 (or at least decimation factor)

    - (YY) ASIC token_activation must complete before FPGA token_reset goes
      low.

      master_calib_prepare_cycles_p x M0 > (3+2^slave_lg_token_width_p) x M1
      master_calib_prepare_cycles_p > (3+2^slave_lg_token_width_p) x (M1/M0)

    - (SS) prepare_hold_cycles. we need to make sure that somehow the
      changed data does not get to wherever before the reset gets to where
      it needs to go. going out of the FPGA, these should be pretty evenly
      matched in M0 cycles. the reset has to go through two M1 latches that
      the data does not have to. so, to be safe 10 + 5*(M1/M0) should be
      more than adequate.

    - (CC) prepare_hold_cycles. we need to make sure that enough cycles
      have passed for the core to reset so that the inputs to the source
      synchronous channels are valid.

      master_calib_prepare_cycles >  ~5 * C1/M0
*/

module bsg_comm_link_kernel #
  (parameter channel_width_p = "inv"
  ,parameter core_channels_p = "inv"
  ,parameter link_channels_p = "inv"

  // 1 = FPGA, 0 = ASIC
  ,parameter master_p = "inv"

  // in testing, use this to disable tests
  ,parameter master_bypass_test_p = 5'b00000

  // Dangerous parameters after this line,
  // please make sure what they mean before changing it

  // NB: master_  parameters only apply to the master
  // this is the maximum ratio between master io frequency
  // and the min of: slave io frequency
  //                 slave core frequency
  //                 master core frequency
  //
  // that we want to support.
  // Used only by master.
  ,parameter master_to_slave_speedup_p = 100

  // for DDR at 500 mbps, we make token go at / 8 = 66 mbps
  // this will keep the token clock nice and slow
  // careful: values other than 3 have not been tested.
  ,parameter lg_credit_to_token_decimation_p = 3

  // across all frequency combinations, we need a little over 20 fifo slots
  // so we round up to 32, to allow for delay in the FPGA
  ,parameter lg_input_fifo_depth_p = 5

  // lg of how many cycles to wait to assert token reset
  // also how many cycles to assert it for
  // keep these at 5; bigger is not necessarilybetter.
  // bigger is not necessarily better for token_width
  // keep these at 5, unless token_decimation
  // increases.
  ,parameter master_lg_token_width_p = lg_credit_to_token_decimation_p + 2
  ,parameter slave_lg_token_width_p = lg_credit_to_token_decimation_p + 2

  // time after reset to start calibration process
  ,parameter master_lg_wait_after_reset_p = $clog2(1 + master_to_slave_speedup_p*128)

  // time to assert reset before calibration code
  ,parameter master_calib_prepare_cycles_p = master_to_slave_speedup_p * 2 * (2**(master_lg_token_width_p+1)+2**(slave_lg_token_width_p+1))

  // time to hold calibration code after reset
  // see derivation in master_master
  ,parameter master_lg_out_prepare_hold_cycles_p = $clog2(5*master_to_slave_speedup_p + 10)

  // fixme: derive value better
  ,parameter master_calib_timeout_cycles_p = master_to_slave_speedup_p*5000)

  (input core_clk_i
  ,input io_master_clk_i
  ,input async_reset_i

  // core ctrl
  ,output                       core_calib_done_r_o
  ,output [link_channels_p-1:0] core_active_channels_o
  ,output                       core_async_reset_danger_o

  // core in
  ,input  [link_channels_p-1:0] core_valid_i
  ,input  [channel_width_p-1:0] core_data_i [link_channels_p-1:0]
  ,output [link_channels_p-1:0] core_ready_o

  // core out
  ,output [link_channels_p-1:0] core_valid_o
  ,output [channel_width_p-1:0] core_data_o [link_channels_p-1:0]
  ,input  [link_channels_p-1:0] core_yumi_i

  // io in
  ,input  [link_channels_p-1:0] io_clk_tline_i
  ,input  [link_channels_p-1:0] io_valid_tline_i
  ,input  [channel_width_p-1:0] io_data_tline_i [link_channels_p-1:0]
  ,output [link_channels_p-1:0] io_token_clk_tline_o

  // im out
  ,output [link_channels_p-1:0] im_clk_tline_o
  ,output [link_channels_p-1:0] im_valid_tline_o
  ,output [channel_width_p-1:0] im_data_tline_o [link_channels_p-1:0]

  // im slave reset for ASIC
  ,output im_slave_reset_tline_r_o

  // token in
  ,input [link_channels_p-1:0] token_clk_tline_i);

  // synchronize core reset

  logic core_reset_lo;

  bsg_sync_sync #
    (.width_p(1))
  core_reset_ss
    (.oclk_i(core_clk_i)
    ,.iclk_data_i(async_reset_i)
    ,.oclk_data_o(core_reset_lo));

  assign core_async_reset_danger_o = core_reset_lo;

  // synchronize io reset

  logic im_reset_lo;

  bsg_sync_sync #
    (.width_p(1))
  im_reset_ss
    (.oclk_i(io_master_clk_i)
    ,.iclk_data_i(async_reset_i)
    ,.oclk_data_o(im_reset_lo));

  // (ASIC) slave reset

  logic im_slave_reset_tline_r;

  assign im_slave_reset_tline_r_o = im_slave_reset_tline_r;

  // calibration done

  logic im_calib_done_lo, im_calib_done_r;
  logic core_calib_done_r;

  bsg_launch_sync_sync #
    (.width_p(1))
  out_to_core_sync_calib_done
    (.iclk_i(io_master_clk_i)
    ,.iclk_reset_i(1'b0)
    ,.oclk_i(core_clk_i)
    ,.iclk_data_i(im_calib_done_lo)
    ,.iclk_data_o(im_calib_done_r)
    ,.oclk_data_o(core_calib_done_r));

  assign core_calib_done_r_o = core_calib_done_r;

  logic [link_channels_p-1:0] im_channel_active;

  always @(negedge io_master_clk_i)
    if (im_calib_done_lo == 1'b1 && im_calib_done_r == 1'b0)
      $display("### %s calibration COMPLETED with active channels: (%b)"
              ,master_p ? "Master" : "Slave"
              ,im_channel_active);

  // common signals for master and slave blocks

  genvar i,j;

  logic im_channel_reset_lo;

  logic [link_channels_p-1:0] im_clk_init;

  logic [link_channels_p-1:0] im_override_en;
  logic [link_channels_p-1:0] im_override_is_posedge;

  logic [channel_width_p+1-1:0] im_override_valid_data [link_channels_p-1:0];

  logic [channel_width_p+1-1:0] io_snoop_valid_data_pos [link_channels_p-1:0];
  logic [channel_width_p+1-1:0] io_snoop_valid_data_neg [link_channels_p-1:0];

  logic [link_channels_p-1:0] io_trigger_mode_en;
  logic [link_channels_p-1:0] io_trigger_mode_alt_en;
  logic [link_channels_p-1:0] io_infinite_credits_en;

  logic [link_channels_p-1:0] io_reset_vec_lo;

  logic [link_channels_p-1:0] core_loopback_en;
  logic core_channel_reset_lo;

  // master

  if (master_p) begin : mstr

    localparam number_tests_lp=5;

    // wait a certain number of cycles after global reset to start
    // global calibration

    logic im_start_calibration_n, im_start_calibration_r;

    bsg_wait_after_reset #
      (.lg_wait_cycles_p(master_lg_wait_after_reset_p))
    bwar
      (.clk_i(io_master_clk_i)
      ,.reset_i(im_reset_lo)
      ,.ready_r_o(im_start_calibration_n));

    always_ff @(posedge io_master_clk_i)
      im_start_calibration_r <= im_start_calibration_n;

    // counter intuitive; organized by tests then by channel
    logic [link_channels_p-1:0] im_test_scoreboard [number_tests_lp+1-1:0];

    // + 1; for the "final test"
    logic [$clog2(number_tests_lp+1)-1:0] im_test_index;

    logic im_prepare_lo;

    bsg_source_sync_channel_control_master_master #
      (.link_channels_p(link_channels_p)
      ,.tests_p(number_tests_lp)
      ,.prepare_cycles_p(master_calib_prepare_cycles_p)
      ,.timeout_cycles_p(master_calib_timeout_cycles_p))
    master_master
      (.clk_i(io_master_clk_i)
      ,.reset_i(im_reset_lo)
      ,.start_i(~im_start_calibration_r & im_start_calibration_n)
      ,.test_scoreboard_i(im_test_scoreboard)
      ,.test_index_r_o(im_test_index)
      ,.prepare_o(im_prepare_lo)
      ,.done_o(im_calib_done_lo));

    // assert the tline

    always_ff @(posedge io_master_clk_i)
      im_slave_reset_tline_r <= im_prepare_lo;

    logic im_reset_r;

    always_ff @(posedge io_master_clk_i)
      im_reset_r <= im_reset_lo;

    // master im and core reset

    assign im_channel_reset_lo = im_prepare_lo;

    bsg_launch_sync_sync #
      (.width_p(1))
    bssi_reset
      (.iclk_i(io_master_clk_i)
      ,.iclk_reset_i(1'b0)
      ,.oclk_i(core_clk_i)
      ,.iclk_data_i(im_channel_reset_lo)
      ,.iclk_data_o()
      ,.oclk_data_o(core_channel_reset_lo));

    // create all of the input and output channels

    for (i=0; i < link_channels_p; i=i+1) begin: ch

      // io reset vector

      bsg_launch_sync_sync #
        (.width_p(1))
      io_reset_lss
        (.iclk_i(io_master_clk_i)
        ,.iclk_reset_i(1'b0)
        ,.oclk_i(io_clk_tline_i[i])
        ,.iclk_data_i(im_channel_reset_lo)
        ,.iclk_data_o()
        ,.oclk_data_o(io_reset_vec_lo[i]));

      logic [number_tests_lp+1-1:0] im_tests_gather;

      bsg_source_sync_channel_control_master #
        (.width_p(channel_width_p)
        ,.lg_token_width_p(master_lg_token_width_p)
        ,.lg_out_prepare_hold_cycles_p(master_lg_out_prepare_hold_cycles_p)
        ,.bypass_test_p(master_bypass_test_p)
        ,.tests_lp(number_tests_lp))
      control_master
        (.out_clk_i(io_master_clk_i)
        ,.out_reset_i(im_reset_lo)

        ,.out_calibration_state_i(im_test_index)
        ,.out_calib_prepare_i(im_prepare_lo)
        ,.out_channel_blessed_i(im_channel_active[i])

        ,.out_override_en_o(im_override_en[i])
        ,.out_override_valid_data_o(im_override_valid_data[i])
        ,.out_override_is_posedge_i(im_override_is_posedge[i])

        ,.out_test_pass_r_o(im_tests_gather)

        // AWC fixme: incorrect name should be output clocked, not in
        // clocked i.e. should be:
        // ,.out_infinite_credits_o (im_infinite_credits_en[i])
        ,.in_infinite_credits_o(io_infinite_credits_en[i])

        ,.in_clk_i(io_clk_tline_i[i])

        // reset synchronized to io_clk_tline_i
        ,.in_reset_i(io_reset_vec_lo[i])
        ,.in_snoop_valid_data_neg_i(io_snoop_valid_data_neg[i])
        ,.in_snoop_valid_data_pos_i(io_snoop_valid_data_pos[i]));

      for (j=0; j < number_tests_lp + 1; j=j+1) begin: mpa
        assign im_test_scoreboard[j][i] = im_tests_gather[j];
      end // block: mpa

      assign im_clk_init[i] = im_reset_lo & (~im_reset_r);

      // activate the channel if all of the "real" tests passed
      assign im_channel_active[i] = (& im_tests_gather[number_tests_lp-1:0]);

      assign io_trigger_mode_en[i] = 1'b0;
      assign io_trigger_mode_alt_en[i] = 1'b0;
      assign core_loopback_en[i] = 1'b0;

    end // block: ch

  end // block: mstr

  // slave
  else begin: slv

    // the slave is done calibrating if any of the channels are
    // active. since activation goes high only when im_reset_lo goes
    // low, all channels will all activate at the same time.
    //
    // no waiting for differences in channel clocks is necessary.
    assign im_calib_done_lo = (|im_channel_active);
    assign im_slave_reset_tline_r = 1'b0;

    // slaver im and core reset
    assign im_channel_reset_lo = im_reset_lo;
    assign core_channel_reset_lo = core_reset_lo;

    // create all of the input and output channels
    for (i=0; i < link_channels_p; i=i+1) begin: ch

      // no launch flop necessary here
      // and we synchronize directly from
      // the async reset for speed
      bsg_sync_sync #
        (.width_p(1))
      io_reset_ss
        (.oclk_i(io_clk_tline_i[i])
        ,.iclk_data_i(async_reset_i)
        ,.oclk_data_o(io_reset_vec_lo[i]));

      bsg_source_sync_channel_control_slave #
        (.width_p(channel_width_p)
        ,.lg_token_width_p(slave_lg_token_width_p))
      control_slave
        // for core control
        (.core_clk_i(core_clk_i)
        ,.core_loopback_en_o(core_loopback_en[i])

        ,.out_clk_i(io_master_clk_i)
        ,.out_reset_i(im_reset_lo)
        ,.out_clk_init_r_o(im_clk_init[i])
        ,.out_override_en_o(im_override_en[i])
        ,.out_override_valid_data_o(im_override_valid_data[i])

        // whether the channel is available for I/O assembler, post reset
        ,.out_channel_active_o(im_channel_active[i])

        // AWC fixme: incorrect name should be output clocked, not in
        // clocked i.e. should be:
        // ,.out_infinite_credits_o (im_infinite_credits_en[i])
        ,.in_infinite_credits_o(io_infinite_credits_en[i])

        // for input channel
        ,.in_clk_i(io_clk_tline_i[i])

        ,.in_snoop_valid_data_i(io_snoop_valid_data_pos[i])
        ,.in_trigger_mode_en_o(io_trigger_mode_en[i])
        ,.in_trigger_mode_alt_en_o(io_trigger_mode_alt_en[i]));

    end // block: ch

  end // block: slv

  // source sync output input

  logic [link_channels_p-1:0] io_calib_done;

  logic [link_channels_p-1:0] core_ssi_valid_lo;
  logic [channel_width_p-1:0] core_ssi_data_lo [link_channels_p-1:0];
  logic [link_channels_p-1:0] core_sso_ready_lo;

  // The token reset strategy for metastability is different,
  // because clocking the token clock increments a counter. Introducing
  // a synchronizer for the reset requires for us to control the token reset
  // precisely relative to the token clock, which cannot easily be done
  // from another clock domain.

  // Instead, we tie the token reset to the im reset, and avoid
  // metastability by requiring the master reset be asserted for many cycles
  // before going low.

  // During that reset period, we toggle the token clock to clear out state.
  // The token clock should only be toggled again (in normal use) a safe
  // number of cycles after reset goes low.

  logic token_reset_lo;

  assign token_reset_lo = im_channel_reset_lo;

  for (i=0; i < link_channels_p; i=i+1) begin: comm

    bsg_launch_sync_sync #
      (.width_p(1))
    blss_channel_active
      (.iclk_i(io_master_clk_i)
      ,.iclk_reset_i(im_reset_lo)
      ,.oclk_i(core_clk_i)
      ,.iclk_data_i(im_channel_active[i])
      ,.iclk_data_o()
      ,.oclk_data_o (core_active_channels_o[i]));

    bsg_source_sync_output #
      (.lg_start_credits_p(lg_input_fifo_depth_p)
      ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
      ,.channel_width_p(channel_width_p))
    sso
      // core clk and reset
      (.core_clk_i(core_clk_i)
      ,.core_reset_i(core_channel_reset_lo)

      // core in
      ,.core_valid_i(core_loopback_en[i]?
                     core_ssi_valid_lo[i]
                    :core_valid_i[i])
      ,.core_data_i(core_loopback_en[i]?
                    core_ssi_data_lo[i]
                   :core_data_i[i])
      // fixme: any special treatment required for loopback?
      ,.core_ready_o(core_sso_ready_lo[i])

      ,.io_master_clk_i(io_master_clk_i)
      ,.io_reset_i(im_channel_reset_lo)
      ,.io_clk_init_i(im_clk_init[i])

      ,.io_override_en_i(im_override_en[i])
      ,.io_override_valid_data_i(im_override_valid_data[i])
      ,.io_override_is_posedge_o(im_override_is_posedge[i])

      ,.io_clk_r_o(im_clk_tline_o[i])
      ,.io_data_r_o(im_data_tline_o[i])
      ,.io_valid_r_o(im_valid_tline_o[i])

      // AWC fixme: incorrect name should be output clocked, not in clocked
      // i.e. should be:
      // ,.io_infinite_credits_o (im_infinite_credits_en[i])
      ,.io_infinite_credits_i (io_infinite_credits_en[i])

      ,.token_clk_i(token_clk_tline_i[i])
      ,.token_reset_i(token_reset_lo));

    bsg_launch_sync_sync #
      (.width_p(1))
    im_to_io_calib_done
      (.iclk_i(io_master_clk_i)
      ,.iclk_reset_i(1'b0)
      ,.oclk_i(io_clk_tline_i[i])
      ,.iclk_data_i (im_calib_done_lo)
      ,.iclk_data_o()
      ,.oclk_data_o(io_calib_done[i]));

    bsg_source_sync_input #
      (.lg_fifo_depth_p(lg_input_fifo_depth_p)
      ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
      ,.channel_width_p(channel_width_p))
    ssi
      // starts on reset lo->hi xition
      (.io_clk_i(io_clk_tline_i[i])
      ,.io_data_i(io_data_tline_i[i])
      ,.io_valid_i(io_valid_tline_i[i])
      ,.io_token_r_o(io_token_clk_tline_o[i])

      // note a small quirk: for the master, we tie reset of the
      // input channel to the calibration being done rather
      // than the channel reset. this is because for the most
      // part the input channel is not used during calibration.

      // for the master, we keep this unit quiet until calibration is done
      // for the slave,  we need to use this unit, but we reset it for each
      // phase of calibration

      ,.io_reset_i(master_p? ~io_calib_done[i] : io_reset_vec_lo[i])

      // for both master and slave, prepare/reset mode enables token bypass
      // i.e.; we reset the token on every Phase.
      ,.io_token_bypass_i(io_reset_vec_lo[i])

      // latch on both edges; could change on the fly
      ,.io_edge_i(2'b11)

      // snoop input channel for establishing calib. state on reset
      ,.io_snoop_pos_r_o(io_snoop_valid_data_pos[i])
      ,.io_snoop_neg_r_o(io_snoop_valid_data_neg[i])

      // enable loop-back trigger mode
      ,.io_trigger_mode_en_i(io_trigger_mode_en[i])

      // enable loop-back trigger mode: alternate trigger
      ,.io_trigger_mode_alt_en_i(io_trigger_mode_alt_en[i])

      // core clk and reset
      ,.core_clk_i(core_clk_i)
      ,.core_reset_i(core_channel_reset_lo)

      // core out
      ,.core_valid_o(core_ssi_valid_lo[i])
      ,.core_data_o(core_ssi_data_lo[i])
      ,.core_yumi_i(core_loopback_en[i]?
                   (core_sso_ready_lo[i] & core_ssi_valid_lo[i])
                   :core_yumi_i[i]));

  end // block: comm

  // core out

  assign core_ready_o = core_sso_ready_lo;
  assign core_valid_o = core_ssi_valid_lo;
  assign core_data_o = core_ssi_data_lo;

endmodule
