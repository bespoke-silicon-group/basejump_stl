#!/usr/bin/python
from __future__ import print_function

import argparse
import json

nomask_template = """
  `include "bsg_mem_2rw_sync_macros.vh"

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

    // synopsys translate_off
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
    // synopsys translate_on

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

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
    //synopsys translate_on

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync)
"""

bitmask_template = """
  `include "bsg_mem_2rw_sync_mask_write_bit_macros.vh"

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

    // synopsys translate_off
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
    // synopsys translate_on

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

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
    //synopsys translate_on

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync_mask_write_bit)
"""

bytemask_template = """
  `include "bsg_mem_2rw_sync_mask_write_byte_macros.vh"

  module bsg_mem_2rw_sync_mask_write_byte
    #(parameter `BSG_INV_PARAM(width_p)
      , parameter `BSG_INV_PARAM(els_p)
      , parameter read_write_same_addr_p=0
      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
      , parameter write_mask_width_lp=data_width_p>>3
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

    // synopsys translate_off
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
      if (disable_collision_warning_p && !{disable_collision_warning_en})
        $warning("BSG ERROR: disable_collision_warning_p is set but unsupported");
    end
    // synopsys translate_on

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

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
    //synopsys translate_on

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_2rw_sync_mask_write_byte)
"""

def print_ram(
    template,
    memgen_cfg,
    read_write_same_addr_en,
    enable_clock_gating_en,
    disable_collision_warning_en,
):
    print(template.format(
            sram_cfg=memgen_cfg,
            read_write_same_addr_en=0,
            enable_clock_gating_en=0,
            disable_collision_warning_en=0,
        )
    )


def create_cfg(memgen_json):
    fid = open(memgen_json, "r")
    memgen_json = json.load(fid)
    fid.close()

    memgen_defaults = {
        # Necessary
        "ports": "xrxw",
        "type": "xrf",
        "width": -1,
        "depth": -1,
        "mux": -1,
        # Defaults
        "mask": 0,
        "adbanks": 1,
        "awbanks": 1,
    }

    if c["mask"] == 0:
        template = nomask_template
        c["maskstr"] = ""
    elif c["mask"] == 1:
        template = bitmask_template
        c["maskstr"] = "_mask_write_bit"
    elif c["mask"] == 8:
        template = bytemask_template
        c["maskstr"] = "_mask_write_byte"

    memgen_cfg = ""
    for m in memgen_json["memories"]:
        c = memgen_defaults.copy()
        c.update(m)
        if c["ports"] != "2rw":
            continue
        if c["adbanks"] != 1 or c["awbanks"] != 1:
            print("Banking is not currently supported for 2rw");
            exit()
        memgen_cfg += "\t`bsg_mem_{ports}_sync{maskstr}_{_type}_macro({depth},{width},{mux}) else\n".format(
            ports=c["ports"],
            maskstr=c["maskstr"],
            depth=c["depth"] / c["adbanks"],
            width=c["width"] / c["awbanks"],
            mux=c["mux"],
            _type=c["type"],
        )

    return template, memgen_cfg


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("memgen_json", help="The memgen.json file to parse")
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
    args = parser.parse_args()

    template, memgen_cfg = create_cfg(args.memgen_json)
    print_ram(
        template,
        memgen_cfg,
        args.read_write_same_addr_en,
        args.enable_clock_gating_en,
        args.disable_collision_warning_en,
    )
