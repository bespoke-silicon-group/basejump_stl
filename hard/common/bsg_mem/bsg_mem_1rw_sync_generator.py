#!/usr/bin/python
from __future__ import print_function

import argparse
import json


nomask_template = """
  `include "bsg_mem_1rw_sync_macros.vh"

`include "bsg_defines.v"

module bsg_mem_1rw_sync #(parameter `BSG_INV_PARAM(width_p)
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
    , input w_i
    , output logic [`BSG_SAFE_MINUS(width_p,1):0]  data_o
    );

    // synopsys translate_off
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
    // synopsys translate_on

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

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
    //synopsys translate_on

endmodule
        """

bitmask_template = """
  `include "bsg_mem_1rw_sync_mask_write_bit_macros.vh"

`include "bsg_defines.v"

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

    // synopsys translate_off
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
    // synopsys translate_on

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

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
    //synopsys translate_on

endmodule
        """

bytemask_template = """
  `include "bsg_mem_1rw_sync_mask_write_byte_macros.vh"

`include "bsg_defines.v"

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

    // synopsys translate_off
    initial begin
      if (latch_last_read_p && !{latch_last_read_en})
        $error("BSG ERROR: latch_last_read_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
    // synopsys translate_on

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

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating data_width_p=%d, els_p=%d (%m)", data_width_p, els_p);
        end
    //synopsys translate_on
endmodule
        """


def print_ram(
    template, memgen_cfg, latch_last_read_en, enable_clock_gating_en,
):
    print(
        template.format(
            sram_cfg=memgen_cfg, latch_last_read_en=0, enable_clock_gating_en=0,
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
        maskstr = ""
    elif c["mask"] == 1:
        template = bitmask_template
        maskstr = "_mask_write_bit"
    elif c["mask"] == 8:
        template = bytemask_template
        maskstr = "_mask_write_byte"

    memgen_cfg = ""
    for m in memgen_json["memories"]:
        c = memgen_defaults.copy()
        c.update(m)
        if c["ports"] != "1rw":
            continue
        if c["adbanks"] != 1 or c["awbanks"] != 1:
            memgen_cfg += "\t`bsg_mem_{ports}{maskstr}_sync_banked_macro({depth},{width},{awbanks},{adbanks}) else\n".format(
                ports=c["ports"],
                maskstr=maskstr,
                depth=c["depth"],
                width=c["width"],
                awbanks=c["awbanks"],
                adbanks=c["adbanks"],
            )
        memgen_cfg += "\t`bsg_mem_{ports}_sync{maskstr}_{_type}_macro({depth},{width},{mux}) else\n".format(
            ports=c["ports"],
            maskstr=maskstr,
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
        "--latch_last_read_en",
        action="store_true",
        help="Whether to enable latch_last_read_p",
    )
    parser.add_argument(
        "--enable_clock_gating_en",
        action="store_true",
        help="Whether to enable enable_clock_gating_p",
    )
    args = parser.parse_args()

    template, memgen_cfg = create_cfg(args.memgen_json)
    print_ram(
        template, memgen_cfg, args.latch_last_read_en, args.enable_clock_gating_en,
    )
