//
// bsg_tag_client_unsync
//
// simple serial on-chip configuration network
//
// this client has only the shift register that captures data from the client
// no attempt is made to perform any synchronzation, or to hide intermediate toggles
// of bits as values are shifted in.
//
// generally speaking, this version should only be used in special cases:
//
// - where values are not intended to be updated on the fly as the chip runs;
//   i.e. configuration prior to reset
//
// - where receive logic has been explicitly coded separately
//
// 5/26/2018 MBT
//
//
// RESET SEMANTICS
//
// 1. Shift in the value you want to use.
// 2. Deassert reset on the receive side module.
//

`include "bsg_defines.v"

module bsg_tag_client_unsync
  import bsg_tag_pkg::bsg_tag_s;
   #(parameter width_p="inv", harden_p=1, debug_level_lp=0)
   (
    input 		 bsg_tag_s bsg_tag_i

    ,output [width_p-1:0] data_async_r_o
    );

   logic   op_r, param_r;

   always_ff @(posedge bsg_tag_i.clk)
     begin
        op_r    <= bsg_tag_i.op;
        param_r <= bsg_tag_i.param;
     end

   wire shift_op = op_r;
   wire no_op    = ~op_r & ~param_r;

   logic [width_p-1:0] tag_data_r, tag_data_n, tag_data_shift;

   // shift in new state
   if (width_p > 1)
     begin : fi
	assign tag_data_shift = { param_r, tag_data_r[width_p-1:1] };
     end
   else
     begin: fi
	assign tag_data_shift = param_r;
     end
	
   bsg_mux2_gatestack #(.width_p(width_p),.harden_p(harden_p)) tag_data_mux
     (.i0 (tag_data_r            ) // sel=0
      ,.i1(tag_data_shift        ) // sel=1
      ,.i2({ width_p {shift_op} }) // sel var
      ,.o (tag_data_n)
      );


   // Veri lator did not like bsg_dff_gatestack with the replicated clock signal
   // hopefully this replacement does not cause inordinate problems =)
   
   bsg_dff #(.width_p(width_p), .harden_p(harden_p)) tag_data_reg
	     (.clk_i(bsg_tag_i.clk)
	      ,.data_i(tag_data_n)
	      ,.data_o(tag_data_r)
	      );
	     
/*	     
   bsg_dff_gatestack #(.width_p(width_p),.harden_p(harden_p)) tag_data_reg
     (
      .i0 (tag_data_n                    )
      ,.i1( { width_p { bsg_tag_i.clk } })
      ,.o (tag_data_r                    )
      );
  */ 
   

   // synopsys translate_off
   if (debug_level_lp > 1)
     begin: debug
	wire reset_op = ~op_r & param_r;
	always @(negedge bsg_tag_i.clk)
	  begin
	     //if (reset_op)
	     //  $display("## bsg_tag_client RESET HI (%m)");
             if (reset_op & ~(~bsg_tag_i.op & bsg_tag_i.param))
               $display("## bsg_tag_client RESET DEASSERTED time %t (%m)",$time);
             if (~reset_op & (~bsg_tag_i.op & bsg_tag_i.param))
               $display("## bsg_tag_client RESET ASSERTED time   %t  (%m)",$time);
             if (shift_op)
               $display("## bsg_tag_client (send) SHIFTING  %b (%m)",tag_data_r);
	  end
     end
   // synopsys translate_on

   assign data_async_r_o = tag_data_r;

endmodule
