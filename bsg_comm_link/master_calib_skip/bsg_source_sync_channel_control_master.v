// MBT 5/1/2017 Fast simulation mastercalibration module
//
// FPGA calibration module (example, only implements Phase 1 and dummy Phase 0,2,3)
//
// See BSG Source Synchronous I/O for specification of this.
//
// everything beginning with "out" is the output channel clock
// everything beginning with "in"  is the input  channel clock
//
// respect the clock domains!
//
// tests_lp defines the number of real tests; but we have one more "fake"
// test at the end, which causes activation or deactivation of the channel
//
//

`include "bsg_defines.v"

module  bsg_source_sync_channel_control_master #(parameter   width_p  = -1
                                                 , parameter lg_token_width_p = 6
                                                 , parameter lg_out_prepare_hold_cycles_p = 6
                                                 // bit vector
                                                 , parameter bypass_test_p = 5'b0
                                                 , parameter tests_lp = 5
                                                 , parameter verbose_lp = 1
                                                 )
   (// output channel
    input  out_clk_i
    , input  out_reset_i // note this is just a synchronized version of core_reset

    // we can do calibration in parallel, or channel-by-channel
    , input [$clog2(tests_lp+1)-1:0]  out_calibration_state_i

    , input                      out_calib_prepare_i // essentially the reset signal

    // ignore, we assume all channels are blessed
    , input                      out_channel_blessed_i

    // this is used to force data on to the output channel
    // (calibration modes 0 and 1)

    , output                 out_override_en_o
    , output [width_p+1-1:0] out_override_valid_data_o

    // ignore
    , input                  out_override_is_posedge_i

    // whether the test passed
    , output [tests_lp+1-1:0] out_test_pass_r_o

    // ignore
    , input  in_clk_i
    , input  in_reset_i

    // ignore
    , input  [width_p+1-1:0] in_snoop_valid_data_neg_i

    // ignore
    , input  [width_p+1-1:0] in_snoop_valid_data_pos_i

    // hardwired to zero
    , output                 out_infinite_credits_o

    );

   assign out_infinite_credits_o = 1'b0;

   // memory mapped registers

   logic [width_p+1-1:0]          valid_data_r;        // 0
   logic                          override_r;          // 1
   logic [tests_lp+1-1:0]         out_test_pass_r;     // 2
   logic [$clog2(tests_lp+1):0]   match_reg_r;         // 3

   assign out_override_valid_data_o = valid_data_r;
   assign out_override_en_o         = override_r;
   assign out_test_pass_r_o         = out_test_pass_r;

   //
   // opcode4 <addr2>, <data14>
   //

   wire                   v_lo, v_li;
   wire [15:0]            data_lo, data_li;
   wire            yumi_li;


   localparam match_size_lp = $clog2(tests_lp+1)+1;

   // handle opcode4 -> send
   // we convert this into a memory mapped write

   always_ff @(posedge out_clk_i)
     if (out_reset_i)
       begin
          valid_data_r    <= 0;
          override_r      <= 0;
          out_test_pass_r <= 0;
          match_reg_r     <= 0;
       end
     else
       begin
          if (v_lo)
            begin
               if (data_lo[15:14] == 0)
                 valid_data_r <= data_lo[0+:width_p+1];
               else
                 if (data_lo[15:14] == 1)
                   override_r <= data_lo[0];
                 else
                   if (data_lo[15:14] == 2)
                     out_test_pass_r <= data_lo[0+:tests_lp+1];
                   else
                     if (data_lo[15:14] == 3)
                       match_reg_r <= data_lo[0+:$clog2(tests_lp+1)+1];
            end
       end // else: !if(out_reset_i)

   assign yumi_li = v_lo;

   // handle opcode -> receive

   assign data_li  = 16'b0;
   assign v_li     = (match_reg_r == {out_calib_prepare_i, out_calibration_state_i});

   localparam rom_addr_width_lp = 6;

   wire [rom_addr_width_lp-1:0] rom_addr_li;
   wire [4+16-1:0] rom_data_lo;

   bsg_fsb_node_trace_replay
     #(.ring_width_p(16)
       ,.rom_addr_width_p(rom_addr_width_lp)
       ) tr
       (.clk_i(out_clk_i)
        ,.reset_i(out_reset_i)
        ,.en_i(1'b1)

        ,.v_i    (v_li)
        ,.data_i (data_li)
        ,.ready_o() // ignored

        ,.v_o    (v_lo)
        ,.data_o (data_lo)
        ,.yumi_i (yumi_li)

        ,.rom_addr_o(rom_addr_li)
        ,.rom_data_i(rom_data_lo)

        ,.done_o() // cheeky mapping to done signal
        ,.error_o()
        );

   // generated with bsg_fsb_master_rom
   bsg_comm_link_master_calib_skip_rom
     #(.width_p(4+16)
       ,.addr_width_p(rom_addr_width_lp)
       ) comm_link_master_rom
       (.addr_i(rom_addr_li)
        ,.data_o(rom_data_lo)
        );

endmodule
