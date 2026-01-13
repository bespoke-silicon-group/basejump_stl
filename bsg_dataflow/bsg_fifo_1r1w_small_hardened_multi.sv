//
// bsg_fifo_1r1w_small_hardened_multi
//
// AI-generated: ChatGPT 5.2 Pro (codex)
//
// Multi-virtualized version of bsg_fifo_1r1w_small_hardened.
// Each virtual fifo has its own tracker and bypass flag/register, but all data
// lives in a single shared bsg_mem_1r1w_sync.
// NOTE: The user must ensure that at most one bit of yumi_i is asserted per cycle.
//
// Address mapping:
//   addr = fifo_id * els_p + ptr
// This keeps fifo segments disjoint even when els_p/fifos_p are not powers of two.
//
// Correctness sketch and corner cases (per fifo i; enq_id_i in range, and yumi_i one-hot or zero):
// Invariants:
//  I1) bsg_fifo_tracker maintains pointers and full/empty, so ready_param_o[i]
//      and v_o[i] match occupancy after each clock edge.
//  I2) Address mapping base_i = i*els_p makes each fifo's segment disjoint:
//      addr = base_i + ptr, so different fifo IDs never alias.
//  I3) Head storage: if read_write_same_addr_r[i] is 1, the head element is in
//      data_bypass_r[i]; otherwise it is in data_head_r[i].
//      data_head_r[i] is driven by bsg_dff_en_bypass with head_en=read_v_r & read_one_hot_r[i],
//      so it updates only when fifo i is read and holds its value when idle.
//      data_o[i] selects between these two, so each fifo exposes its head data.
//  I4) read_write_same_addr_n = enq & (wptr_r == rptr_n). When true, RAM read/write
//      are suppressed and bypass captures data_i; set dominates clear so enqueue
//      replacement wins on enq+deq singletons.
//  I5) No same-address RAM R/W: if same fifo and wptr==rptr_n, both read/write are
//      disabled; otherwise rptr_n and wptr_r differ. If different fifos, base_i
//      differ, so addresses differ. Thus 1R1W RAM hazards are avoided.
//  I6) read_one_hot_r captures deq_one_hot when a RAM read is issued, so only the
//      dequeued fifo updates its head register on the following cycle.
//
// Cases:
// 1) Empty + enqueue only:
//    wptr_r==rptr_r and rptr_n==rptr_r, so read_write_same_addr_n=1.
//    read/write are suppressed, bypass captures data_i, and bypass flag sets.
//    After the edge, v_o[i]=1 and data_o selects bypass, so the new element is
//    immediately visible with correct ordering.
// 2) Empty + dequeue:
//    v_o[i]=0 by I1, so a well-formed sender will not assert yumi_i[i]. If it does,
//    the design flags the error; correctness relies on the valid-yumi protocol.
// 3) One element + dequeue only:
//    wptr_r==rptr_n, so no RAM read. The head (bypass or head_data) is consumed.
//    The bypass flag clears on deq, and the fifo becomes empty (v_o deasserts).
// 4) One element + enqueue+dequeue same cycle:
//    wptr_r==rptr_n, so RAM ops are suppressed. bypass captures new data_i and
//    set dominates clear, so bypass flag stays high. The old head is dequeued,
//    the new element remains as the sole entry, and data_o shows it next cycle.
// 5) Two+ elements + dequeue only:
//    wptr_r!=rptr_n, so read_mem_en=1 and raddr uses rptr_n (next element).
//    The current head is consumed; data_head_r updates next cycle with the next
//    element, so v_o stays high without bubbles.
// 6) Two+ elements + enqueue only:
//    write_mem_en=1 writes to wptr_r; head storage is unchanged, preserving order.
// 7) Two+ elements + enqueue+dequeue same fifo:
//    wptr_r!=rptr_n, so read and write occur to distinct addresses. The dequeued
//    element is the old head; the enqueued element becomes the new tail, and
//    occupancy is unchanged.
// 8) Enqueue and dequeue different fifos:
//    By I2, base_i differ, so addresses differ even if pointer values match.
//    One RAM read and one RAM write per cycle are safe in the shared 1R1W memory.
// 9) Bypass flag with additional elements:
//    While bypass flag is set, data_o uses bypass. On a dequeue, the flag clears.
//    If more data remains, a read is issued and data_head_r captures the next
//    element, so data_o stays correct on the following cycle.
// 10) els_p==1:
//     Pointers always equal; read_write_same_addr_n is true for enq, so RAM is
//     unused and the bypass holds the sole element. Full/empty from I1 still hold.
// 11) fifos_p==1:
//     base_i=0 and the design reduces to a single fifo with identical bypass
//     semantics; all cases above still apply.
// 12) Output vectorization:
//     data_o[i] is driven for every fifo i, independent of yumi_i. By I3,
//     whenever v_o[i] is asserted, data_o[i] is the correct head element.
//

