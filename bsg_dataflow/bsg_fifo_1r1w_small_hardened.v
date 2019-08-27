// bsg_fifo_1r1w_small_hardened
//
// bsg_fifo with 1 read and 1 write, using
// 1-write 1-async-read register file implementation.
//
// used for smaller fifos.
//
// input handshake protocol (based on ready_THEN_valid_p parameter):
//     valid-and-ready or
//     ready-then-valid
//
// output protocol is valid-yumi (like typical fifo)
//                    aka valid-then-ready
//
//

module bsg_fifo_1r1w_small_hardened #( parameter width_p      = -1
                            , parameter els_p        = -1
                            , parameter ready_THEN_valid_p = 0
                            )
    ( input                clk_i
    , input                reset_i

    , input                v_i
    , output               ready_o
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
   logic ready_lo;

   if (ready_THEN_valid_p)
     begin: rtv
        assign enque = v_i;
     end
   else
     begin: rav
        assign enque = v_i & ready_lo;
     end

   localparam ptr_width_lp = `BSG_SAFE_CLOG2(els_p);

   // one read pointer, one write pointer;
   logic [ptr_width_lp-1:0] rptr_r, wptr_r;
   logic                    full, empty;
   // one cycle earlier than rptr_r
   logic [ptr_width_lp-1:0] rptr_n;
   // one cycle later than empty
   logic empty_r;
   // avoid reading and writing same address 
   logic [width_p-1:0] data_o_mem, data_o_reg;
  
   bsg_fifo_tracker_sync #(.els_p(els_p)
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
      ,.empty_r_o(empty_r)
      );

   // sync read
   bsg_mem_1r1w_sync #(.width_p (width_p)
                      ,.els_p   (els_p  )
                      // MBT: this should be zero
                      ,.read_write_same_addr_p(0)
                      ,.harden_p(1)
                      ) mem_1r1w_sync
     (.clk_i
      ,.reset_i
      ,.w_v_i    (enque     )
      ,.w_addr_i (wptr_r    )
      ,.w_data_i (data_i    )
      ,.r_v_i    (v_o_tmp   )
      ,.r_addr_i (rptr_n    )
      ,.r_data_o (data_o_mem)
      );
      
   // w_data bypass register, handling read_write_same_addr case
   bsg_dff_en #(.width_p(width_p)) bypass_reg
     (.clk_i
      ,.data_i(data_i)
      ,.en_i  (enque & empty)
      ,.data_o(data_o_reg)
      );
    
   assign data_o = (empty_r)? data_o_reg : data_o_mem;

   // during reset, we keep ready low
   // even though fifo is empty

   //assign ready_lo = ~full & ~reset_i;
   assign ready_lo = ~full;
   assign ready_o = ready_lo;
   assign v_o_tmp = ~empty;

   //synopsys translate_off
   always_ff @ (posedge clk_i)
     begin
        if (ready_THEN_valid_p & full  & v_i    & ~reset_i)
          $display("%m error: enque full fifo at time %t", $time);
        if (empty & yumi_i & ~reset_i)
          $display("%m error: deque empty fifo at time %t", $time);
     end
   //synopsys translate_on

/*
   always_ff @(negedge clk_i)
     begin
        $display("%m v_i=%x yumi_i=%x wptr=%b rptr=%b enque=%b full=%d empty=%d ready_o=%d",v_i,yumi_i,wptr_r, rptr_r, enque, full,empty,ready_o);
     end
 */
endmodule
