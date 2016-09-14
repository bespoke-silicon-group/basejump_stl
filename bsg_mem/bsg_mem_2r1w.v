// MBT 4/1/2014
//
// 2 read-port, 1 write-port ram
//
// reads are asynchronous
//

module bsg_mem_2r1w #(parameter width_p=-1
                      , parameter els_p=-1
                      , parameter read_write_same_addr_p=0
                      , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                      )
   (input   w_clk_i
    , input w_reset_i

    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i

    , input                      r0_v_i
    , input [addr_width_lp-1:0]  r0_addr_i
    , output logic [width_p-1:0] r0_data_o

    , input                      r1_v_i
    , input [addr_width_lp-1:0]  r1_addr_i
    , output logic [width_p-1:0] r1_data_o

    );

   logic [width_p-1:0]    mem [els_p-1:0];

   // this implementation ignores the r_v_i
   assign r1_data_o = mem[r1_addr_i];
   assign r0_data_o = mem[r0_addr_i];

   wire                   unused = w_reset_i;

   always_ff @(posedge w_clk_i)
     if (w_v_i)
       begin
//synopsys translate_off
          assert (w_addr_i < els_p)
            else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

          assert (~(r0_addr_i == w_addr_i && w_v_i && r0_v_i && !read_write_same_addr_p))
            else $error("%m: Attempt to read and write same address");

          assert (~(r1_addr_i == w_addr_i && w_v_i && r1_v_i && !read_write_same_addr_p))
            else $error("%m: Attempt to read and write same address");

//synopsys translate_on
          mem[w_addr_i] <= w_data_i;
       end

endmodule
