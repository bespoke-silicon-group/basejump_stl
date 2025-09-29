// bsg_fifo_1r1w_multi
//
// This implements the logic for multiple fifos that share
// a common pool of storage. It stores the data as linked
// lists inside the storage.
//
// Internally, it uses synchronous 1R1W SRAM to store the
// next pointers. The data store is stored externally to
// the module.
//
// Note: there is a one-cycle bubble if the FIFO is full
// before new data will be accepted.
//
// The analysis of the multi-fifo versus a multiple FIFOs is
// interesting. Unquestionably, multiple independent FIFOs have
// more bandwidth. And the multi-FIFO has the area/power overhead of the 
// pointer SRAM because it stores the data as multiple linked lists.
//
// One example where the multi-FIFO could be useful is where you
// have a wide range in the occupancy of the FIFOs. 

`include "bsg_defines.sv"

// helper module
module bsg_fifo_1r1w_multi_fifo_head
  #(parameter `BSG_INV_PARAM(lg_total_els_lp))
   (input clk_i
    ,input reset_i

    ,input enque_i
    ,input [lg_total_els_lp-1:0] enque_addr_i

    ,output enque_addr_v_o
    ,output [lg_total_els_lp-1:0] enque_addr_o
    
    ,input deque_i

    // this is whether we should read from pointer storage
    ,output deque_addr_v_o 

    // this is the address to read from the fifo storage
    // and if applicable, the address to read from pointer storage
    ,output [lg_total_els_lp-1:0] deque_addr_o

    // coming back from memory
    ,input  [lg_total_els_lp-1:0] deque_data_i

    ,output v_o
    );

   logic [lg_total_els_lp-1:0] tail_r, head_r, head_r_bypass;
   logic 		       v_r, v_n;

   assign enque_addr_v_o = v_r & enque_i;
   assign enque_addr_o   = tail_r;
   
   assign v_o = v_r;

   wire equal = (tail_r == head_r_bypass);

   always_comb
     begin
	v_n = v_r;
	if (equal & deque_i) v_n = 1'b0; // singleton deque -> empty
	if (enque_i) v_n = 1'b1; // enq overrides
     end

   always_ff @(posedge clk_i)
     if (reset_i) v_r <= 1'b0;
     else         v_r <= v_n;
   
   always_ff @(posedge clk_i)
     if (reset_i)      tail_r <= '0;
     else if (enque_i) tail_r <= enque_addr_i;

   // only get next pointer if we have more than one element
   wire deque_addr_v_lo = deque_i & v_r & ~equal;
   assign deque_addr_v_o = deque_addr_v_lo;

   logic outstanding_read_r;
   
   always_ff @(posedge clk_i)
     begin
	if (reset_i) outstanding_read_r <= 1'b0;
	else         outstanding_read_r <= deque_addr_v_lo;
     end

   always_ff @(posedge clk_i)
     // if we have fresh meat
     if (reset_i) head_r <= '0;
     else if (enque_i & (~v_r | (equal & deque_i))) head_r <= enque_addr_i; // empt enq, singleton enq+deq: replace element
     else if (outstanding_read_r)                  head_r <= deque_data_i;

   assign head_r_bypass = outstanding_read_r ? deque_data_i : head_r;
	
   // need to bypass data coming in
   assign deque_addr_o = head_r_bypass;
   
endmodule

module bsg_fifo_1r1w_multi
  #(parameter `BSG_INV_PARAM(fifos_p)
    ,parameter `BSG_INV_PARAM(total_els_p)
    ,localparam lg_fifos_lp     = `BSG_SAFE_CLOG2(fifos_p)
    ,localparam lg_total_els_lp = `BSG_SAFE_CLOG2(total_els_p)
    )
   ( input  logic                   clk_i
     ,input  logic                   reset_i
     
     // Enqueue (r&v): payload RAM write happens externally at waddr_o on (v_i & ready_and_o)
     ,input  logic                   v_i
     ,input  logic [lg_fifos_lp-1:0] enq_id_i
     ,output logic                   ready_and_o
     
     // Dequeue: payload RAM read happens externally at raddr_o on yumi_i
     ,output logic [fifos_p-1:0]     v_o
     ,input  logic [lg_fifos_lp-1:0] deq_id_i
     ,input  logic                   yumi_i

     // to Data memory, external to module
     ,output logic [lg_total_els_lp-1:0] raddr_o // valid when yumi_i
     ,output logic [lg_total_els_lp-1:0] waddr_o // valid when v_i & ready_and_o
     );

   parameter debug_lp=1'b0;

`ifndef BSG_HIDE_FROM_SYNTHESIS
   if (debug_lp)
   always @(posedge clk_i)
     begin
	$display("%t deq(y=%d,id=%d) enq(r=%d,v=%d,id=%d) fifo(v_o=%b)",$time,yumi_i,deq_id_i,ready_and_o,v_i,enq_id_i,v_o);
     end
