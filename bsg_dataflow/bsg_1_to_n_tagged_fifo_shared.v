// MBT 7/7/2016
//
// This module implements a FIFO that takes in a multiplexed stream
// on one end, and provides demultiplexed access on the other.
//
// Each stream is guaranteed to have els_p worth of storage.
//
// The shared version of this module shares the storage for the fifos.
// This is useful when the rate at which data is coming in at a rate
// less than half the frequency of the clock domain.
//
// However, guarantees about performance are still contingent on
// the receiver dequeing data during the "free slots" that the
// producer is not enqueing data. To help with these guarantees
// we provide some "little fifo" buffering for each incoming channel.
//
// The parameter unbuffered_mask_p allows you to select some channels
// to come out without a FIFO. This is useful, for example, for credit
// channels that do not need buffering. The yumi_i signal is ignored
// for these channels; they are assumed to always be ready.
//
// Note that this version only guarantees that it is able to store
// up to the els_p capacity without stalls. It does not make any guarantees
// about the timeliness of read data, and in fact it almost always adds delay.
// Potentially, we could add bypassing to the small FIFOs, but that adds complexity
// but potentially saves power and reduces latency.
//
// Unbuffered mask: these indicate channels that do not require buffering
// because they can be consumed immediately.
//

`include "bsg_defines.v"

module bsg_1_to_n_tagged_fifo_shared   #(parameter width_p              = "inv"
                                         ,parameter num_out_p           = "inv"
                                         ,parameter els_p               = "inv" // these are elements per channel
                                         ,parameter buffering_p         = "inv" // elements in small FIFOs
                                                                                // three is probably the minumum
                                                                                // and more than that is probably advised
                                         ,parameter unbuffered_mask_p   = 0
                                         ,parameter sram_1rw_not_1r1w_p = 1
                                         ,parameter tag_width_lp        = `BSG_SAFE_CLOG2(num_out_p)
                                         )
   (input  clk_i
    , input  reset_i

    // input side
    , input                    valid_i
    , input [tag_width_lp-1:0]   tag_i
    , input [     width_p-1:0]  data_i
    , output                    yumi_o

    // output side
    , output [num_out_p-1:0]              valid_o
    , input  [num_out_p-1:0]               yumi_i
    , output [num_out_p-1:0] [width_p-1:0] data_o

    );

   localparam ptr_width_lp = `BSG_SAFE_CLOG2(els_p);

   genvar i;

   // one read pointer, one write pointer;
   logic [num_out_p-1:0][ptr_width_lp-1:0] rptr_r, wptr_r;
   logic [num_out_p-1:0]                   full,   empty;
   logic [num_out_p-1:0]                   enque, deque;
   logic [num_out_p-1:0][`BSG_SAFE_CLOG2(buffering_p)-1:0] els;
   logic [num_out_p-1:0]                                   credits_avail;

   wire read_req;
   wire write_req = valid_i;

   wire [tag_width_lp-1:0] read_req_tag, read_req_tag_r;
   logic [num_out_p-1:0]   read_req_tag_decoded;

   wire                    big_ram_we, big_ram_re, read_ram_re_r;

   wire [num_out_p-1:0 ]   tag_one_hot_or_not;

   bsg_1_to_n_tagged #(.num_out_p(num_out_p)) b1nt
     (.clk_i
      ,.reset_i
      ,.valid_i
      ,.tag_i
      ,.yumi_o

      ,.valid_o(tag_one_hot_or_not)
      ,.ready_i(~full)
      );

   assign enque = (~full)
     & (tag_one_hot_or_not);

   // create a vector of FIFO trackers, one for each channel inside the shared RAM
   // then create a vector of credit counters, one for each FIFO outside the shared RAM

   for (i = 0; i < num_out_p; i=i+1)
     begin: rof
        if (unbuffered_mask_p[i])
          begin : unbuf
             assign wptr_r [i] = 0;
             assign rptr_r [i] = 0;
             // never have anything to send
             // always happy to receive
             assign full [i] = 1'b0;
             assign empty[i] = 1'b1;

             // FIFO never has space, never
             // try to read from the big ram to fill it
             assign els[i] = 0;
          end
        else
          begin : bufd
             bsg_fifo_tracker #(.els_p(els_p)
                                ) ft
               (.clk_i
                ,.reset_i
                ,.enq_i   (enque [i])
                ,.deq_i   (deque [i])
                ,.wptr_r_o(wptr_r[i])
                ,.rptr_r_o(rptr_r[i])
                ,.full_o  (full  [i])
                ,.empty_o (empty [i])
                );

             bsg_counter_up_down #(.max_val_p  (buffering_p)
                                   ,.init_val_p(buffering_p)
                                   ) bcudb
               (.clk_i
                ,.reset_i
                ,.up_i    (yumi_i[i]                            ) // deque from fifo
                ,.down_i  (read_req_tag_decoded[i] & big_ram_re)
                ,.count_o (els[i]                               )
                );

             assign credits_avail[i] = |els[i];
          end
     end

   // select which reader gets to read
   bsg_round_robin_arb #(.inputs_p(num_out_p))  rdr_arb
   (.clk_i
    ,.reset_i
    ,.grants_en_i (1'b1)

    ,.reqs_i  (credits_avail & ~empty)
    ,.grants_o(selected_reader_vec   )
    ,.sel_one_hot_o()

    ,.v_o     (read_req       )
    ,.tag_o   (read_req_tag   )
    ,.yumi_i  (big_ram_re & read_req  )
    );

   // these are the pointers to the big ram that we are selecting
   wire [tag_width_lp+ptr_width_lp-1:0] big_ram_wptr = { tag_i,           wptr_r[tag_i]           };
   wire [tag_width_lp+ptr_width_lp-1:0] big_ram_rptr = { read_req_tag,    rptr_r[read_req_tag]    };
   wire [width_p-1:0]                   sram_data_lo;

   wire                                 tag_i_is_unbuffered = unbuffered_mask_p[tag_i];

   if (sram_1rw_not_1r1w_p)
     begin : _1rw
        assign big_ram_we = write_req & ~tag_i_is_unbuffered;
        assign big_ram_re = ~write_req & read_req;

        bsg_mem_1rw_sync #(.width_p(width_p)
                           ,.els_p(els_p   )
                           ) big_ram
          (.clk_i
           ,.reset_i
           ,.data_i(data_i)
           ,.addr_i(big_ram_we ? wptr_big_ram : rptr_big_ram)
           ,.v_i   (big_ram_we | big_ram_re)
           ,.w_i   (big_ram_we)
           ,.data_o(sram_data_lo)
           );
     end // block: _1rw
   else
     begin : _1r1w
        assign big_ram_we = write_req & ~tag_i_is_unbuffered;
        assign big_ram_re = ready_req;

        // we should never read and write the same address
        // at the same time, since we would not read data
        // until it is empty.

        bgs_mem_1r1w_sync #(.width_p(width_p)
                            ,.els_p (els_p  )
                            ) big_ram
          (.clk_i
           ,.reset_i

           ,.w_v_i    (big_ram_we  )
           ,.w_addr_i (wptr_big_ram)
           ,.w_data_i (data_i      )

           ,.r_v_i    (big_ram_re  )
           ,.r_addr_i (rptr_big_ram)
           ,.r_data_o (sram_data_lo)
           );
     end

   bsg_dff_reset #(.width_p($size(big_ram_re)+$size(read_req_tag)), .init_val_p(0)) dff
   (.clk_i,.reset_i
    ,.data_i({big_ram_re,   read_req_tag  })
    ,.data_o({big_ram_re_r, read_req_tag_r})
    );


   wire yumi_lo;

   wire [num_out_p-1:0] yumi_i_tmp = yumi_i & ~unbuffered_mask_p;

   wire [num_out_p-1:0]               valid_o_tmp;
   wire [num_out_p-1:0] [width_p-1:0] data_o_tmp;

   bsg_1_to_n_tagged_fifo #(.width_p           (width_p)
                            ,.num_out_p        (num_out_p)
                            ,.els_p            (els_p)
                            ,.unbuffered_mask_p(unbuffered_mask_p)
                            ) b1ntf
     (.clk_i
      ,.reset_i
      ,.valid_i(big_ram_re_r  )
      ,.tag_i  (read_req_tag_r)
      ,.data_i (sram_data_lo)
      // should always be == big_ram_re_r
      ,.yumi_o (yumi_lo)

      // producer side
      ,.valid_o(valid_o_tmp)
      ,.yumi_i (yumi_i_tmp )
      ,.data_o (data_o_tmp )
      );

   assign valid_o = valid_o_tmp | (unbuffered_mask_p[i] & tag_one_hot_or_not[i]);

   // if we have an unbuffered channel, we override the channel
   for (i = 0; i < num_out_p; i=i+1)
     begin: rof
        assign data_o [i]  = unbuffered_mask_p[i] ? data_i : data_o_tmp;
     end

   always_ff @(negedge clk_i)
     assert(yumi_lo == big_ram_re_r)
       else $error("%m error; unexpected full little FIFO; credit counters not working?");

endmodule
