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
                           // add a parameter to switch between implementations of hard and soft macro
                           , parameter substitute_2r1w_p=0
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

   if (substitute_2r1w_p)
     begin: s2r1w
       logic [width_p-1:0] r0_data_lo, r1_data_lo;

       bsg_mem_2r1w #(.width_p(width_p)
                      ,.els_p(els_p)
                      ,.read_write_same_addr_p(0)
                      ) mem
         (.w_clk_i   (clk_i)
          ,.w_reset_i(reset_i)

          ,.w_v_i    (w_v_i & w_v_i)
          ,.w_addr_i (w_addr_i)
          ,.w_data_i (w_data_i)

          ,.r0_v_i   (r0_v_i & ~r0_v_i)
          ,.r0_addr_i(r0_addr_i)
          ,.r0_data_o(r0_data_lo)

          ,.r1_v_i   (r1_v_i & ~r1_v_i)
          ,.r1_addr_i(r1_addr_i)
          ,.r1_data_o(r1_data_lo)
          );

       // register output data to convert sync to async
       always_ff @(posedge clk_i) begin
         r0_data_o <= r0_data_lo;
         r1_data_o <= r1_data_lo;
       end
     end
   else
   if ((width_p == 32) && (els_p == 32))
     begin: macro
        // synopsys translate_off
        initial
          begin
             assert(read_write_same_addr_p==0)
               else
                 begin
                    $error("%L: this configuration does not permit simultaneous read and writes! (%m)");
                    $finish();
                 end
          end
        // synopsys translate_on

        // use two 1R1W rams to create
         tsmc40_2rf_lg5_w32_m2 mem0    
            (                                                   
             //write port
              .AA       ( w_addr_i      )
             ,.D        ( w_data_i      )
             ,.BWEB     ( 32'b0         )
             ,.WEB      ( ~w_v_i        )
             ,.CLKW     ( clk_i         )
             //read port                                                   
             ,.AB       ( r0_addr_i     )
             ,.REB      ( ~r0_v_i       )
             ,.CLKR     ( clk_i         )
             ,.Q        ( r0_data_o     )
                                                                
             ,.RDELAY   ( 2'b00         )
             ,.WDELAY   ( 2'b00         )
            );                                                  

         tsmc40_2rf_lg5_w32_m2 mem1    
            (                                                   
             //write port
              .AA       ( w_addr_i      )
             ,.D        ( w_data_i      )
             ,.BWEB     ( 32'b0         )
             ,.WEB      ( ~w_v_i        )
             ,.CLKW     ( clk_i         )
             //read port                                                   
             ,.AB       ( r1_addr_i     )
             ,.REB      ( ~r1_v_i       )
             ,.CLKR     ( clk_i         )
             ,.Q        ( r1_data_o     )
                                                                
             ,.RDELAY   ( 2'b00         )
             ,.WDELAY   ( 2'b00         )
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
