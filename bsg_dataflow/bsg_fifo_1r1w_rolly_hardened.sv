
`include "bsg_defines.v"

module bsg_fifo_1r1w_rolly_hardened
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(lg_size_p)
    , parameter ready_THEN_valid_p = 0
    , localparam els_lp = (1 << lg_size_p)
    )
  (input                  clk_i
   , input                reset_i

   , input                clr_v_i
   , input                deq_v_i
   , input                roll_v_i

   , input [width_p-1:0]  data_i
   , input                v_i
   , output               ready_o

   , output [width_p-1:0] data_o
   , output               v_o
   , input                yumi_i
   );

  logic [lg_size_p-1:0] wptr_r;
  logic                 full, empty;
  // rptr_n is one cycle earlier than rptr_r
  logic [lg_size_p-1:0] rptr_n;

  wire r_deq       = yumi_i;
  wire r_incr      = deq_v_i;
  wire r_rewind    = roll_v_i;
  wire r_forward   = 1'b0; // unused
  wire r_clear     = 1'b0; // unused

  wire w_enq       = ready_THEN_valid_p ? v_i : ready_o & v_i;
  wire w_incr      = 1'b0; // unused
  wire w_rewind    = 1'b0; // unused
  wire w_forward   = 1'b1; // ...so that wptr always == wcptr
  wire w_clear     = clr_v_i;

  assign ready_o = ~w_clear & ~full;
  assign v_o     = ~r_clear & ~r_rewind & ~empty;

  bsg_fifo_rolly_tracker
   #(.lg_size_p(lg_size_p))
   ft
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.r_deq_i(r_deq)
     ,.r_incr_i(r_incr)
     ,.r_rewind_i(r_rewind)
     ,.r_forward_i(r_forward)
     ,.r_clear_i(r_clear)

     ,.w_enq_i(w_enq)
     ,.w_incr_i(w_incr)
     ,.w_rewind_i(w_rewind)
     ,.w_forward_i(w_forward)
     ,.w_clear_i(w_clear)

     ,.wptr_r_o(wptr_r)
     ,.rptr_r_o()
     ,.wcptr_r_o()
     ,.rcptr_r_o()

     ,.wptr_n_o()
     ,.rptr_n_o(rptr_n)
     ,.wcptr_n_o()
     ,.rcptr_n_o()

     ,.full_o(full)
     ,.empty_o(empty)
     );

  logic [width_p-1:0] data_o_mem, data_o_reg;
  logic read_write_same_addr_r, read_write_same_addr_n;

  bsg_mem_1r1w_sync
  #(.width_p(width_p)
    ,.els_p(els_lp)
    ,.read_write_same_addr_p(0)
    ,.disable_collision_warning_p(0)
    ,.harden_p(1))
  fifo_mem
   (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.w_v_i(w_enq)
    ,.w_addr_i(wptr_r)
    ,.w_data_i(data_i)
    ,.r_v_i(~read_write_same_addr_n)
    ,.r_addr_i(rptr_n)
    ,.r_data_o(data_o_mem)
    );

  bsg_dff_en
  #(.width_p(width_p))
  bypass_reg
   (.clk_i(clk_i)
    ,.data_i(data_i)
    ,.en_i  (read_write_same_addr_n)
    ,.data_o(data_o_reg)
    );

  assign read_write_same_addr_n = w_enq & (wptr_r == rptr_n);
  always_ff @(posedge clk_i)
    read_write_same_addr_r <= read_write_same_addr_n;
  assign data_o = (read_write_same_addr_r) ? data_o_reg : data_o_mem;

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_1r1w_rolly_hardened)

