// 1 read port, 1 write port memory implemented using two single port (1rw) memories
//
// reads are synchronous

`include "bsg_defines.sv"

module bsg_mem_1r1w_sync_from_1rw_sync #(parameter width_p=-1
                                        ,parameter els_p=-1
                                        ,parameter read_write_same_addr_p=0
                                        ,parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                                        ,parameter harden_p=0
                                        ,parameter disable_collision_warning_p=1
                                        ,parameter enable_clock_gating_p=0
                                        )
  (input clk_i
  ,input reset_i
  ,input                                        w_v_i
  ,input [addr_width_lp-1:0]                    w_addr_i
  ,input [`BSG_SAFE_MINUS(width_p, 1):0]        w_data_i
  ,input                                        r_v_i
  ,input [addr_width_lp-1:0]                    r_addr_i
  ,output logic [`BSG_SAFE_MINUS(width_p, 1):0] r_data_o
  );

  logic [els_p-1:0] v_r;
  logic [els_p-1:0] set, clear;
  logic [els_p-1:0] w_addr_one_hot_lo;
  logic mem_select_r;

  bsg_decode_with_v
    #(.num_out_p(els_p))
    addr_decoder
    (.i(w_addr_i)
    ,.v_i(w_v_i)
    ,.o(w_addr_one_hot_lo)
    );

  // Use r_v_i as well to account for cases when r_addr_i is undefined/invalid
  wire wr_ptr = ~r_v_i | ~v_r[r_addr_i];
  assign set   = {els_p { wr_ptr  & w_v_i}} & w_addr_one_hot_lo;
  assign clear = {els_p {~wr_ptr  & w_v_i}} & w_addr_one_hot_lo;

  bsg_dff_reset_set_clear
    #(.width_p(els_p))
    valid_reg
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.set_i(set)
    ,.clear_i(clear)
    ,.data_o(v_r)
    );

  bsg_dff
    #(.width_p(1))
    mem_select_reg
    (.clk_i(clk_i)
    ,.data_i(v_r[r_addr_i])
    ,.data_o(mem_select_r)
    );

  wire [1:0] w_li    = {w_v_i &  wr_ptr,
                        w_v_i & ~wr_ptr};
  wire [1:0] r_li    = {(r_v_i &  v_r[r_addr_i]),
                        (r_v_i & ~v_r[r_addr_i])};
  wire [1:0] v_li    = w_li | r_li;
  wire [1:0][addr_width_lp-1:0] addr_li =
                          {w_li[1] ? w_addr_i : r_addr_i,
                           w_li[0] ? w_addr_i : r_addr_i};
  logic [1:0][width_p-1:0] data_lo;
  assign r_data_o    = mem_select_r ? data_lo[1] : data_lo[0];

   bsg_mem_1rw_sync
    #(.width_p(width_p)
     ,.els_p(els_p)
     ,.enable_clock_gating_p(enable_clock_gating_p)
     ) 
    mem0
     (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(w_data_i)
     ,.addr_i(addr_li[0])
     ,.v_i(v_li[0])
     ,.w_i(w_li[0])
     ,.data_o(data_lo[0])
     );

   bsg_mem_1rw_sync
    #(.width_p(width_p)
     ,.els_p(els_p)
     ,.enable_clock_gating_p(enable_clock_gating_p)
     )
    mem1
     (.clk_i(clk_i)
     ,.reset_i(reset_i)
     ,.data_i(w_data_i)
     ,.addr_i(addr_li[1])
     ,.v_i(v_li[1])
     ,.w_i(w_li[1])
     ,.data_o(data_lo[1])
     );

   //synopsys translate_off
   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d, harden_p=%d (%m)",width_p,els_p,read_write_same_addr_p,harden_p);
     end

   always_ff @(posedge clk_i)
     if (w_v_i)
       begin
          assert ((reset_i === 'X) || (reset_i === 1'b1) || (w_addr_i < els_p))
            else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

          assert ((reset_i === 'X) || (reset_i === 1'b1) || ~(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p && !disable_collision_warning_p))
            else
              begin
                 $error("X'ing matched read address %x (%m)",r_addr_i);
              end
       end
   //synopsys translate_on

endmodule

