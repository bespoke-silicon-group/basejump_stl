/*
 * Synchronous read 1r1w content addressable memory module.
 * Each entry has a tag and a data associated with it, and can be
 *   independently cleared and set
 *
 * This module is similar to bsg_cam_1r1w_sync, except it allows for an
 *   external replacement scheme
 */

`include "bsg_defines.sv"

module bsg_cam_1r1w_sync_unmanaged
 #(parameter `BSG_INV_PARAM(els_p)
   , parameter `BSG_INV_PARAM(tag_width_p)
   , parameter `BSG_INV_PARAM(data_width_p)

   , parameter safe_els_lp = `BSG_MAX(els_p,1)
   )
  (input                             clk_i
   , input                           reset_i

   // Synchronous write/invalidate of a tag
   // one or zero-hot
   , input [safe_els_lp-1:0]               w_v_i
   , input                           w_set_not_clear_i
   // Tag/data to set on write
   , input [tag_width_p-1:0]         w_tag_i
   , input [data_width_p-1:0]        w_data_i
   // Metadata useful for an external replacement policy
   // Whether there's an empty entry in the tag array
   , output [safe_els_lp-1:0]              w_empty_o
   
   // Asynchronous read of a tag, if exists
   , input                           r_v_i
   , input [tag_width_p-1:0]         r_tag_i

   , output logic [data_width_p-1:0] r_data_o
   , output logic                    r_v_o
  );

  // Latch the read request for a synchronous read
  logic [tag_width_p-1:0] r_tag_r;
  logic r_v_r;
  bsg_dff
   #(.width_p(1+tag_width_p))
   r_tag_reg
    (.clk_i(clk_i)

     ,.data_i({r_v_i, r_tag_i})
     ,.data_o({r_v_r, r_tag_r})
     );

  // Read from asynchronous unmanaged CAM
  bsg_cam_1r1w_unmanaged
   #(.els_p(safe_els_lp)
     ,.tag_width_p(tag_width_p)
     ,.data_width_p(data_width_p)
     )
   cam
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_set_not_clear_i(w_set_not_clear_i)
     ,.w_tag_i(w_tag_i)
     ,.w_data_i(w_data_i)
     ,.w_empty_o(w_empty_o)    

     ,.r_v_i(r_v_r)
     ,.r_tag_i(r_tag_r)
     ,.r_data_o(r_data_o)
     ,.r_v_o(r_v_o)
     );

endmodule

`BSG_ABSTRACT_MODULE(bsg_cam_1r1w_sync_unmanaged)
