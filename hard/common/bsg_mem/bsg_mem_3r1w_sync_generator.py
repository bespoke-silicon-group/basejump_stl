#!/usr/bin/python
from __future__ import print_function

import argparse
import json


def print_ram(
    memgen_cfg,
    read_write_same_addr_en,
    enable_clock_gating_en,
):
    print(
        """
  `include "bsg_mem_3r1w_sync_macros.vh"

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

    // synopsys translate_off
    initial begin
      if (read_write_same_addr_p && !{read_write_same_addr_en})
        $error("BSG ERROR: read_write_same_addr_p is set but unsupported");
      if (enable_clock_gating_p && !{enable_clock_gating_en})
        $error("BSG ERROR: enable_clock_gating_p is set but unsupported");
    end
    // synopsys translate_on

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

    //synopsys translate_off
      initial
        begin
           $display("## %L: instantiating width_p=%d, els_p=%d (%m)", width_p, els_p);
        end
    //synopsys translate_on

  endmodule

  `BSG_ABSTRACT_MODULE(bsg_mem_3r1w_sync)
  """.format(
            sram_cfg=memgen_cfg,
            read_write_same_addr_en=0,
            enable_clock_gating_en=0,
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

    memgen_cfg = ""
    for m in memgen_json["memories"]:
        c = memgen_defaults.copy()
        c.update(m)
        if c["ports"] != "3r1w":
            continue
        if c["type"] != "2rf":
            print("Only 2rf composition is supported")
            exit()
        if c["adbanks"] != 1 or c["awbanks"] != 1:
            print("Banking is not currently supported for 3r1w");
            exit()
        memgen_cfg += "\t`bsg_mem_3r1w_sync_{_type}_macro({depth},{width},{mux}) else\n".format(
            depth=c["depth"] / c["adbanks"],
            width=c["width"] / c["awbanks"],
            mux=c["mux"],
            _type=c["type"],
        )

    return memgen_cfg


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
    args = parser.parse_args()

    memgen_cfg = create_cfg(args.memgen_json)
    print_ram(
        memgen_cfg,
        args.read_write_same_addr_en,
        args.enable_clock_gating_en,
    )
