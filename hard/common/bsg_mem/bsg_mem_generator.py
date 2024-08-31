#!/usr/bin/python
from __future__ import print_function

import argparse
import json
import os

bsg_mem_1r1w_sync_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_1r1w_sync_macros.svh"

  module bsg_mem_1r1w_sync
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter harden_p=1
      , parameter latch_last_read_p=0
      , parameter disable_collision_warning_p=0
      , parameter enable_clock_gating_p=0
    )
    (
      input clk_i
      , input reset_i

      , input w_v_i
      , input [addr_width_lp-1:0] w_addr_i
      , input [`BSG_SAFE_MINUS(width_p,1):0] w_data_i

      , input r_v_i
      , input [addr_width_lp-1:0] r_addr_i

      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r_data_o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_1r1w_sync_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync)
"""

bsg_mem_1r1w_sync_mask_write_bit_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_1r1w_sync_mask_write_bit_macros.svh"

  module bsg_mem_1r1w_sync_mask_write_bit
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter latch_last_read_p=0
      , parameter harden_p=1
      , parameter disable_collision_warning_p=0
      , parameter enable_clock_gating_p=0
    )
    (
      input clk_i
      , input reset_i

      , input w_v_i
      , input [`BSG_SAFE_MINUS(width_p,1):0] w_mask_i
      , input [addr_width_lp-1:0] w_addr_i
      , input [`BSG_SAFE_MINUS(width_p,1):0] w_data_i

      , input r_v_i
      , input [addr_width_lp-1:0] r_addr_i

      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r_data_o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_1r1w_sync_mask_write_bit_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync_mask_write_bit)
"""

bsg_mem_1r1w_sync_mask_write_byte_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_1r1w_sync_mask_write_byte_macros.svh"

  module bsg_mem_1r1w_sync_mask_write_byte
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter write_mask_width_lp=width_p>>3
      , parameter latch_last_read_p=0
      , parameter harden_p=1
      , parameter disable_collision_warning_p=0
      , parameter enable_clock_gating_p=0
    )
    (
      input clk_i
      , input reset_i

      , input w_v_i
      , input [`BSG_SAFE_MINUS(write_mask_width_lp,1):0] w_mask_i
      , input [addr_width_lp-1:0] w_addr_i
      , input [`BSG_SAFE_MINUS(width_p,1):0] w_data_i

      , input r_v_i
      , input [addr_width_lp-1:0] r_addr_i

      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r_data_o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_1r1w_sync_mask_write_byte_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_1r1w_sync_mask_write_byte)
"""

bsg_mem_1rw_sync_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_1rw_sync_macros.svh"

module bsg_mem_1rw_sync #(parameter `BSG_INV_PARAM(width_p)
                          , parameter `BSG_INV_PARAM(els_p)
                          , parameter latch_last_read_p=0
                          , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                          , parameter verbose_if_synth_p=0
                          , parameter enable_clock_gating_p=0
                          , parameter harden_p=1
                          )
   (input   clk_i
    , input reset_i
    , input [`BSG_SAFE_MINUS(width_p,1):0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input w_i
    , output logic [`BSG_SAFE_MINUS(width_p,1):0]  data_o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_1rw_sync_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

endmodule
"""

bsg_mem_1rw_sync_mask_write_bit_template = """

  `include "bsg_defines.sv"
  `include "bsg_mem_1rw_sync_mask_write_bit_macros.svh"

module bsg_mem_1rw_sync_mask_write_bit #(parameter `BSG_INV_PARAM(width_p)
                          , parameter `BSG_INV_PARAM(els_p)
                          , parameter latch_last_read_p=0
                          , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                          , parameter enable_clock_gating_p=0
                          , parameter harden_p=1
                          )
   (input   clk_i
    , input reset_i
    , input [`BSG_SAFE_MINUS(width_p,1):0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [`BSG_SAFE_MINUS(width_p,1):0] w_mask_i
    , input w_i
    , output logic [`BSG_SAFE_MINUS(width_p,1):0]  data_o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_1rw_sync_mask_write_bit_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

endmodule
"""

bsg_mem_1rw_sync_mask_write_byte_template = """

  `include "bsg_defines.sv"
  `include "bsg_mem_1rw_sync_mask_write_byte_macros.svh"

module bsg_mem_1rw_sync_mask_write_byte #(parameter `BSG_INV_PARAM(data_width_p)
                          , parameter `BSG_INV_PARAM(els_p)
                          , parameter latch_last_read_p=0
                          , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                          , parameter write_mask_width_lp=data_width_p>>3
                          , parameter enable_clock_gating_p=0
                          , parameter harden_p=1
                          )
   (input   clk_i
    , input reset_i
    , input [`BSG_SAFE_MINUS(data_width_p,1):0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input [`BSG_SAFE_MINUS(write_mask_width_lp,1):0] write_mask_i
    , input w_i
    , output logic [`BSG_SAFE_MINUS(data_width_p,1):0]  data_o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_1rw_sync_mask_write_byte_synth #(
        .data_width_p(data_width_p)
        ,.els_p(els_p)
        ,.latch_last_read_p(latch_last_read_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating data_width_p=%d, els_p=%d (%m)", data_width_p, els_p);
        end
`endif
endmodule
"""

bsg_mem_2r1w_sync_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_2r1w_sync_macros.svh"

  module bsg_mem_2r1w_sync
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter harden_p=1
      , parameter enable_clock_gating_p=0
    )
    (
      input clk_i
      , input reset_i

      , input w_v_i
      , input [addr_width_lp-1:0] w_addr_i
      , input [`BSG_SAFE_MINUS(width_p,1):0] w_data_i

      , input r0_v_i
      , input [addr_width_lp-1:0] r0_addr_i
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r0_data_o

      , input r1_v_i
      , input [addr_width_lp-1:0] r1_addr_i
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r1_data_o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_2r1w_sync_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_2r1w_sync)
"""

bsg_mem_2rw_sync_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_2rw_sync_macros.svh"

  module bsg_mem_2rw_sync
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter harden_p=1
      , parameter disable_collision_warning_p=0
      , parameter enable_clock_gating_p=0
    )
  ( input                      clk_i
  , input                      reset_i

  , input [`BSG_SAFE_MINUS(width_p,1):0] a_data_i
  , input [addr_width_lp-1:0]  a_addr_i
  , input                      a_v_i
  , input                      a_w_i

  , input [`BSG_SAFE_MINUS(width_p,1):0] b_data_i
  , input [addr_width_lp-1:0]  b_addr_i
  , input                      b_v_i
  , input                      b_w_i

  , output logic [`BSG_SAFE_MINUS(width_p,1):0] a_data_o
  , output logic [`BSG_SAFE_MINUS(width_p,1):0] b_data_o
  );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_2rw_sync_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync)
"""

bsg_mem_2rw_sync_mask_write_bit_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_2rw_sync_mask_write_bit_macros.svh"

  module bsg_mem_2rw_sync_mask_write_bit
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter harden_p=1
      , parameter disable_collision_warning_p=0
      , parameter enable_clock_gating_p=0
    )
  ( input                      clk_i
  , input                      reset_i

  , input [`BSG_SAFE_MINUS(width_p,1):0] a_data_i
  , input [`BSG_SAFE_MINUS(width_p,1):0] a_w_mask_i
  , input [addr_width_lp-1:0]  a_addr_i
  , input                      a_v_i
  , input                      a_w_i

  , input [`BSG_SAFE_MINUS(width_p,1):0] b_data_i
  , input [`BSG_SAFE_MINUS(width_p,1):0] b_w_mask_i
  , input [addr_width_lp-1:0]  b_addr_i
  , input                      b_v_i
  , input                      b_w_i

  , output logic [`BSG_SAFE_MINUS(width_p,1):0] a_data_o
  , output logic [`BSG_SAFE_MINUS(width_p,1):0] b_data_o
  );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_2rw_sync_mask_write_bit_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync_mask_write_bit)
