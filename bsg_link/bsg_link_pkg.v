
// 
// This package is intended as a convenience for bringing up a chip with a bsg_link using bsg_tag.
//
// To bring up a chip with bsg_links, a specific reset sequence must be followed (see here:
//   https://github.com/bespoke-silicon-group/basejump_stl/blob/master/bsg_link/bsg_link_sdr.sv). In
//   the BSG methodology, we use bsg_tag (https://github.com/bespoke-silicon-group/blob/master/bsg_tag):
//   a system-synchronous, decentralized broadcast configuration network. A bsg_tag_master_decentralized
//   will snoop on tag lines corresponding to reset signals of the SDR links. Each of these tag lines will
//   then feed into a bsg_tag_client, triggering the reset sequence. The structs in this package collect
//   these tag lines to eliminate confusion over offsets, making it easier to reuse system bringup components.
//
package bsg_link_pkg;

  import bsg_tag_pkg::*;

  typedef struct packed
  {
    bsg_tag_s sdr_disable;
    bsg_tag_s uplink_reset;
    bsg_tag_s downlink_reset;
    bsg_tag_s downstream_reset;
    bsg_tag_s token_reset;
  }  bsg_link_sdr_w_disable_tag_lines_s;
  localparam bsg_link_sdr_w_disable_tag_local_els_gp =
	$bits(bsg_link_sdr_w_disable_tag_lines_s) / $bits(bsg_tag_s);

  typedef struct packed
  {
    bsg_tag_s uplink_reset;
    bsg_tag_s downlink_reset;
    bsg_tag_s downstream_reset;
    bsg_tag_s token_reset;
  }  bsg_link_sdr_tag_lines_s;
  localparam bsg_link_sdr_tag_local_els_gp =
	$bits(bsg_link_sdr_tag_lines_s) / $bits(bsg_tag_s);

endpackage

