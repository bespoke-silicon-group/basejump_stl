// MBT 11/9/2014
// DWP 5/9/2020
//
// 1 read-port, 1 write-port ram with a onehot address scheme
//
// reads are asynchronous
//

module bsg_mem_1r1w_one_hot #(parameter width_p=-1
                            , parameter els_p=-1
                            , parameter read_write_same_addr_p=0
                            )
   (input   w_clk_i
    , input w_reset_i

    , input                      w_v_i
    , input [els_p-1:0]          w_addr_i
    , input [width_p-1:0]        w_data_i

    // currently unused
    , input                      r_v_i
    , input [els_p-1:0]          r_addr_i
    , output logic [width_p-1:0] r_data_o
    );

  logic [els_p-1:0][width_p-1:0] mem;

  wire unused0 = w_reset_i;
  wire unused1 = r_v_i;

  always_ff @(posedge w_clk_i)
    begin
      for (integer i = 0; i < els_p; i++)
        if (w_v_i & w_addr_i[i])
          mem[i] <= w_data_i;
    end

  bsg_mux_one_hot
   #(.width_p(width_p)
     ,.els_p(els_p)
     )
   one_hot_sel
    (.data_i(mem)
     ,.sel_one_hot_i(r_addr_i)
     ,.data_o(r_data_o)
     );

   //synopsys translate_off

   initial
     begin
	if (read_write_same_addr_p || (width_p*els_p >= 64))
          $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d (%m)"
                   ,width_p,els_p,read_write_same_addr_p);
     end

   always_ff @(negedge w_clk_i)
     if (w_v_i===1'b1)
       begin
          assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || $countones(w_addr_i) <= 1)
            else $error("Invalid write address %b to %m is not onehot (w_reset_i=%b, w_v_i=%b)\n", w_addr_i, w_reset_i, w_v_i);
          assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || $countones(r_addr_i) <= 1)
            else $error("Invalid read address %b to %m is not onehot (w_reset_i=%b, w_v_i=%b)\n", r_addr_i, w_reset_i, r_v_i);
          assert ((w_reset_i === 'X) || (w_reset_i === 1'b1) || !(r_addr_i == w_addr_i && w_v_i && r_v_i && !read_write_same_addr_p))
            else $error("%m: Attempt to read and write same address %x (w_v_i = %b, w_reset_i = %b)",w_addr_i,w_v_i,w_reset_i);
       end

   //synopsys translate_on

endmodule