"""

bsg_mem_2rw_sync_mask_write_byte_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_2rw_sync_mask_write_byte_macros.svh"

  module bsg_mem_2rw_sync_mask_write_byte
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter write_mask_width_lp=width_p>>3
      , parameter harden_p=1
      , parameter disable_collision_warning_p=0
      , parameter enable_clock_gating_p=0
    )
  ( input                      clk_i
  , input                      reset_i

  , input [`BSG_SAFE_MINUS(width_p,1):0] a_data_i
  , input [`BSG_SAFE_MINUS(write_mask_width_lp,1):0] a_w_mask_i
  , input [addr_width_lp-1:0]  a_addr_i
  , input                      a_v_i
  , input                      a_w_i

  , input [`BSG_SAFE_MINUS(width_p,1):0] b_data_i
  , input [`BSG_SAFE_MINUS(write_mask_width_lp,1):0] b_w_mask_i
  , input [addr_width_lp-1:0]  b_addr_i
  , input                      b_v_i
  , input                      b_w_i

  , output logic [`BSG_SAFE_MINUS(width_p,1):0] a_data_o
  , output logic [`BSG_SAFE_MINUS(width_p,1):0] b_data_o
  );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_2rw_sync_mask_write_byte_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync_mask_write_byte)
"""

