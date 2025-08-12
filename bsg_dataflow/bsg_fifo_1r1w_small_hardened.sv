//
// bsg_fifo_1r1w_small_hardened
//
// bsg_fifo with 1 read and 1 write, used for smaller fifos
// No bubble between packets, has one-cycle latency
//
// This fifo instantiates bsg_mem_1r1w_sync memory, which has synchronous read
// port with 1-cycle read-delay. It is possible to read/write same address when
//   1. fifo is empty
//   2. fifo has one element, and it enqueues / dequeues in same cycle
// Read/write same address is usually not allowed. Whenever this happens, writing
// is prioritized and reading is paused for current cycle. Write data is also stored
// into bypass register so that it shows up on read side in the next cycle to make up
// for the dropped read request.
//
// input handshake protocol (based on ready_THEN_valid_p parameter):
//     valid-and-ready or
//     ready-then-valid
//
// output protocol is valid-yumi (like typical fifo)
//                    aka valid-then-ready
//
//

`include "bsg_defines.sv"

module bsg_fifo_1r1w_small_hardened #(parameter `BSG_INV_PARAM(width_p)
                            , parameter `BSG_INV_PARAM(els_p)
                            , parameter ready_THEN_valid_p = 0
                            )
    ( input                clk_i
    , input                reset_i

    , input                v_i
    , output               ready_param_o
    , input [width_p-1:0]  data_i

    , output               v_o
    , output [width_p-1:0] data_o
    , input                yumi_i
    );

   wire deque = yumi_i;
   wire v_o_tmp;

   assign v_o = v_o_tmp;

   // vivado bug prohibits declaring wire inside of generate block
   wire enque;
   logic ready_param_lo;

   if (ready_THEN_valid_p)
     begin: rtv
        assign enque = v_i;
     end
   else
     begin: rav
        assign enque = v_i & ready_param_lo;
     end

   localparam ptr_width_lp = `BSG_SAFE_CLOG2(els_p);

   // one read pointer, one write pointer;
   logic [ptr_width_lp-1:0] rptr_r, wptr_r;
   logic                    full, empty;
   // rptr_n is one cycle earlier than rptr_r
   logic [ptr_width_lp-1:0] rptr_n;
   // avoid reading and writing same address in mem_1r1w_sync
   logic [width_p-1:0] data_o_mem, data_o_reg;
   logic read_write_same_addr_r, read_write_same_addr_n;
  
   bsg_fifo_tracker #(.els_p(els_p)
                          ) fts
     (.clk_i
      ,.reset_i
      ,.enq_i    (enque)
      ,.deq_i    (deque)
      ,.wptr_r_o (wptr_r)
      ,.rptr_r_o (rptr_r)
      ,.rptr_n_o (rptr_n)
      ,.full_o   (full)
      ,.empty_o  (empty)
      );

   // sync read
   // Prioritize write when reading/writing same address
   bsg_mem_1r1w_sync #(.width_p (width_p)
                      ,.els_p   (els_p  )
                      // MBT: this should be zero
                      ,.read_write_same_addr_p(0)
                      ,.disable_collision_warning_p(0)
                      ,.harden_p(1)
                      ) mem_1r1w_sync
     (.clk_i
      ,.reset_i
      ,.w_v_i    (enque     )
      ,.w_addr_i (wptr_r    )
      ,.w_data_i (data_i    )
      ,.r_v_i    (~read_write_same_addr_n)
      ,.r_addr_i (rptr_n    )
      ,.r_data_o (data_o_mem)
      );
      
   // w_data bypass register, enable when read_write_same_addr happens
   bsg_dff_en #(.width_p(width_p)) bypass_reg
     (.clk_i
      ,.data_i(data_i)
      ,.en_i  (read_write_same_addr_n)
      ,.data_o(data_o_reg)
      );
   
   // Read from bypass register when read_write_same_addr happens in previous cycle
   assign data_o = (read_write_same_addr_r)? data_o_reg : data_o_mem;
   always_ff @(posedge clk_i)
     read_write_same_addr_r <= read_write_same_addr_n;
   
   // When enque==1 and read/write address are same, stop reading
   // A copy of data is written into bypass register in same cycle
   assign read_write_same_addr_n = enque & (wptr_r == rptr_n);

   // during reset, we keep ready low
   // even though fifo is empty

   //assign ready_param_lo = ~full & ~reset_i;
   assign ready_param_lo = ~full;
   assign ready_param_o = ready_param_lo;
   assign v_o_tmp = ~empty;

`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @ (posedge clk_i)
     begin
        if (ready_THEN_valid_p & full  & v_i    & ~reset_i)
          $display("%m error: enque full fifo at time %t", $time);
        if (empty & yumi_i & ~reset_i)
          $display("%m error: deque empty fifo at time %t", $time);
     end
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_1r1w_small_hardened)
