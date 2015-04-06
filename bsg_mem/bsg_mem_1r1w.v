// MBT 11/9/2014
//
// 1 read-port, 1 write-port ram
//
// reads are asynchronous
//

module bsg_mem_1r1w #(parameter width_p=-1
                      , parameter els_p=-1
                      , parameter read_write_same_addr_p=0
                      , parameter addr_width_lp=$clog2(els_p)
                      )
   (input   w_clk_i
    , input w_reset_i

    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i

    // currently unused
    , input                      r_v_i
    , input [addr_width_lp-1:0]  r_addr_i

    , output logic [width_p-1:0] r_data_o
    );

   logic [width_p-1:0]    mem [els_p-1:0];

   // this implementation ignores the r_v_i
   assign r_data_o = mem[r_addr_i];

   always_ff @(posedge w_clk_i)
     if (w_v_i)
       begin
          assert (w_addr_i < els_p)
            else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

          assert (~(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p))
            else $error("%m: Attempt to read and write same address");

          mem[w_addr_i] <= w_data_i;
       end

endmodule