bsg_mem_3r1w_sync_template = """
  `include "bsg_defines.sv"
  `include "bsg_mem_3r1w_sync_macros.svh"

  module bsg_mem_3r1w_sync
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter harden_p=1
      , parameter enable_clock_gating_p=0
    )
    (
      input clk_i
      , input reset_i

      , input w_v_i
      , input [addr_width_lp-1:0] w_addr_i
      , input [`BSG_SAFE_MINUS(width_p,1):0] w_data_i

      , input r0_v_i
      , input [addr_width_lp-1:0] r0_addr_i
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r0_data_o

      , input r1_v_i
      , input [addr_width_lp-1:0] r1_addr_i
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r1_data_o

      , input r2_v_i
      , input [addr_width_lp-1:0] r2_addr_i
      , output logic [`BSG_SAFE_MINUS(width_p,1):0] r2_data_o
    );

`ifndef BSG_HIDE_FROM_SYNTHESIS
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
`endif

    if (0) begin end else
    // Hardened macro selections
    {sram_cfg}
      begin: notmacro
      bsg_mem_3r1w_sync_synth #(
        .width_p(width_p)
        ,.els_p(els_p)
        ,.read_write_same_addr_p(read_write_same_addr_p)
      ) synth (.*);
    end

`ifndef BSG_HIDE_FROM_SYNTHESIS
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
`endif

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_3r1w_sync)
"""


def print_ram(
    memgen_json,
    ports,
    mask,
    read_write_same_addr_en,
    enable_clock_gating_en,
    disable_collision_warning_en,
    latch_last_read_en,
):
    fid = open(memgen_json, "r")
    memgen_json = json.load(fid)
    fid.close()

    memgen_defaults = {
        # Necessary
        "ports": "xrxw",
        "type": "xrf",
        "width": -1,
        "depth": -1,
        # Defaults
        "mask": 0,
        "adbanks": 1,
        "awbanks": 1,
        "mux": "",
        "seg": "",
        "tag": "",
    }

    if int(mask) == 0:
        maskstr = ""
    elif int(mask) == 1:
        maskstr = "_mask_write_bit"
    elif int(mask) == 8:
        maskstr = "_mask_write_byte"

    template = globals()[
        "bsg_mem_{ports}_sync{maskstr}_template".format(ports=ports, maskstr=maskstr)
    ]

    memgen_cfg = ""
    for m in memgen_json["memories"]:
        c = memgen_defaults.copy()
        c.update(m)

        if c["ports"] != ports:
            continue

        # Default tag is m<mux><seg> e.g. m2s, m2f
        if c["tag"] == "":
            if c["mux"] != "":
                c["tag"] += "m{mux}".format(mux=c["mux"])
            if c["seg"] != "":
                c["tag"] += "s{seg}".format(seg=c["seg"])

        if int(c["adbanks"]) != 1 or int(c["awbanks"]) != 1:
            memgen_cfg += "\t`bsg_mem_{ports}_sync{maskstr}_banked_macro({depth},{width},{awbanks},{adbanks}) else\n".format(
                ports=ports,
                maskstr=maskstr,
                depth=c["depth"],
                width=c["width"],
                awbanks=c["awbanks"],
                adbanks=c["adbanks"],
            )

        memgen_cfg += "\t`bsg_mem_{ports}_sync{maskstr}_{_type}_macro({depth},{width},{tag}) else\n".format(
            ports=ports,
            maskstr=maskstr,
            depth=c["depth"] // c["adbanks"],
            width=c["width"] // c["awbanks"],
            tag=c["tag"],
            _type=c["type"],
        )

    print(
        template.format(
            sram_cfg=memgen_cfg,
            read_write_same_addr_en=read_write_same_addr_en,
            enable_clock_gating_en=enable_clock_gating_en,
            disable_collision_warning_en=disable_collision_warning_en,
            latch_last_read_en=latch_last_read_en,
        )
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("memgen_json", help="The memgen.json file to parse")
    parser.add_argument("ports", help="The xryw port configuration for the SRAM")
    parser.add_argument("mask", help="The SRAM mask")
    parser.add_argument(
        "--read_write_same_addr_en",
        action="store_true",
        help="Whether to enable read_write_same_addr_p",
    )
    parser.add_argument(
        "--enable_clock_gating_en",
        action="store_true",
        help="Whether to enable enable_clock_gating_p",
    )
    parser.add_argument(
        "--disable_collision_warning_en",
        action="store_true",
        help="Whether to enable disable_collision_warning_p",
    )
    parser.add_argument(
        "--latch_last_read_en",
        action="store_false",
        help="Whether to enable latch_last_read_p",
    )
    args = parser.parse_args()
    read_write_same_addr_en = "(1'b1)" if args.read_write_same_addr_en else "(1'b0)"
    enable_clock_gating_en = "(1'b1)" if args.enable_clock_gating_en else "(1'b0)"
    disable_collision_warning_en = "(1'b1)" if args.disable_collision_warning_en else "(1'b0)"
    latch_last_read_en = "(1'b1)" if args.latch_last_read_en else "(1'b0)"

    print_ram(
        args.memgen_json,
        args.ports,
        args.mask,
        read_write_same_addr_en,
        enable_clock_gating_en,
        disable_collision_warning_en,
        latch_last_read_en,
    )
