`include "bsg_defines.v"
// MBT
// 11/9/14
//
// a fifo with only one read or write port,
// using a 1RW *synchronous read* ram.
//
// NOTE: read results appear on next cycle
//

module bsg_fifo_1rw_large #(parameter width_p         = -1
                          , parameter els_p           = -1
			  , parameter verbose_p       = 0
                          )
   (input                  clk_i
    , input                reset_i
    , input [width_p-1:0]  data_i
    , input                v_i
    , input                enq_not_deq_i

    // full and empty are richer
    // than ready_enq and ready_deq
    // which could mean just this cycle

    , output full_o
    , output empty_o
    , output [width_p-1:0] data_o
    );

   localparam ptr_width_lp = `BSG_SAFE_CLOG2(els_p);

   logic [ptr_width_lp-1:0]       rd_ptr, wr_ptr;

   logic                          last_op_is_read_r;


   wire mem_we = enq_not_deq_i & v_i;
   wire mem_re = ~enq_not_deq_i & v_i;

   always_ff @(posedge clk_i)
     if (reset_i)
       last_op_is_read_r <= 1;
     else
       if (v_i)
         last_op_is_read_r <= mem_re;

   // empty versus full detection. very nice for
   // one port case. if ptrs match and last op was a read
   // a read, it must be empty; if last op was a write,
   // it must be full.

   wire fifo_empty = (rd_ptr == wr_ptr) & last_op_is_read_r;
   wire fifo_full  = (rd_ptr == wr_ptr) & ~last_op_is_read_r;

   assign full_o  = fifo_full;
   assign empty_o = fifo_empty;

   // synopsys translate_off

   always_ff @(posedge clk_i)
     assert (reset_i
             | ((fifo_full & mem_we) !== 1)
             ) else $error("enque on full fifo");

   always_ff @(posedge clk_i)
     assert (reset_i
             | ((fifo_empty & mem_re) !== 1)
             ) else $error("deque on empty fifo %x %x", fifo_empty, mem_re, v_i, enq_not_deq_i);

   always_ff @(posedge clk_i)
     if (verbose_p)
       if (v_i)
         begin
            if (enq_not_deq_i)
              $display("### %m enq %x onto fifo (r=%x w=%x)",data_i,rd_ptr,wr_ptr);
            else
              $display("### %m deq fifo (r=%x w=%x)",rd_ptr,wr_ptr);
         end


   wire [31:0] num_elements_debug = (fifo_empty
                                     ? 0
                                     : (fifo_full
                                        ? els_p
                                        : (wr_ptr > rd_ptr
                                           ? (wr_ptr - rd_ptr)
                                           : (els_p - (rd_ptr - wr_ptr)))));

   // synopsys translate_on

   bsg_circular_ptr #(.slots_p(els_p)
                      ,.max_add_p(1)
                      ) rd_circ_ptr
     (.clk      (clk_i)
      , .reset_i(reset_i)
      , .add_i  (mem_re)
      , .o      (rd_ptr )
      , .n_o()
      );

   bsg_circular_ptr #(.slots_p(els_p)
                      ,.max_add_p(1)
                      ) wr_circ_ptr
     (.clk      (clk_i  )
      , .reset_i(reset_i)
      , .add_i  (mem_we)
      , .o      (wr_ptr )
      , .n_o()
      );

   bsg_mem_1rw_sync #(.width_p(width_p)
                      ,.els_p(els_p)
                      )
   mem_1srw (.clk_i
             ,.reset_i
             ,.data_i (data_i                   )
             ,.addr_i (mem_we ? wr_ptr : rd_ptr )
             ,.v_i    (v_i                      )
             ,.w_i    (mem_we                   )
             ,.data_o (data_o                   )
             );



endmodule