`endif
   
   wire alloc_v_lo;
   wire enq_fire = v_i & alloc_v_lo;
   assign ready_and_o = alloc_v_lo;

   logic [fifos_p-1:0] enq_id_one_hot, deq_id_one_hot;

   // one hot signals
   bsg_decode_with_v #(.num_out_p(fifos_p)) enq_dec
     (.i(enq_id_i), .v_i(enq_fire), .o(enq_id_one_hot));

   bsg_decode_with_v #(.num_out_p(fifos_p)) deq_dec
     (.i(deq_id_i), .v_i(yumi_i), .o(deq_id_one_hot));

   // ------------------ Shared ID pool ------------------
   logic [lg_total_els_lp-1:0] raddr_lo,dealloc_id_r; // address we are reading/dequeing
   logic [lg_total_els_lp-1:0] alloc_id_lo;

   logic 		       dealloc_v_r;
   
   // because deallocs are bypassed into allocation in this
   // variant of bsg_id_pool, we register these signals
   // to avoid read/write hazards in the data ram

   always_ff @(posedge clk_i)
     begin
	if (reset_i)
	  dealloc_v_r <= 1'b0;
	else
	  dealloc_v_r <= yumi_i;

	dealloc_id_r <= raddr_lo;
     end
   
   bsg_id_pool #(.els_p(total_els_p)) pool
     (.clk_i        (clk_i)
      ,.reset_i     (reset_i)
      ,.alloc_v_o   (alloc_v_lo)
      ,.alloc_id_o  (alloc_id_lo)
      ,.alloc_yumi_i(enq_fire)
      ,.dealloc_v_i (dealloc_v_r)
      ,.dealloc_id_i(dealloc_id_r)
      ,.empty_o()
      );
   
   genvar i;

   logic [fifos_p-1:0]                      fifo_enque_addr_v_lo, fifo_deque_addr_v_lo;
   logic [fifos_p-1:0][lg_total_els_lp-1:0] fifo_enque_addr_lo, fifo_deque_addr_lo;
   logic [lg_total_els_lp-1:0]              fifo_deque_data_li;
      
   for (i = 0; i < fifos_p; i++)
     begin: fifo
        bsg_fifo_1r1w_multi_fifo_head
	    #(.lg_total_els_lp(lg_total_els_lp))
        fifo
	    (.clk_i          (clk_i)
	     ,.reset_i       (reset_i)

	     ,.enque_i       (enq_id_one_hot[i])
	     ,.enque_addr_i  (alloc_id_lo) // broadcast parameter
	     
	     ,.enque_addr_v_o(fifo_enque_addr_v_lo[i])  
	     ,.enque_addr_o  (fifo_enque_addr_lo  [i])

	     ,.deque_i        (deq_id_one_hot[i])
	     
	     ,.deque_addr_v_o (fifo_deque_addr_v_lo[i])
	     ,.deque_addr_o   (fifo_deque_addr_lo  [i])

	     ,.deque_data_i   (fifo_deque_data_li)
	     ,.v_o            (v_o[i])
	     );
     end

   // we want the outside user to write their data into
   // the newly allocated memory location
   assign waddr_o = alloc_id_lo;

   logic [lg_total_els_lp-1:0] waddr_lo, output_raddr_lo;

   bsg_mux_one_hot #(.width_p(lg_total_els_lp),.els_p(fifos_p)) m_raddr_out
     (.sel_one_hot_i(deq_id_one_hot)
      ,.data_i      (fifo_deque_addr_lo)
      ,.data_o      (output_raddr_lo)
      );

   // the user will read data from the target of the pointer
   // and we will read the next pointer at the target of the pointer as well
   assign raddr_o = output_raddr_lo;
	      
/* 
   // this will have the effect of zero-ing out the address if no input
   // is valid, but when an input is valid, it will have the same effect
   // as the previous bsg_mux_one_hot. For this reason, we save the logic
 
    bsg_mux_one_hot #(.width_p(lg_total_els_lp),.els_p(fifos_p)) m_raddr
     (.sel_one_hot_i(fifo_deque_addr_v_lo)
      ,.data_i      (fifo_deque_addr_lo)
      ,.data_o      (raddr_lo)
      );
  */
	     
   assign raddr_lo = output_raddr_lo;
	      
   // gather the location of the pointer we need to update on enque
   bsg_mux_one_hot #(.width_p(lg_total_els_lp),.els_p(fifos_p)) m_waddr
     (.sel_one_hot_i(fifo_enque_addr_v_lo)
      ,.data_i      (fifo_enque_addr_lo)
      ,.data_o      (waddr_lo)
      );

   wire w_li = |fifo_enque_addr_v_lo;
   wire r_li = |fifo_deque_addr_v_lo;
   
   bsg_mem_1r1w_sync
     #(.width_p(lg_total_els_lp)
       ,.els_p (total_els_p)
       ,.read_write_same_addr_p(0)
       )
   next_mem
     (.clk_i   (clk_i)
      ,.reset_i(reset_i)

      ,.w_v_i   (w_li)
      ,.w_addr_i(waddr_lo)
      ,.w_data_i(alloc_id_lo)

      // don't try to read if we are bypassing
      ,.r_v_i   (r_li)
      ,.r_addr_i(raddr_lo)
      ,.r_data_o(fifo_deque_data_li) // back to fifos
      );

`ifndef BSG_HIDE_FROM_SYNTHESIS
   always_ff @(posedge clk_i) 
     if (reset_i === 1'b0) 
       begin
          // these should be one-hot or zero-hot
	  assert ($onehot0(fifo_enque_addr_v_lo)) else $error("%m: enq link valids not onehot0");
	  assert ($onehot0(fifo_deque_addr_v_lo)) else $error("%m: deq read valids not onehot0");

          // No same-address R/W in pointer SRAM:
          // if both valids can be 1, addresses must differ
          if (w_li & r_li)
	    assert (waddr_lo != raddr_lo)
	      else $error("%m: pointer SRAM same-address R+W in one cycle");

	  // alloc_v_lo == ready_and_o, avoiding inout warning in sim
	  if (v_i & alloc_v_lo & yumi_i)
            assert (waddr_o != raddr_o)
	      else $error("%m: payload RAM same-address R+W in one cycle");
	end
`endif
   
endmodule // bsg_fifo_1r1w_multi


