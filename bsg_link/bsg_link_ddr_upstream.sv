//
// Paul Gao 03/2019
//
// This is the sender part of bsg_link_ddr, a complete DDR communication 
// endpoint over multiple source-synchronous channels.
//
// * This module MUST be mirrored with bsg_link_ddr_downstream, which is
//   instantiated on the destination chip or FPGA. It is not a must to
//   use upstream and downstream in pair on same chip or FPGA.
// 
// The purpose of bsg_link_ddr_upstream is to receive data packets from ready-valid
// interface in core clock domain, serialize them to fit in IO channels (optional),
// then send out through physical IO pins.
// Token-credit based flow control ensures efficiency and correctness.
// ODDR PHY sends out packets with center-aligned DDR clock.
//
// Typical usage: ASIC <-> ASIC communication and ASIC <-> FPGA communication.
// Instantiate one bsg_link_ddr_upstream on sender side, one bsg_link_ddr_downstream on
// receiver side to establish communication.
// 
// Refer to bsg_link_source_sync_upstream for more information on flow control
//
// Reset procedures:
// Step 1: Assert io_link_reset_i and core_link_reset_i.
// Step 2: async_token_reset_i must be posedge/negedge toggled (0->1->0) 
//         at least once. token_clk_i cannot toggle during this step.
// Step 3: io_clk_i posedge toggled at least four times after that.
// Step 4: Deassert io_link_reset_i. 
// Step 5: Deassert core_link_reset_i. 
//

`include "bsg_defines.sv"

module bsg_link_ddr_upstream

 #(// Core data width
  // MUST be multiple of (2*channel_width_p*num_channels_p) 
  // When use_extra_data_bit_p=1, must be multiple of ((2*channel_width_p+1)*num_channels_p) 
   parameter `BSG_INV_PARAM(width_p         )
  // Number of IO pins per physical IO channels
  ,parameter channel_width_p = 8
  // Number of physical IO channels
  ,parameter num_channels_p  = 1
  // Receive fifo depth 
  // MUST MATCH paired bsg_link_ddr_downstream setting
  // Default value comes from child module
  // Refer to bsg_link_source_sync_downstream for more detail on this parameter
  ,parameter lg_fifo_depth_p = 6
  // Token credit decimation
  // MUST MATCH paired bsg_link_ddr_downstream setting
  // Default value comes from child module
  // Refer to bsg_link_source_sync_downstream for more detail on this parameter
  ,parameter lg_credit_to_token_decimation_p = 3
  // There are (channel_width_p+1) physical wires available (1 wire for valid bit)
  // With DDR clock, we can handle 2*channel_width_p+2 bits each cycle
  // By default the link has 2*channel_width_p data bits and 1 valid bit, 1 bit is unused
  // Set use_extra_data_bit_p=1 to utilize this extra bit
  // MUST MATCH paired bsg_link_ddr_downstream setting
  ,parameter use_extra_data_bit_p = 0
  // When channel_width_p is large, it might be hard to properly align source synchronous
  // clock to all data wires. One option is to cut the channel in half and align to
  // different clocks. Ecoding method below helps represent valid bit for bottom half data
  // without adding an extra wire.
  // +-------------+---------------+---------------------+
  // |    v_top    |     bottom    |        Value        |
  // | 0_0???_???? |   0000_0000   | no data (""comma"") |
  // | 1_XXXX_XXXX |  YYYY_YYYY!=0 | XXXX_XXXX_YYYY_YYYY |
  // | 0_1XXX_XXXX |   X000_0001   | XXXX_XXXX_0000_0000 |
  // +-------------+---------------+---------------------+
  // Physical bonding suggestion: Regard v bit and top bits of the channel as a group
  // Regard bottom bits of the channel as another group
  // Set use_encode_p=1 to enable this encoding feature
  // MUST MATCH paired bsg_link_ddr_downstream setting
  ,parameter use_encode_p = 0
  ,parameter bypass_twofer_fifo_p = 0
  ,parameter bypass_gearbox_p = 0
  ,localparam ddr_width_lp  = channel_width_p*2 + use_extra_data_bit_p
  ,localparam piso_ratio_lp = width_p/(ddr_width_lp*num_channels_p)
  ,localparam phy_width_lp  = channel_width_p+1
  )

  (// Core side
   input core_clk_i
  ,input core_link_reset_i

  ,input [width_p-1:0] core_data_i
  ,input               core_valid_i
  ,output              core_ready_o  
  
  // Physical IO side
  ,input io_clk_i
  ,input io_link_reset_i
  ,input async_token_reset_i
  
  ,output logic [num_channels_p-1:0]                      io_clk_r_o
  ,output logic [num_channels_p-1:0][channel_width_p-1:0] io_data_r_o
  ,output logic [num_channels_p-1:0]                      io_valid_r_o
  ,input        [num_channels_p-1:0]                      token_clk_i
  );
  
  
  logic core_piso_valid_lo, core_piso_yumi_li;
  logic [num_channels_p-1:0][ddr_width_lp-1:0] core_piso_data_lo;

  // Dequeue from PISO when all channels are ready
  logic [num_channels_p-1:0] core_piso_ready_li;

  if (piso_ratio_lp == 1 && bypass_gearbox_p != 0)
  begin
    assign core_piso_valid_lo = core_valid_i;
    assign core_piso_data_lo  = core_data_i;
    assign core_ready_o = (& core_piso_ready_li);
  end
  else
  begin: piso
    assign core_piso_yumi_li = (& core_piso_ready_li) & core_piso_valid_lo;
    bsg_parallel_in_serial_out
   #(.width_p(ddr_width_lp*num_channels_p)
    ,.els_p  (piso_ratio_lp)
    ) out_piso
    (.clk_i  (core_clk_i)
    ,.reset_i(core_link_reset_i)
    ,.valid_i(core_valid_i)
    ,.data_i (core_data_i)
    ,.ready_and_o(core_ready_o)
    ,.valid_o(core_piso_valid_lo)
    ,.data_o (core_piso_data_lo)
    ,.yumi_i (core_piso_yumi_li)
    );
  end
  
  genvar i;
  
  // multiple channels
  for (i = 0; i < num_channels_p; i++) 
  begin: ch

    // core side signals
    logic core_ss_valid_li, core_ss_ready_lo, core_ss_data_nonzero;
    logic [phy_width_lp-1:0] core_ss_data_top;
