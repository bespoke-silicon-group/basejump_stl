// MBT
//
// 10/27/14
//
// implements a circular pointer that
// can be incremented by at most max_add_p
// and points to slots_p slots.
//

module bsg_circular_ptr #(parameter slots_p     = -1
                          , parameter max_add_p = -1
                          // local param
                          , parameter ptr_width_lp = `BSG_SAFE_CLOG2(slots_p))
   (input clk
    , input reset_i
    , input  [$clog2(max_add_p+1)-1:0] add_i
    , output [ptr_width_lp-1:0] o
    );

   logic [ptr_width_lp-1:0] ptr_r, ptr_n;
   logic [ptr_width_lp:0]   ptr_wrap;

   assign o = ptr_r;

   // increment round robin pointers
   always @(posedge clk)
     if (reset_i) ptr_r <= 0;
     else       ptr_r <= ptr_n;

   if (slots_p == 1)
     begin
	assign ptr_n = 1'b0;
	wire ignore = |add_i;
     end
   else
     if (`BSG_IS_POW2(slots_p))
       assign  ptr_n = ptr_width_lp ' (ptr_r + add_i);
     else
       begin: notpow2
          always_comb
            begin
               // compute wrapped and non-wrap cases
               // in parallel

               ptr_wrap = { 1'b0, ptr_r } - slots_p + add_i;
               ptr_n = ptr_r + add_i;

               // if (ptr_r + add_i - slots_p >= 0)
               // then we have wrapped around

               if  (~ptr_wrap[ptr_width_lp])
                 ptr_n = ptr_wrap[0+:ptr_width_lp];

	       // synopsys translate_off
               assert( (ptr_n < slots_p) || (|ptr_n === 'X) || reset_i || (add_i > slots_p))
                 else $error("bsg_circular_ptr counter overflow (ptr_r=%b/add_i=%b/ptr_wrap=%b/ptr_n=%b)",ptr_r,add_i,ptr_wrap,ptr_n, slots_p);
	       // synopsys translate_on
            end
        end
endmodule // bsg_circular_ptr
