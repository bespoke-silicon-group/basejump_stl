//
// 2 read-port, 1 write-port ram
//
// reads are synchronous
//
//

module bsg_mem_2r1w_sync #(parameter width_p=-1
                           , parameter els_p=-1
                           , parameter read_write_same_addr_p=0
                           , parameter addr_width_lp=`BSG_SAFE_CLOG2(els_p)
                           , parameter harden_p=0
                           )
   (input   clk_i
    , input reset_i

    , input                     w_v_i
    , input [addr_width_lp-1:0] w_addr_i
    , input [width_p-1:0]       w_data_i

    // currently unused
    , input                      r0_v_i
    , input [addr_width_lp-1:0]  r0_addr_i
    , output logic [width_p-1:0] r0_data_o

    , input                      r1_v_i
    , input [addr_width_lp-1:0]  r1_addr_i
    , output logic [width_p-1:0] r1_data_o
    );

   wire                   unused = reset_i;

   if ((width_p == 32) && (els_p == 32))
     begin: macro

        tsmc16_2rf_lg5_w32_all mem0
          (
           // read port
           .CLKA (clk_i)
           ,.AA  (r0_addr_i)
           ,.CENA(~r0_v_i)

           // output
           ,.QA  (r0_data_o)

           // write port
           ,.CLKB(clk_i)
           ,.AB  (w_addr_i)
           ,.DB  (w_data_i)
           ,.CENB(~w_v_i)

           ,.STOV (1'd0  ) // Self-timing Override - disabled
           ,.EMAA (3'd3  ) // Extra Margin Adjustment - default value
           ,.EMAB (3'd3  ) // Extra Margin Adjustment - default value
           ,.EMASA(1'd1  ) // Extra Margin Adjustment Sense Amp. - default value
           ,.RET1N(1'b1  ) // Retention Mode (active low) - disabled
           );

        tsmc16_2rf_lg5_w32_all mem1
          (
           .CLKA (clk_i)
           ,.AA  (r1_addr_i)
           ,.CENA(~r1_v_i)

           // output
           ,.QA  (r1_data_o)

           // write port
           ,.CLKB(clk_i)
           ,.AB  (w_addr_i)
           ,.DB  (w_data_i)
           ,.CENB(~w_v_i)

           ,.STOV (1'd0  ) // Self-timing Override - disabled
           ,.EMAA (3'd3  ) // Extra Margin Adjustment - default value
           ,.EMAB (3'd3  ) // Extra Margin Adjustment - default value
           ,.EMASA(1'd1  ) // Extra Margin Adjustment Sense Amp. - default value
           ,.RET1N(1'b1  ) // Retention Mode (active low) - disabled
           );

     end // block: macro
   else
     begin: notmacro

	bsg_mem_2r1w_sync_synth
	  #(.width_p(width_p)
	    ,.els_p(els_p)
	    ,.read_write_same_addr_p(read_write_same_addr_p)
	    ,.harden_p(harden_p)
	    ) synth
	    (.*);
     end


//synopsys translate_off

   always_ff @(posedge clk_i)
     if (w_v_i)
       begin
          assert (w_addr_i < els_p)
            else $error("Invalid address %x to %m of size %x\n", w_addr_i, els_p);

          assert (~(r0_addr_i == w_addr_i && w_v_i && r0_v_i && !read_write_same_addr_p))
            else $error("%m: port 0 Attempt to read and write same address");

          assert (~(r1_addr_i == w_addr_i && w_v_i && r1_v_i && !read_write_same_addr_p))
            else $error("%m: port 1 Attempt to read and write same address");
       end

   initial
     begin
        $display("## %L: instantiating width_p=%d, els_p=%d, read_write_same_addr_p=%d, harden_p=%d (%m)"
		 ,width_p,els_p,read_write_same_addr_p,harden_p);
     end

//synopsys translate_on

   

endmodule
