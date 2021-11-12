#!/usr/bin/python
from __future__ import print_function

import argparse
import json


def print_hard(cfg,):
    print(
        """
  module bsg_mem_{ports}_sync{maskstr}_w{width_p}_d{depth_p}_m{tag_p}_hard;
      bsg_mem_{ports}_sync{maskstr}_synth #(
        .width_p({width_p})
        ,.els_p({depth_p})
      ) func (.*);
  endmodule
  
  """.format(
            ports=cfg["ports"],
            maskstr=cfg["maskstr"],
            width_p=cfg["width"] / cfg["awbanks"],
            depth_p=cfg["depth"] / cfg["adbanks"],
            tag_p=cfg["tag"],
        )
    )


def create_rams(memgen_json):
    fid = open(memgen_json, "r")
    memgen_json = json.load(fid)
    fid.close()

    memgen_defaults = {
        # Necessary
        "ports": "xrxw",
        "type": "xrf",
        "width": -1,
        "depth": -1,
        "tag": -1,
        # Defaults
        "mask": 0,
        "adbanks": 1,
        "awbanks": 1,
    }

    memgen_cfg = ""
    for m in memgen_json["memories"]:
        c = memgen_defaults.copy()
        c.update(m)
        if c["mask"] == 8:
            c["maskstr"] = "_mask_write_byte"
        elif c["mask"] == 1:
            c["maskstr"] = "_mask_write_bit"
        else:
            c["maskstr"] = ""
        print_hard(c)

    return memgen_cfg


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("memgen_json", help="The memgen.json file to parse")
    args = parser.parse_args()

    create_rams(args.memgen_json)
