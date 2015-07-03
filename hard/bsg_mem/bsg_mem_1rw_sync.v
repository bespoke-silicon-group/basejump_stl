// MBT 11/9/2014
//
// Synchronous 1-port ram.
// Only one read or one write may be done per cycle.
//

module bsg_mem_1rw_sync #(parameter width_p=-1
			  , parameter els_p=-1
			  , parameter addr_width_lp=$clog2(els_p))
   (input   clk_i
    , input reset_i
    , input [width_p-1:0] data_i
    , input [addr_width_lp-1:0] addr_i
    , input v_i
    , input w_i
    , output logic [width_p-1:0]  data_o
    );

   if ((width_p == 66) & (els_p==128))
     begin : z
	rGenSRAM_128x66 smem_128x66
	  (.CLK(clk_i)
	   ,.Q(data_o) // out
	   ,.CEN(~v_i) // lo true
	   ,.WEN(~w_i) // lo true
	   ,.A(addr_i) // in
	   ,.D(data_i) // in
	   );
     end
   else
     begin : z

	logic [width_p-1:0]    mem [els_p-1:0];
   
	always_ff @(posedge clk_i)
	  if (v_i)
	    begin
               assert (addr_i < els_p)
		 else $error("Invalid address %x to %m of size %x\n", addr_i, els_p);
               if (w_i)
		 mem[addr_i] <= data_i;
               else
		 data_o      <= mem[addr_i];
	    end
     end

endmodule
