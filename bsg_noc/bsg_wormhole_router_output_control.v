`include "bsg_defines.v"

module bsg_wormhole_router_output_control
  #(parameter input_dirs_p=-1)
   (input clk_i
    , input reset_i

    // this input channel has a header packet at the head of the FIFO for this output
    , input  [input_dirs_p-1:0] reqs_i

    // the input channel finished a packet on the previous cycle
    // note: it is up to this module to verify that the input channel was allocated to this output channel
    , input  [input_dirs_p-1:0] release_i

    // from input fifos
    , input [input_dirs_p-1:0] valid_i
    , output [input_dirs_p-1:0] yumi_o

    // channel outputs
    , input ready_i
    , output valid_o
    , output [input_dirs_p-1:0] data_sel_o
    );

   wire [input_dirs_p-1:0] scheduled_r, scheduled_with_release, scheduled_n, grants_lo;

   bsg_dff_reset #(.width_p(input_dirs_p)) scheduled_reg (.clk_i, .reset_i, .data_i(scheduled_n), .data_o(scheduled_r));

   assign scheduled_with_release = scheduled_r & ~release_i;

   wire                     free_to_schedule = !scheduled_with_release;

   bsg_round_robin_arb
     #(.inputs_p(input_dirs_p)) brr
   (.clk_i
    ,.reset_i
    ,.grants_en_i  (free_to_schedule)      // ports are all free
    ,.reqs_i       (reqs_i)                // requests from input ports
    ,.grants_o     (grants_lo)             // output grants, takes into account grants_en_i
    ,.sel_one_hot_o()                      // output grants, does not take into account grants_en_i
    ,.v_o          ()                      // some reqs_i was set
    ,.tag_o        ()
    // make sure to only allocate the port if we succeeded in transmitting the header
    // otherwise the input will try to allocate again on the next cycle
    ,.yumi_i       (free_to_schedule & ready_i & valid_o) // update round_robin
    );

   assign scheduled_n = grants_lo | scheduled_with_release;
   assign data_sel_o = scheduled_n;
   assign valid_o = (|(scheduled_n & valid_i));
   assign yumi_o  = ready_i ? (scheduled_n & valid_i) : '0;
endmodule




