/*
 * Synchnronous read 1r1w content addressable memory module.
 * Each entry has a tag and a data associated with it
 * - Read searches the array for any data with r_tag_i
 * - Write allocates a new entry, replacing an existing entry with replacement
 *     scheme repl_scheme_p
 * - Write with w_nuke_i flag invalidates the cam
 */

`include "bsg_defines.v"

module bsg_cam_1r1w_sync
 #(parameter els_p                = "inv"
   , parameter tag_width_p        = "inv"
   , parameter data_width_p       = "inv"

   // The replacement scheme for the CAM
   , parameter repl_scheme_p = "lru"
   )
  (input                             clk_i
   , input                           reset_i

   // Synchronous write/invalidate of a tag
   , input                           w_v_i
   // When w_v_i & w_nuke_i, the whole cam array is invalidated
   , input                           w_nuke_i
   // Tag/data to set on write
   , input [tag_width_p-1:0]         w_tag_i
   , input [data_width_p-1:0]        w_data_i
   
   // Synchronous read of a tag, if exists
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

  // Read from asynchronous CAM
  bsg_cam_1r1w
   #(.els_p(els_p)
     ,.tag_width_p(tag_width_p)
     ,.data_width_p(data_width_p)
     ,.repl_scheme_p(repl_scheme_p)
     )
   cam
    (.clk_i(clk_i)
     ,.reset_i(reset_i)

     ,.w_v_i(w_v_i)
     ,.w_nuke_i(w_nuke_i)
     ,.w_tag_i(w_tag_i)
     ,.w_data_i(w_data_i)

     ,.r_v_i(r_v_r)
     ,.r_tag_i(r_tag_r)
     ,.r_data_o(r_data_o)
     ,.r_v_o(r_v_o)
     );

endmodule

