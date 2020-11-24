// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//

module bsg_mem_1rw_sync #(parameter width_p=-1
                         ,parameter els_p=-1
                         ,parameter latch_last_read_p=0
                         ,parameter addr_width_lp=$clog2(els_p)
                         ,parameter harden_p=1
                         )
  (input                      clk_i
  ,input                      reset_i
  ,input [width_p-1:0]        data_i
  ,input [addr_width_lp-1:0]  addr_i
  ,input                      v_i
  ,input                      w_i
  ,output logic [width_p-1:0] data_o
  );

  bsg_mem_1rw_sync_mask_write_bit
   #(.width_p(width_p)
    ,.els_p(els_p)
    ,.latch_last_read_p(latch_last_read_p)
    ,.harden_p(harden_p)
    )
   mem
    (.clk_i(clk_i)
    ,.reset_i(reset_i)
    ,.v_i(v_i)
    ,.w_i(w_i)
    ,.addr_i(addr_i)
    ,.data_i(data_i)
    ,.w_mask_i('1)
    ,.data_o(data_o)
    );

  // synopsys translate_off
  initial
    begin
      $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
    end
  // synopsys translate_on

endmodule
