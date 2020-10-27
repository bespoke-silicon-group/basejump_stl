`include "bsg_defines.v"

`ifndef CONFIG_DEFS_V

`define CONFIG_DEFS_V

typedef struct packed {
  logic cfg_clk;
  logic cfg_bit;
} config_s;

/* ========================================================================== *
 * WARNING: Please do not modify the following hard-coded localparams unless
 *          you are clear about the possible consequences.
 *
 *   frame_bit_size_lp is set to 1 and the current framing bit is defined as
 *   a single '0'.
 *
 *   data_frame_len_lp has to be less than the reset_len_lp, so that when
 *   bits are shifted in, the content of a data frame never gets interpreted
 *   as a reset sequence.
 *
 *   Since id bits and len bits are not framed in this implementation,
 *   id_width_lp and len_width_lp also should be less than reset_len_lp.
 * ========================================================================== */
// local parameters same for all nodes in the configuration network
localparam valid_bit_size_lp  =  2;
localparam frame_bit_size_lp  =  1;
localparam data_frame_len_lp  =  8;  // bit '0' is inserted every data_frame_len_lp in data bits
localparam id_width_lp        =  5;  // number of bits to represent the ID of a node, should be able to keep the max ID in the whole chain
localparam len_width_lp       =  5;  // number of bits to represent number of bits in the configuration packet ==> this can be reduced to $clog2(data_max_bits_lp)
localparam reset_len_lp       = 10;  // reset sequence length

localparam data_max_bits_lp   = 15;  // maximum number of allowed configurable bits in a single config_node
                                     // the value should match the main processor's data width for efficient communication

localparam id_tag_bits_lp     =  8;  // a pseudo random tag for the snooper node
                                     // feedback formula config_snooper needs change if this length changed

`endif