//    logic [1:0][channel_width_p/2-1:0] core_ss_data_bottom;
     logic [channel_width_p-1:0] core_ss_data_bottom;
     
    // io side signals
    logic io_oddr_valid_li, io_oddr_ready_lo;
    logic [1:0][phy_width_lp-1:0] io_oddr_data_raw, io_oddr_data_final;

    // connect to piso
    assign core_ss_valid_li = core_piso_valid_lo;
    assign core_piso_ready_li[i] = core_ss_ready_lo;
    assign core_ss_data_top = (phy_width_lp)'(core_piso_data_lo[i][ddr_width_lp-1:channel_width_p]);

    if (use_encode_p == 0)
      begin
        assign core_ss_data_nonzero = 1'b0; // unused
        assign core_ss_data_bottom = core_piso_data_lo[i][channel_width_p-1:0];
        // valid sent out in first cycle
        // When idle, balance hi / lo bits in each channel
        assign io_oddr_data_final = (io_oddr_valid_li)?
              {io_oddr_data_raw[1], 1'b1, io_oddr_data_raw[0][channel_width_p-1:0]}
            : {2{1'b0, {(channel_width_p/2){2'b10}}}};
      end
    else
      begin
        // core side encode
        assign core_ss_data_nonzero = ~(core_piso_data_lo[i][channel_width_p/2-1:0] == '0);
        assign core_ss_data_bottom[channel_width_p-1:channel_width_p/2] = (core_ss_data_nonzero)?
              {      core_piso_data_lo[i][channel_width_p-0-1:channel_width_p/2]}
            : {1'b1, core_piso_data_lo[i][channel_width_p-1-1:channel_width_p/2]};
        assign core_ss_data_bottom[channel_width_p/2-1:0] = (core_ss_data_nonzero)?
              {core_piso_data_lo[i][channel_width_p/2-1:0]                          }
            : {core_piso_data_lo[i][channel_width_p-1], (channel_width_p/2-1)'(1'b1)};
        // When idle, assign 1'b0 to certain wires to represent invalid state
        // Assign 1'b1 to rest of the wires to balance hi / lo bits in each channel
        assign io_oddr_data_final = (io_oddr_valid_li)?
              io_oddr_data_raw
            : {2{2'b00, (channel_width_p/2-1)'('1), (channel_width_p/2)'('0)}};
      end

    bsg_link_source_sync_upstream
   #(.channel_width_p(2*phy_width_lp)
    ,.lg_fifo_depth_p(lg_fifo_depth_p)
    ,.lg_credit_to_token_decimation_p(lg_credit_to_token_decimation_p)
    ,.bypass_twofer_fifo_p(bypass_twofer_fifo_p)
    ) sso
    (// control signals  
     .core_clk_i            (core_clk_i)
    ,.core_link_reset_i     (core_link_reset_i)    
    ,.io_clk_i              (io_clk_i)
    ,.io_link_reset_i       (io_link_reset_i)
    ,.async_token_reset_i   (async_token_reset_i)

    // Input from chip core
    ,.core_data_i           ({core_ss_data_top, core_ss_data_nonzero, core_ss_data_bottom})
    ,.core_valid_i          (core_ss_valid_li)
    ,.core_ready_o          (core_ss_ready_lo)

    // source synchronous output channel; going to chip edge
    ,.io_data_o             (io_oddr_data_raw)
    ,.io_valid_o            (io_oddr_valid_li)
    ,.io_ready_i            (io_oddr_ready_lo)
    ,.token_clk_i           (token_clk_i[i])
    );
    
    // valid and data signals are sent together
    bsg_link_oddr_phy
   #(.width_p(phy_width_lp)
    ) oddr_phy
    (.reset_i (io_link_reset_i)
    ,.clk_i   (io_clk_i)
    ,.data_i  (io_oddr_data_final)
    ,.ready_o (io_oddr_ready_lo)
    ,.data_r_o({io_valid_r_o[i], io_data_r_o[i]})
    ,.clk_r_o (io_clk_r_o[i])
    );
  
  end
  
`ifndef BSG_HIDE_FROM_SYNTHESIS
  initial 
  begin
    assert (piso_ratio_lp > 0)
    else 
      begin 
        $error("BaseJump STL ERROR %m: width_p should be larger than or equal to (ddr_width_lp*num_channels_p)");
        $finish;
      end
      
    assert (piso_ratio_lp*(ddr_width_lp*num_channels_p) == width_p)
    else 
      begin 
        $error("BaseJump STL ERROR %m: width_p should be multiple of (ddr_width_lp*num_channels_p)");
        $finish;
      end
  end
`endif

endmodule
`BSG_ABSTRACT_MODULE(bsg_link_ddr_upstream)
