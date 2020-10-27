// This module uses the synthesizable bsg_fsb_node_trace_replay module
// to communicate over bsg_tag. This module instantitates a trace-replay,
// removes the output data to match what bsg_tag is expecting, and
// finally it serializes the trace data down to a single bit.
//
// Each trace should be in the following format:
//
// M = number of masters
// N = clog2( #_of_tag_clients ) )
// D = max( client_1_width, client_2_width, ..., client_n_width )
// L = clog2( D + 1 ) )
//
// |<    4-bits    >|< M-bits >|< N-bits >|<     1-bit    >|< L-bits >|< D-bits >|
// +----------------+----------+----------+----------------+----------+----------+
// | replay command | masterEn |  nodeID  | data_not_reset |  length  |   data   |
// +----------------+----------+----------+----------------+----------+----------+
//
//  Replay Commands
//    0 = 0000 = Wait a cycle
//    1 = 0001 = Send data
//    2 = 0010 = Receive data
//    3 = 0011 = Assert done_o ouput signal
//    4 = 0100 = End test (calls $finish)
//    5 = 0101 = Wait for cycle_counter == 0
//    6 = 0110 = Initialize cycle_counter with a 16 bit number
//
// To reset the bsg_tag_master, we just need to send a bunch of 0's,
// so we can send a trace of all 0's and just wait for many cycles. This
// will continuously send 0's down bsg_tag thus reseting the master.
//
// To reset a client, set the nodeID, data_not_reset=0, and length
// fields correctly, then set the data to all 1's.
//

`include "bsg_defines.v"

module bsg_tag_trace_replay

   #( parameter rom_addr_width_p    = -1
    , parameter rom_data_width_p    = -1
    , parameter num_masters_p       = 0
    , parameter num_clients_p       = -1
    , parameter max_payload_width_p = -1 )

    ( input clk_i
    , input reset_i
    , input en_i
      
    , output [rom_addr_width_p-1:0] rom_addr_o
    , input  [rom_data_width_p-1:0] rom_data_i
      
    , input                            valid_i
    , input  [max_payload_width_p-1:0] data_i
    , output                           ready_o

    , output                                 valid_o
    , output [`BSG_MAX(1,num_masters_p)-1:0] en_r_o
    , output                                 tag_data_o
    , input                                  yumi_i

    , output done_o
    , output error_o
    ) ;

    `include "bsg_tag.vh"

    // The trace ring width is the size of the rom data width
    // minus the 4-bits for the trace-replay command.
    localparam trace_ring_width_lp = rom_data_width_p - 4;

    // The number of bits needed to represent the length of the
    // payload inside bsg_tag.
    localparam lg_max_payload_width_lp = `BSG_SAFE_CLOG2(max_payload_width_p + 1);

    // The number of bits in the header of the tag packet.
    `declare_bsg_tag_header_s(num_clients_p, lg_max_payload_width_lp);
    localparam bsg_tag_header_width_lp = $bits(bsg_tag_header_s);

    // Data signals between trace_replay and parallel_in_serial_out.
    logic                           tr_valid_lo;
    logic [trace_ring_width_lp-1:0] tr_data_lo;
    logic                           tr_yumi_li;

    // Instantiate the trace replay
    bsg_fsb_node_trace_replay #( .ring_width_p(trace_ring_width_lp)
                               , .rom_addr_width_p(rom_addr_width_p) )
      trace_replay
        (.clk_i   (clk_i)
        ,.reset_i (reset_i)
        ,.en_i    (en_i)

        /* input channel */
        ,.v_i     (valid_i)
        ,.data_i  (trace_ring_width_lp ' (data_i))
        ,.ready_o (ready_o)

        /* output channel */
        ,.v_o    (tr_valid_lo)
        ,.data_o (tr_data_lo)
        ,.yumi_i (tr_yumi_li)

        /* rom connections */
        ,.rom_addr_o (rom_addr_o)
        ,.rom_data_i (rom_data_i)

        /* signals */
        ,.done_o  (done_o)
        ,.error_o (error_o)
        );

    // Reform the data between the trace-replay and the piso
    // to properly act like a bsg_tag packet. This includes adding
    // a 1-bit to the beginning of the data and a 0-bit to the
    // end. Furthermore, swap the header and payload order.
    wire [bsg_tag_header_width_lp-1:0]   header_n  = tr_data_lo[max_payload_width_p+:bsg_tag_header_width_lp];
    wire [max_payload_width_p-1:0]       payload_n = tr_data_lo[0+:max_payload_width_p];
    wire [trace_ring_width_lp + 2 - 1:0] data_n    = {1'b0, payload_n, header_n, 1'b1};

   wire 				 piso_ready_lo;
   assign tr_yumi_li = piso_ready_lo & tr_valid_lo;
   
    // Instantiate the paralle-in serial-out data structure.
    bsg_parallel_in_serial_out #( .width_p(1)
                                , .els_p(trace_ring_width_lp + 2) )
      trace_piso
        (.clk_i   (clk_i)
        ,.reset_i (reset_i)
   
        /* Data Input Channel (Valid then Yumi) */
        ,.valid_i (tr_valid_lo)
        ,.data_i  (data_n)
        ,.ready_and_o (piso_ready_lo)
   
        /* Data Output Channel (Valid then Yumi) */
        ,.valid_o (valid_o)
        ,.data_o  (tag_data_o)
        ,.yumi_i  (yumi_i)
        );

  // If there are "no masters" (or at least none required to drive the enables
  // for) then we will disconnect en_r_o, otherwise we will instantiate a
  // register to capture the enables.
  if (num_masters_p == 0)
    begin
      assign en_r_o = 1'bz;
    end
  else
    begin
      bsg_dff_en #( .width_p(num_masters_p) )
        en_reg
          (.clk_i  (clk_i)
          ,.en_i   (tr_valid_lo & piso_ready_lo)
          ,.data_i (tr_data_lo[(max_payload_width_p+bsg_tag_header_width_lp)+:num_masters_p])
          ,.data_o (en_r_o)
          );
    end

endmodule
