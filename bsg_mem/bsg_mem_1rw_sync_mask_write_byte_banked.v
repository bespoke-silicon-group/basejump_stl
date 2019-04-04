/**
 * bsg_mem_banked
 * 
 * The bank is selected from the LSB.
 */
module bsg_mem_1rw_sync_mask_write_byte_banked
  #(parameter  banks_p      =  "inv"
    ,parameter els_p        =  "inv"
    ,parameter data_width_p =  "inv"
    ,parameter enable_clock_gating_p = 0
    ,parameter addr_width_lp        = `BSG_SAFE_CLOG2(els_p)    
    ,parameter write_mask_width_lp  = data_width_p>>3
    ,parameter lg_banks_lp 	    = `BSG_SAFE_CLOG2(banks_p) 
    ,parameter bank_els_lp          = els_p >> lg_banks_lp
   )
   (input                         clk_i
   ,input                         reset_i

   ,input                         v_i
   ,input                         w_i

   ,input [addr_width_lp-1:0]       addr_i
   ,input [data_width_p-1:0]        data_i
   ,input [write_mask_width_lp-1:0] write_mask_i

   ,output [data_width_p-1:0] data_o
   );
  
  // synopsys translate_off
  initial
    begin
        $display("## %L: instantiating data_width_p=%d, els_p=%d (%m)",data_width_p,els_p);
    end
  // synopsys translate_on
  
  if (banks_p == 1)
    begin
      bsg_mem_1rw_sync_mask_write_byte
  	#(.data_width_p         ( data_width_p )
  	  ,.els_p               ( els_p )
  	  )
      mem_bank
  	(.*);      
    end
  else 
    begin  
      /* data outputs for each bank */
      wire [data_width_p-1:0] bank_data_lo [banks_p-1:0];
      /* selects which bank drives data_o */
      wire [lg_banks_lp-1:0] bank_data_sel_lo;
      /* selects which bank to address */
      wire [lg_banks_lp-1:0]  bank_sel_li  = addr_i[lg_banks_lp-1:0];

       bsg_dff_en
	 #(.width_p(lg_banks_lp))
       bank_data_sel_r
	 ( .clk_i   ( clk_i )
	   ,.data_i ( bank_sel_li )
	   ,.en_i   ( (v_i == 1'b1) && (w_i == 1'b0) )
	   ,.data_o ( bank_data_sel_lo ));

      /* generate memory for each bank */
      genvar b;
      for (b = 0; b < banks_p; b++)
  	begin: genbanks
  	  bsg_mem_1rw_sync_mask_write_byte 
  	       #(.data_width_p        ( data_width_p )
  		 ,.els_p               ( bank_els_lp )
		 ,.enable_clock_gating_p ( enable_clock_gating_p )
  		 )
  	  mem_bank
  	       (.clk_i         (  clk_i  )
  		,.reset_i      (  reset_i  )
  		,.v_i          (  v_i  && (bank_sel_li == b)  )
  		,.w_i          (  w_i  && (bank_sel_li == b)  )
  		,.addr_i       (  addr_i[addr_width_lp-1:lg_banks_lp]  )
  		,.data_i       (  data_i  )
  		,.write_mask_i (  write_mask_i  )
  		,.data_o       (  bank_data_lo[b]  ));
  	end // for (b = 0; b < banks_p; b++)
  
      assign data_o  = bank_data_lo[bank_data_sel_lo];
  
  end // else: !if(banks_p == 1)
  //   
endmodule // bsg_mem_banked
