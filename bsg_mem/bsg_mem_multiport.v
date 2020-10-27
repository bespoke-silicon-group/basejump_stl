// MBT 7/3/2016
//
// N read-port, M write-port ram
//
// reads are asynchronous
//
//

`include "bsg_defines.v"

module bsg_mem_multiport #(parameter width_p=-1
                           , parameter els_p=-1
                           , parameter read_write_same_addr_p =0
                           , parameter write_write_same_addr_p=0
                           , parameter read_ports_p  ="inv"
                           , parameter write_ports_p ="inv"
                           , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                           )
   (input   w_clk_i
    , input w_reset_i

    , input [write_ports_p-1:0]                    w_v_i
    , input [write_ports_p-1:0][addr_width_lp-1:0] w_addr_i
    , input [write_ports_p-1:0][width_p-1:0]       w_data_i

    , input [read_ports_p-1:0]                      r_v_i
    , input [read_ports_p-1:0][addr_width_lp-1:0]   r_addr_i
    , output [read_ports_p-1:0][width_p-1:0]        r_data_o
    );

   logic [width_p-1:0]    mem [els_p-1:0];

   // this implementation ignores the r_v_i
   genvar                 i,j;

   for (i = 0; i < read_ports_p; i=i+1)
     begin: rof_r
        assign r_data_o[i] = mem[r_addr_i[i]];
     end

   wire                   unused = w_reset_i;

   for (i = 0; i < write_ports_p; i=i+1)
     begin: rof_w
        always_ff @(posedge w_clk_i)
          begin
             if (w_v_i[i])
               mem[w_addr_i[i]] <= w_data_i[i];
          end

        always @(posedge w_clk_i)
          begin
             assert (w_addr_i[i] < els_p)
               else $error("Invalid address %x to %m of size %x\n", w_addr_i[i], els_p);
          end
     end

   for (i = 0; i < write_ports_p; i=i+1)
     begin: w2
        for (j = 0; j < read_ports_p; j=j+1)
          begin: r2
             always @(posedge w_clk_i)
               assert (~(w_addr_i[i] == r_addr_i[j] && w_v_i[i] && r_v_i[j] && !read_write_same_addr_p))
                 else $error("%m: Attempt to read and write same address");
          end
     end

   for (i = 0; i < write_ports_p; i=i+1)
     begin: w3
        for (j = i; j < write_ports_p; j=j+1)
          begin: w4
             always @(posedge w_clk_i)
               assert (~(w_addr_i[i] == w_addr_i[j] && w_v_i[i] && w_v_i[j] && !write_write_same_addr_p))
                 else $error("%m: Attempt to write same address twice");
          end
     end


   // synopsys translate_off
   initial
     begin
        $display("## bsg_mem_multiport: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d, write_write_same_addr_p=%d harden_p=%d (%m,%L)"
                 ,width_p,els_p,read_write_same_addr_p, write_write_same_addr_p,harden_p);
     end
   // synopsys translate_on

endmodule
