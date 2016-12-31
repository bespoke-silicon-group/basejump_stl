// STD 10-30-16
//
// Synchronous 1-port ram with byte masking
// Only one read or one write may be done per cycle.
//
module bsg_mem_1rw_sync_mask_write_byte

 #(parameter els_p = -1
  ,parameter data_width_p = -1
  ,parameter addr_width_lp = `BSG_SAFE_CLOG2(els_p)
  ,parameter write_mask_width_lp = data_width_p>>3
  )

  (input                           clk_i
  ,input                           reset_i

  ,input                           v_i
  ,input                           w_i

  ,input [addr_width_lp-1:0]       addr_i
  ,input [data_width_p-1:0]        data_i

  ,input [write_mask_width_lp-1:0] write_mask_i

  ,output [data_width_p-1:0] data_o
  );

  // TSMC 180 1024x32 Byte Mask
  if ((els_p == 1024) & (data_width_p == 32))
    begin : macro
      wire [3:0] wen = {~(w_i & write_mask_i[3])
                       ,~(w_i & write_mask_i[2])
                       ,~(w_i & write_mask_i[1])
                       ,~(w_i & write_mask_i[0])};
      tsmc180_1rw_lg10_w32_m8_byte mem
      (.Q   (data_o)
      ,.CLK (clk_i)
      ,.CEN (~v_i)
      ,.WEN (wen)
      ,.A   (addr_i)
      ,.D   (data_i)
       // 1=tristate output
      ,.OEN (1'b0)
      );
    end
  
  // no hardened version found
  else
    begin  : notmacro

       bsg_mem_1rw_sync_mask_write_byte_synth
	 #(.els_p(els_p), .data_width_p(data_width_p))
       synth (.*);

    end


  // synopsys translate_off

  always_comb
    assert (data_width_p % 8 == 0)
      else $error("data width should be a multiple of 8 for byte masking");

   initial
     begin
        $display("## bsg_mem_1rw_sync_mask_write_byte: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
     end

  // synopsys translate_on
   
endmodule