`include "bsg_defines.sv"

module bsg_fifo_1r1w_small_hardened_multi
  #(parameter `BSG_INV_PARAM(width_p)
    , parameter `BSG_INV_PARAM(els_p)
    , parameter `BSG_INV_PARAM(fifos_p)
    , localparam ptr_width_lp  = `BSG_SAFE_CLOG2(els_p)
    , localparam lg_fifos_lp   = `BSG_SAFE_CLOG2(fifos_p)
    , localparam int unsigned total_els_lp = fifos_p * els_p
    , localparam int unsigned addr_width_lp = `BSG_SAFE_CLOG2(total_els_lp)
    )
   ( input  logic                     clk_i
     , input  logic                     reset_i

     // Enqueue (ready/valid)
     , input  logic                     v_i
     , input  logic [lg_fifos_lp-1:0]   enq_id_i
     , output logic [fifos_p-1:0]       ready_param_o
     , input  logic [width_p-1:0]       data_i

     // Dequeue (valid/yumi)
     , output logic [fifos_p-1:0]       v_o
     , output logic [fifos_p-1:0][width_p-1:0] data_o
     , input  logic [fifos_p-1:0]       yumi_i
     );

   logic [fifos_p-1:0][ptr_width_lp-1:0] wptr_r;
   logic [fifos_p-1:0][ptr_width_lp-1:0] rptr_r;
   logic [fifos_p-1:0][ptr_width_lp-1:0] rptr_n;
   logic [fifos_p-1:0]      full, empty;

   logic [fifos_p-1:0]      enq_one_hot, deq_one_hot;
   logic [fifos_p-1:0]      enq_id_one_hot;
   logic [fifos_p-1:0]      read_write_same_addr_n, read_write_same_addr_r;
   logic [fifos_p-1:0]      write_mem_en_one_hot, read_mem_en_one_hot;

   logic [fifos_p-1:0][width_p-1:0] data_bypass_r;
   logic [fifos_p-1:0][width_p-1:0] data_head_r;
   logic [fifos_p-1:0][addr_width_lp-1:0] base_addr;
   logic [fifos_p-1:0][addr_width_lp-1:0] waddr_vec, raddr_vec;
   logic [addr_width_lp-1:0] waddr, raddr;

   bsg_decode_with_v #(.num_out_p(fifos_p)) enq_id_dec
     (.i(enq_id_i)
      ,.v_i(v_i)
      ,.o(enq_id_one_hot)
      );

   assign enq_one_hot = enq_id_one_hot & ready_param_o;

   assign deq_one_hot = yumi_i;

   genvar i;
   for (i = 0; i < fifos_p; i++)
     begin: fifo
      bsg_fifo_tracker #(.els_p(els_p)) fts
         (.clk_i
          ,.reset_i
          ,.enq_i    (enq_one_hot[i])
          ,.deq_i    (deq_one_hot[i])
          ,.wptr_r_o (wptr_r[i])
          ,.rptr_r_o (rptr_r[i])
          ,.rptr_n_o (rptr_n[i])
          ,.full_o   (full[i])
          ,.empty_o  (empty[i])
          );

       assign ready_param_o[i] = ~full[i];
       assign v_o[i]           = ~empty[i];
       assign base_addr[i]     = addr_width_lp'(i * els_p);
       assign waddr_vec[i]     = base_addr[i] + wptr_r[i];
       assign raddr_vec[i]     = base_addr[i] + rptr_n[i];

       assign read_write_same_addr_n[i] =
         enq_one_hot[i] & (wptr_r[i] == rptr_n[i]);

       assign write_mem_en_one_hot[i] =
         enq_one_hot[i] & (wptr_r[i] != rptr_n[i]);

       assign read_mem_en_one_hot[i] =
         deq_one_hot[i] & (wptr_r[i] != rptr_n[i]);

       bsg_dff_en #(.width_p(width_p)) bypass_reg
         (.clk_i
          ,.data_i(data_i)
          ,.en_i  (read_write_same_addr_n[i])
          ,.data_o(data_bypass_r[i])
          );

       bsg_dff_reset_set_clear #(.width_p(1)) read_write_same_addr_reg
         (.clk_i
          ,.reset_i
          ,.set_i   (read_write_same_addr_n[i])
          ,.clear_i (deq_one_hot[i])
          ,.data_o  (read_write_same_addr_r[i])
          );
     end

   wire write_mem_en = |write_mem_en_one_hot;
   wire read_mem_en  = |read_mem_en_one_hot;

   bsg_mux_one_hot #(.width_p(addr_width_lp), .els_p(fifos_p)) waddr_mux
     (.data_i(waddr_vec)
      ,.sel_one_hot_i(enq_one_hot)
      ,.data_o(waddr)
      );

   bsg_mux_one_hot #(.width_p(addr_width_lp), .els_p(fifos_p)) raddr_mux
     (.data_i(raddr_vec)
      ,.sel_one_hot_i(deq_one_hot)
      ,.data_o(raddr)
      );

   logic [width_p-1:0] data_o_mem;

   bsg_mem_1r1w_sync #(.width_p (width_p)
                      ,.els_p   (total_els_lp)
                      ,.addr_width_lp(addr_width_lp)
                      ,.read_write_same_addr_p(0)
                      ,.disable_collision_warning_p(0)
                      ,.latch_last_read_p(0)
                      ,.harden_p(1)
                      ) mem_1r1w_sync
     (.clk_i
      ,.reset_i
      ,.w_v_i    (write_mem_en)
      ,.w_addr_i (waddr)
      ,.w_data_i (data_i)
      ,.r_v_i    (read_mem_en)
      ,.r_addr_i (raddr)
      ,.r_data_o (data_o_mem)
      );

   logic                   read_v_r;
   logic [fifos_p-1:0]     read_one_hot_r;

   always_ff @(posedge clk_i)
     begin
       if (reset_i)
         begin
           read_v_r       <= 1'b0;
           read_one_hot_r <= '0;
         end
       else
         begin
           read_v_r <= read_mem_en;
           if (read_mem_en)
             read_one_hot_r <= deq_one_hot;
         end
     end

   for (i = 0; i < fifos_p; i++)
     begin: head_store
       wire head_en = read_v_r & read_one_hot_r[i];
       bsg_dff_en_bypass #(.width_p(width_p)) head_reg
         (.clk_i
          ,.en_i  (head_en)
          ,.data_i(data_o_mem)
          ,.data_o(data_head_r[i])
          );
       assign data_o[i] = read_write_same_addr_r[i]
         ? data_bypass_r[i]
         : data_head_r[i];
     end

`ifndef BSG_HIDE_FROM_SYNTHESIS
  always_ff @(posedge clk_i)
    if (~reset_i)
      begin
        if (v_i & |(full & enq_id_one_hot))
          $display("%m error: enque full fifo at time %t", $time);
        if ((v_i) && ((1 << lg_fifos_lp) != fifos_p)
            && (enq_id_i >= lg_fifos_lp'(fifos_p)))
          $error("%m error: enq_id_i out of range (%0d) at time %t", enq_id_i, $time);
        for (int ii = 0; ii < fifos_p; ii++)
          if (yumi_i[ii] & empty[ii])
            $display("%m error: deque empty fifo[%0d] at time %t", ii, $time);
        if (!$onehot0(yumi_i))
          $error("%m error: multiple yumi_i asserted in one cycle");
        if (write_mem_en & read_mem_en)
          assert (waddr != raddr)
            else $error("%m: shared RAM same-address R+W in one cycle");
      end
`endif

endmodule

`BSG_ABSTRACT_MODULE(bsg_fifo_1r1w_small_hardened_multi)
