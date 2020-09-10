
//
// Maintains the replacement policy for an array of elements
// The scheme is synchronously updated when v_i goes high, and asynchronously
//   outputs the selected way for replacement based on internal and emptiness
//
// Currently supported schemes
//  LRU:
//  - Both alloc and read operations update LRU in parallel
//  - Allocation is performed logically before the read update
//  - If the read and alloc refer to the same set, all is well,
//       since the LRU update is idempotent.
`include "bsg_defines.v"

module bsg_cam_1r1w_replacement
 #(parameter els_p      = 2
   // Which replacement scheme to use
   , parameter scheme_p = "lru"
   )
  (input                       clk_i
   , input                     reset_i

   // Synchronous update (i.e. indicate that an entry was read)
   , input [els_p-1:0]         read_v_i

   // May use combination of internal state and empty vector
   //   to determine replacement
   // Synchronous update (i.e. indicate that an entry was allocated)
   , input                     alloc_v_i
   , input [els_p-1:0]         alloc_empty_i
   , output [els_p-1:0]        alloc_v_o
   );

  // Standard tree-based pseudo-lru
  if (scheme_p == "lru")
    begin : lru
      localparam lg_els_lp = `BSG_SAFE_CLOG2(els_p);

      wire read_v_li    = |read_v_i;
      wire lru_touch_li = read_v_li | alloc_v_i;

      // LRU storage
      logic [els_p-2:0] lru_n, lru_r;
      bsg_dff_reset_en
       #(.width_p(els_p-1))
       lru_reg
        (.clk_i(clk_i)
         ,.reset_i(reset_i)
         ,.en_i(lru_touch_li)

         ,.data_i(lru_n)
         ,.data_o(lru_r)
         );

      //
      // Selection output logic 
      //
      // Encode the one-hot way select based on LRU
      logic [lg_els_lp-1:0] lru_way_lo;
      bsg_lru_pseudo_tree_encode
       #(.ways_p(els_p))
       lru_encoder
        (.lru_i(lru_r)
         ,.way_id_o(lru_way_lo)
         );

      // Find an empty way if one exists
      logic [lg_els_lp-1:0] empty_way_lo;
      logic empty_way_v_lo;
      bsg_priority_encode
       #(.width_p(els_p), .lo_to_hi_p(1))
       empty_encoder
        (.i(alloc_empty_i)
         ,.addr_o(empty_way_lo)
         ,.v_o(empty_way_v_lo)
         );

      // Select the empty way if one exists; else, use LRU
      wire [lg_els_lp-1:0] way_lo = empty_way_v_lo ? empty_way_lo : lru_way_lo;

      // Output the one-hot way selected
      bsg_decode
       #(.num_out_p(els_p))
       way_decoder
        (.i(way_lo)
         ,.o(alloc_v_o)
         );

      //
      // LRU update logic
      //
      // Encode the one-hot way read inputs to this module
      logic [lg_els_lp-1:0] read_way_li;
      bsg_encode_one_hot
       #(.width_p(els_p))
       read_way_encoder
        (.i(read_v_i)
         ,.addr_o(read_way_li)
         ,.v_o()
         );

      // Decides which way to update based on read MRU
      logic [els_p-2:0] read_update_data_lo, read_update_mask_lo;
      bsg_lru_pseudo_tree_decode
       #(.ways_p(els_p))
       read_decoder
        (.way_id_i(read_way_li)
         ,.data_o(read_update_data_lo)
         ,.mask_o(read_update_mask_lo)
         );
       
      // Muxes in the update data to compute the next LRU state
      // This doesn't get latched in unless there's an active use
      logic [els_p-2:0] read_update_lo;
      wire [els_p-2:0] read_sel_lo = read_update_mask_lo & {(els_p-1){read_v_li}};
      bsg_mux_bitwise
       #(.width_p(els_p-1))
       read_update_mux
        (.data0_i(lru_r)
         ,.data1_i(read_update_data_lo)
         ,.sel_i(read_sel_lo)
         ,.data_o(read_update_lo)
         );

      // Decides which way to update based on write MRU
      logic [els_p-2:0] alloc_update_data_lo, alloc_update_mask_lo;
      bsg_lru_pseudo_tree_decode
       #(.ways_p(els_p))
       alloc_decoder
        (.way_id_i(way_lo)
         ,.data_o(alloc_update_data_lo)
         ,.mask_o(alloc_update_mask_lo)
         );

      logic [els_p-2:0] alloc_update_lo;
      wire [els_p-2:0] alloc_sel_lo = alloc_update_mask_lo & {(els_p-1){alloc_v_i}};
      bsg_mux_bitwise
       #(.width_p(els_p-1))
       alloc_update_mux
        (.data0_i(read_update_lo)
         ,.data1_i(alloc_update_data_lo)
         ,.sel_i(alloc_sel_lo)
         ,.data_o(alloc_update_lo)
         );

      assign lru_n = alloc_update_lo;
    end

  initial
    begin
      assert (scheme_p == "lru") else $error("Only LRU scheme is currently supported");
    end
  
endmodule

