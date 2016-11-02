// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//

module bsg_mem_1rw_sync #(parameter width_p=-1
                          , parameter els_p=-1
                          , parameter addr_width_lp=$clog2(els_p)
                          // whether to substitute a 1r1w
                          , parameter substitute_1r1w_p=1)
   (input   clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input w_i
    , output logic [width_p-1:0]  data_o
    );

   if ((width_p == 32) & (els_p==2048))
     begin : macro
        bsg_tsmc_180_mem_1rw_lgEls_11_width_32_mux_8_mask_all mem
          (.Q(data_o)
           ,.CLK(clk_i)
           ,.CEN(~v_i)
           ,.WEN(~w_i)
           ,.A(addr_i)
           ,.D(data_i)
	   // 1=tristate
           ,.OEN(1'b0)
           );
     end // block: z
   else
   if ((width_p == 62) & (els_p==128))
       begin :macro
	  bsg_tsmc_180_mem_1rf_lgEls_7_width_62_mux_2_mask_all mem
	    (
	     .Q(data_o)
	     ,.CLK(clk_i)
	     ,.CEN(~v_i)
	     ,.WEN(~w_i)
	     ,.A(addr_i)
	     ,.D(data_i)
	     );
       end
   else
     begin : z
        // we substitute a 1r1w macro
        // fixme: theoretically there may be
        // a more efficient way to generate a 1rw synthesized ram
        if (substitute_1r1w_p)
          begin: s1r1w
             logic [width_p-1:0] data_lo;

             bsg_mem_1r1w #(.width_p(width_p)
                            ,.els_p(els_p)
                            ,.read_write_same_addr_p(0)
                            ) mem
               (.w_clk_i   (clk_i)
                ,.w_reset_i(reset_i)
                ,.w_v_i    (v_i & w_i)
                ,.w_addr_i (addr_i)
                ,.w_data_i (data_i)
                ,.r_addr_i (addr_i)
                ,.r_v_i    (v_i & ~w_i)
                ,.r_data_o (data_lo)
                );

             // register output data to convert sync to async
             always_ff @(posedge clk_i)
               data_o <= data_lo;
         end // block: subst
        else
          begin: notmacro
             logic [width_p-1:0]    mem [els_p-1:0];

             always_ff @(posedge clk_i)
               if (v_i)
                 begin

                    // synopsys translate_off

                    assert (addr_i < els_p)
                      else $error("Invalid address %x to %m of size %x\n"
                                  , addr_i, els_p);

                    // synopsys translate_on

                    if (w_i)
                      mem[addr_i] <= data_i;
                    else
                      data_o      <= mem[addr_i];
                 end
          end // block: nonsubst
     end // block: z

endmodule
