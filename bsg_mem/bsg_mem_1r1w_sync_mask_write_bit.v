// MBT 7/7/2016
//
// 1 read-port, 1 write-port ram
//
// reads are synchronous

module bsg_mem_1r1w_sync_mask_write_bit #(parameter width_p=-1
                                        , parameter els_p=-1
                                        , parameter read_write_same_addr_p=0
                                        , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                                        , parameter harden_p=0
                                        )
   (input   clk_i
    , input reset_i

    , input                     w_v_i
    , input [width_p-1:0]       w_mask_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [width_p-1:0] r_data_o
    );

   logic [width_p-1:0]    mem [els_p-1:0];

   wire                   unused = reset_i;

   if (read_write_same_addr_p)
     begin

        logic [addr_width_lp-1:0] r_addr_r;

        always_ff @(posedge clk_i)
           if (r_v_i)
              r_addr_r <= r_addr_i;

        assign r_data_o = mem[r_addr_r];

        int i;
        always_ff @(posedge clk_i)
           for (i = 0; i < width_p; i=i+1)
              if (w_v_i && w_mask_i[i])
                 mem[w_addr_i][i] <= w_data_i[i];

     end
   else
     begin
        // this implementation ignores the r_v_i
        assign r_data_o = mem[r_addr_i];

        always_ff @(posedge clk_i)
          if (r_v_i)
            r_data_o <= mem[r_addr_i];

        int i;
        always_ff @(posedge clk_i)
           for (i = 0; i < width_p; i=i+1)
              if (w_v_i && w_mask_i[i])
                 mem[w_addr_i][i] <= w_data_i[i];

        //synopsys translate_off
        always_ff @(posedge clk_i)
          if (w_v_i)
            begin
               assert (w_addr_i < els_p)
                 else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

               assert (~(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p))
                 else $error("%m: Attempt to read and write same address");
            end
        //synopsys translate_on
     end

endmodule
