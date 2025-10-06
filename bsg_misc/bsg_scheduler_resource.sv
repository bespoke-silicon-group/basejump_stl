// =============================================================
// bsg_scheduler_resource (SRAM-less)
// =============================================================
// Overview
// --------
// A level-sensitive, multi-resource scheduler built from BaseJump STL blocks:
// * bsg_id_pool_dealloc_alloc_one_hot : manages free/active entry IDs
// * bsg_arb_round_robin               : fairish/starvation free selection among ready entries
//
// Each entry chooses one bit (index) from each resource’s availability bitmap.
// An entry is ready when all chosen bits are 1. Ready entries are arbitrated
// in round-robin order. The module exposes just IDs; the parent manages payload SRAM.
//
// Why not bsg_scheduler_dataflow?
// -------------------------------
// bsg_scheduler_dataflow uses event/tag wakeups (edge-like) rather than level
// readiness across multiple resources. Converting level bitmaps into wakeup
// streams would require extra glue logic and state; this module keeps a simple
// AND-of-bits model.
//
//
// Suggested interface (SRAM-less)
// -------------------------------
//   - Allocate:  alloc_v_i, alloc_sel_i[r], alloc_id_v_o, alloc_id_o
//   - Resources: res_avail_i[r][max_dep_bits_p]
//   - Dequeue :  deq_v_o, deq_id_o, deq_yumi_i
//
// Integration pattern
// -------------------
//   // On allocate (when alloc_id_v_o):
//   payload_mem[alloc_id_o] <= payload_in;
//
//   // On dequeue (when deq_yumi_i):
//   payload_out <= payload_mem[deq_id_o];
//   // (and perform side effects; ID is auto-freed by the scheduler)
//
// Parameter notes
// ---------------
//   resources_p     : number of independent resources to AND across
//   els_p           : maximum concurrent entries tracked
//   max_dep_bits_p  : width of each resource’s availability bitmap
//   idx_width_lp    : clog2(max_dep_bits_p)
//   id_width_lp     : clog2(els_p)
//
// Reset/X-safety
// --------------
// sel_idx_r is only observed when active_ids_r[i] is 1; we do not clear on
// dealloc or reset (optional). This reduces reset fanout and surge power. The
// readiness logic guards variable indexing with active_ids_r to avoid X-prop.

`include "bsg_defines.sv"

module bsg_scheduler_resource
  // resources_p : number of independent level-sensitive resources
  // els_p       : max number of in-flight entries
  // max_dep_bits_p : width of each resource availability bitmap
  #(parameter `BSG_INV_PARAM(resources_p)
    ,parameter `BSG_INV_PARAM(els_p)
    ,parameter `BSG_INV_PARAM(max_dep_bits_p)
    ,parameter output_res_p=1
    ,localparam dep_width_p = `BSG_SAFE_CLOG2(max_dep_bits_p)
    ,localparam id_width_lp  = `BSG_SAFE_CLOG2(els_p)
    )
   ( input  clk_i
     , input  reset_i

     // ---------- Resource availability (level sensitive) ----------
     , input  [resources_p-1:0][max_dep_bits_p-1:0] res_avail_i

     // ---------- Allocate (enqueue) ----------
     , input                                     alloc_v_i
     , input  [resources_p-1:0][dep_width_p-1:0] alloc_sel_i // per-resource dependency indices

     , output logic                       alloc_yumi_o        // an ID has been allocated this cycle;
	                                                      // is also a kind of yumi
     , output logic [id_width_lp-1:0]     alloc_id_o          // allocated ID (binary)

     // ---------- Dequeue (issue/dispatch) ----------
     , output logic                                    deq_v_o    // at least one entry ready
     , output logic [id_width_lp-1:0]                  deq_id_o   // encoded selected entry ID (binary)
     , output logic [resources_p-1:0][dep_width_p-1:0] deq_res_o  // resources used by selected ID
     , input                                           deq_yumi_i // consumer accepts selected entry
     );

   // ----------------------------------------------------------------
   // ID pool (manage active entries)
   // ----------------------------------------------------------------
   logic [els_p-1:0] active_ids_r;
   logic [els_p-1:0] alloc_id_one_hot_lo;
   logic             alloc_id_v_lo;

   logic [els_p-1:0] grants_one_hot;

   // user wants to allocate, and id pool has something available to allocate
   wire wr_entry = alloc_v_i & alloc_id_v_lo;
   assign alloc_yumi_o = wr_entry;

   
  bsg_id_pool_dealloc_alloc_one_hot #(.els_p(els_p)) idpool
    ( .clk_i               (clk_i)
      ,.reset_i            (reset_i)
      ,.active_ids_r_o     (active_ids_r)

      ,.alloc_id_v_o       (alloc_id_v_lo)
      ,.alloc_id_one_hot_o (alloc_id_one_hot_lo)

      ,.alloc_yumi_i       (wr_entry)
      ,.dealloc_ids_i      ( { els_p { deq_yumi_i } } & grants_one_hot )
  );

   // One-hot → binary for write row; also provide externally as alloc_id_o
   bsg_encode_one_hot #(.width_p(els_p)) enc_alloc_id
     ( .i(alloc_id_one_hot_lo)
       ,.addr_o(alloc_id_o)
       ,.v_o()
       );


   // ----------------------------------------------------------------
   // Compact per-entry dependency indices
   // ----------------------------------------------------------------
   logic [els_p-1:0][resources_p-1:0][dep_width_p-1:0] sel_idx_r;

   genvar i, r;

   for (i = 0; i < els_p; i++) 
     begin : el
       for (r = 0; r < resources_p; r++) 
         begin : res
           always_ff @(posedge clk_i) 
             begin
               if (wr_entry && alloc_id_one_hot_lo[i]) 
                 sel_idx_r[i][r] <= alloc_sel_i[r];
	          end
         end
     end

   // ----------------------------------------------------------------
   // Ready calculation (level-sensitive across resources)
   // ----------------------------------------------------------------
   logic [els_p-1:0] entry_ready;

   for (i = 0; i < els_p; i++) 
     begin : gen_ready
	     logic [resources_p-1:0] per_res_ok;
       for (r = 0; r < resources_p; r++) 
         begin : gen_per_res_ok
           // Guard indexing to avoid X-prop on inactive rows
           assign per_res_ok[r] = active_ids_r[i]
               ? res_avail_i[r][ sel_idx_r[i][r] ]
               : 1'b0;
         end
        assign entry_ready[i] = active_ids_r[i] & (&per_res_ok);
     end

   // ----------------------------------------------------------------
   // Round-robin arbitration
   // ----------------------------------------------------------------

   bsg_arb_round_robin #(.width_p(els_p)) rr
     ( .clk_i    (clk_i)
       ,.reset_i (reset_i)
       ,.reqs_i  (entry_ready)
       ,.grants_o(grants_one_hot)
       ,.yumi_i  (deq_yumi_i)
     );

   if (output_res_p)
     begin : res
	bsg_mux_one_hot #(.width_p(resources_p*dep_width_p)
			  ,.els_p(els_p)
			  ) mux1h
	  (.data_i(sel_idx_r)
	   ,.sel_one_hot_i(grants_one_hot)
	   ,.data_o(deq_res_o)
	   );
     end
   else
     begin : nores
        assign deq_res_o = '0;
     end
   
   assign deq_v_o = |entry_ready;
   
   // deq_id_o is the selected entry ID
   bsg_encode_one_hot #(.width_p(els_p)) enc_grant
     (.i(grants_one_hot)
      ,.addr_o(deq_id_o)
      ,.v_o() );

endmodule

