
package bsg_link_pkg;

  import bsg_tag_pkg::*;

  typedef struct packed
  {
    bsg_tag_s sdr_disable;
    bsg_tag_s uplink_reset;
    bsg_tag_s downlink_reset;
    bsg_tag_s downstream_reset;
    bsg_tag_s token_reset;
  }  bsg_link_sdr_tag_lines_s;
  localparam bsg_link_sdr_tag_local_els_gp =
	$bits(bsg_link_sdr_tag_lines_s) / $bits(bsg_tag_s);

endpackage

