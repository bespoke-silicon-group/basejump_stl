// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//
// NOTE: Users of BaseJump STL should not instantiate this module directly
// they should use bsg_mem_1rw_sync.

module bsg_mem_1rw_sync_synth #(parameter width_p=-1
				, parameter els_p=-1
				, parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                                , parameter debug_p =0
                               )
   (input   clk_i
	 	, input v_i
		, input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input w_i
    , output logic [width_p-1:0]  data_o
    );

   wire unused = reset_i;

   logic [width_p-1:0]    mem [els_p-1:0];

   always_ff @(posedge clk_i)
     if (v_i)
       begin
          // synopsys translate_off
          assert ( (v_i !== 1'b1) || (reset_i === 'X) || (reset_i === 1'b1) || (addr_i < els_p))
            else $error("Invalid address %x to %m of size %x (reset_i = %b, v_i = %b, clk_i = %b)\n", addr_i, els_p, reset_i, v_i, clk_i);
          // synopsys translate_on
          if (w_i)
            mem[addr_i] <= data_i;
          else
            data_o      <= mem[addr_i];
       end


   // synopsys translate_off
   if (debug_p ) begin
   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d (%m)",width_p,els_p);
     end
   end

   // synopsys translate_on

endmodule
