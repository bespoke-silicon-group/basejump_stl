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
          begin: nonsubst
             logic [width_p-1:0]    mem [els_p-1:0];

             always_ff @(posedge clk_i)
               if (v_i)
                 begin
                    assert (addr_i < els_p)
                      else $error("Invalid address %x to %m of size %x\n"
                                  , addr_i, els_p);
                    if (w_i)
                      mem[addr_i] <= data_i;
                    else
                      data_o      <= mem[addr_i];
                 end
          end // block: nonsubst
     end // block: z
   
endmodule
