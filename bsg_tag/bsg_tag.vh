// bsg_tag
//
// bsg_tag implements a serial configuration network. 
//
// the abstraction is that you have a number of multibit registers inside your chip that
// you would like to configure, either before the
// chip boots, or even as the chip runs. bsg_tag correctly handles
// clock domain crossings, so multibit registers will be updated atomically, allowing on-the-fly
// configuration changes. however, for this to happen, both the tag clock and the destination
// clock must be active, and enough clock cycles must pass on both sides for the data to be absorbed.
//
// bsg_tag enables this capability using only three
// external pins on the chip -- one for a clock, one for data, and one for a failsafe enable.
//
// each multibit register has a nodeID, and a customized length, and is implemented with a bsg_tag_client
//
// when you stream data into the chip, a single bsg_tag_master module demultiplexes the incoming packets 
// according to nodeID out to the bsg_tag_client nodes. each client has a 4-wire connection to the master
// -- the shared tag clock, the failsafe enable, and a two-bit opcode. the opcode encodes 4 operations:
// shift in 1, shift in 0, reset, and noop. A noop immediately following a shift indicates that the 
// transfer is done and should be sent across the CDC.
//
// - to reset the bsg_tag_master node, a stream of 0's is sent. 
// - to reset the client, you
//   transmit a 1, then the nodeID, a 0, then a length, and then length ' 1 bits.
// - to transmit data to a client, you 
//   transmit a 1, then the nodeID, a 1, then the length, then the data.
// - to not send data, transmit 0's.
//
// the enable signal is an out-of-band signal. if enable is low, then all of the bsg_tag_clients
// are disconnected from the masters. it should not be asserted / deasserted 
// when trying to send data at the same time. 
//
// when using bsg_tag to program the clock generators, the enable signal must be low
// initially because the clock generators must already be running in order to absorb data
// from the bsg_tag and be programmed. =)
//
// see bsg_ip_cores/testing/bsg_clk_gen/bsg_nonsynth_clk_gen_tester.v for an example usage
//
// the bsg_tag clock should be asserted 180 degrees out of phase with the data/en signals, to
// avoid setup/hold time violations. i.e. use negedge clock.
//

`ifndef BSG_TAG_VH
`define BSG_TAG_VH

`define declare_bsg_tag_header_s(PARAM_els,PARAM_lg_width)                  \
                                                                            \
   typedef struct packed {                                                  \
      logic [`BSG_SAFE_CLOG2((PARAM_els))-1:0]       nodeID;                \
      logic                                          data_not_reset;        \
      logic [(PARAM_lg_width)-1:0] len;                                     \
      } bsg_tag_header_s;

`define bsg_tag_max_packet_len(PARAM_els,PARAM_lg_width) ((1 << (PARAM_lg_width)) - 1 + $bits(bsg_tag_header_s))
`define bsg_tag_reset_len(PARAM_els,PARAM_lg_width) ((1 << `BSG_SAFE_CLOG2(`bsg_tag_max_packet_len((PARAM_els),(PARAM_lg_width))+1))+1)


`endif //  `ifndef BSG_TAG_VH
