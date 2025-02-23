// Round robin arbitration unit
// NOTE: generally prefer https://github.com/bespoke-silicon-group/basejump_stl/blob/master/bsg_misc/bsg_arb_round_robin.sv to this module.
// Automatically generated using bsg_round_robin_arb.py
// DO NOT MODIFY

// this arbiter has a few usage scenarios which explains the somewhat complicated interface.
// Informal description of the interface:
// grants_en_i  - Whether to suppress grant_o signals and tag_o, which are computed based on reqs_i
// sel_one_hot_o- The selection signal after the arbitration.
// grant_o      - The grant signals that taking grant_en_i into consideration.
// v_o          - Whether any reqs_i signals were valid. computed without grants_en_i. 
// yumi_i       - Whether to advance "least priority" pointer to the selected item
//                in some typical use cases, grants_en_i comes from a downstream consumer to indicate readiness;
//                this can be used with v_o to implement ready/valid protocol at both producer (fed into yumi_i) and consumer

`include "bsg_defines.sv"


module bsg_round_robin_arb #(parameter `BSG_INV_PARAM(inputs_p)
                                     ,lg_inputs_p   =`BSG_SAFE_CLOG2(inputs_p)
                                     ,reset_on_sr_p = 1'b0
                                     ,hold_on_sr_p  = 1'b0
                                     // Hold on valid sets the arbitration policy such that once
                                     // a output tag is selected, it remains selected until it is
                                     // acked. This is consistent with BaseJump STL handshake
                                     // assumptions. Notably, this parameter is required to work
                                     // with bsg_parallel_in_serial_out_passthrough. This policy
                                     // has a slight throughput degradation but effectively
                                     // arbitrates based on age, so minimizes worst case latency.
                                     ,hold_on_valid_p = 1'b0)
    (input clk_i
    , input reset_i
    , input grants_en_i // whether to suppress grants_o

    // these are "third-party" inputs/outputs
    // that are part of the "data plane"

    , input  [inputs_p-1:0] reqs_i
    , output logic [inputs_p-1:0] grants_o
    , output logic [inputs_p-1:0] sel_one_hot_o

    // end third-party inputs/outputs

    , output v_o                           // if grants_en_i (i.e. ready_i) were set, would a grant signal be asserted? 
    , output logic [lg_inputs_p-1:0] tag_o // to which input the grant was given
    , input yumi_i                         // yes, go ahead with whatever grants_o proposed
    );

logic [lg_inputs_p-1:0] last, last_n, last_r;
logic hold_on_sr, reset_on_sr;



// synopsys translate_off
initial begin
assert (inputs_p <=  24 )
  else begin
    $error("[%m] Can not support inputs_p greater than  24 . You can regenerate bsg_round_robin_arb.sv with a greater input range.");
    $finish();
  end
end
// synopsys translate_on


if(inputs_p == 1)
begin: inputs_1

logic [1-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    2'b?_0: begin sel_one_hot_n = 1'b0; tag_o = (lg_inputs_p) ' (0); end // X
    2'b0_1: begin sel_one_hot_n= 1'b1; tag_o = (lg_inputs_p) ' (0); end
    default: begin sel_one_hot_n= {1{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {1{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           1'b0 : hold_on_sr = ( reqs_i == 1'b1 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_1 
    assign reset_on_sr = ( reqs_i == 1'b1 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_1

if(inputs_p == 2)
begin: inputs_2

logic [2-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    3'b?_00: begin sel_one_hot_n = 2'b00; tag_o = (lg_inputs_p) ' (0); end // X
    3'b0_1?: begin sel_one_hot_n= 2'b10; tag_o = (lg_inputs_p) ' (1); end
    3'b0_01: begin sel_one_hot_n= 2'b01; tag_o = (lg_inputs_p) ' (0); end
    3'b1_?1: begin sel_one_hot_n= 2'b01; tag_o = (lg_inputs_p) ' (0); end
    3'b1_10: begin sel_one_hot_n= 2'b10; tag_o = (lg_inputs_p) ' (1); end
    default: begin sel_one_hot_n= {2{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {2{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           1'b0 : hold_on_sr = ( reqs_i == 2'b01 );
           default: hold_on_sr = ( reqs_i == 2'b10 );
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_2 
    assign reset_on_sr = ( reqs_i == 2'b01 ) 
                       | ( reqs_i == 2'b10 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_2

if(inputs_p == 3)
begin: inputs_3

logic [3-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    5'b??_000: begin sel_one_hot_n = 3'b000; tag_o = (lg_inputs_p) ' (0); end // X
    5'b00_?1?: begin sel_one_hot_n= 3'b010; tag_o = (lg_inputs_p) ' (1); end
    5'b00_10?: begin sel_one_hot_n= 3'b100; tag_o = (lg_inputs_p) ' (2); end
    5'b00_001: begin sel_one_hot_n= 3'b001; tag_o = (lg_inputs_p) ' (0); end
    5'b01_1??: begin sel_one_hot_n= 3'b100; tag_o = (lg_inputs_p) ' (2); end
    5'b01_0?1: begin sel_one_hot_n= 3'b001; tag_o = (lg_inputs_p) ' (0); end
    5'b01_010: begin sel_one_hot_n= 3'b010; tag_o = (lg_inputs_p) ' (1); end
    5'b10_??1: begin sel_one_hot_n= 3'b001; tag_o = (lg_inputs_p) ' (0); end
    5'b10_?10: begin sel_one_hot_n= 3'b010; tag_o = (lg_inputs_p) ' (1); end
    5'b10_100: begin sel_one_hot_n= 3'b100; tag_o = (lg_inputs_p) ' (2); end
    default: begin sel_one_hot_n= {3{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {3{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           2'b00 : hold_on_sr = ( reqs_i == 3'b010 );
           2'b01 : hold_on_sr = ( reqs_i == 3'b001 );
           2'b10 : hold_on_sr = ( reqs_i == 3'b100 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_3 
    assign reset_on_sr = ( reqs_i == 3'b010 ) 
                       | ( reqs_i == 3'b001 ) 
                       | ( reqs_i == 3'b100 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_3

if(inputs_p == 4)
begin: inputs_4

logic [4-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    6'b??_0000: begin sel_one_hot_n = 4'b0000; tag_o = (lg_inputs_p) ' (0); end // X
    6'b00_??1?: begin sel_one_hot_n= 4'b0010; tag_o = (lg_inputs_p) ' (1); end
    6'b00_?10?: begin sel_one_hot_n= 4'b0100; tag_o = (lg_inputs_p) ' (2); end
    6'b00_100?: begin sel_one_hot_n= 4'b1000; tag_o = (lg_inputs_p) ' (3); end
    6'b00_0001: begin sel_one_hot_n= 4'b0001; tag_o = (lg_inputs_p) ' (0); end
    6'b01_?1??: begin sel_one_hot_n= 4'b0100; tag_o = (lg_inputs_p) ' (2); end
    6'b01_10??: begin sel_one_hot_n= 4'b1000; tag_o = (lg_inputs_p) ' (3); end
    6'b01_00?1: begin sel_one_hot_n= 4'b0001; tag_o = (lg_inputs_p) ' (0); end
    6'b01_0010: begin sel_one_hot_n= 4'b0010; tag_o = (lg_inputs_p) ' (1); end
    6'b10_1???: begin sel_one_hot_n= 4'b1000; tag_o = (lg_inputs_p) ' (3); end
    6'b10_0??1: begin sel_one_hot_n= 4'b0001; tag_o = (lg_inputs_p) ' (0); end
    6'b10_0?10: begin sel_one_hot_n= 4'b0010; tag_o = (lg_inputs_p) ' (1); end
    6'b10_0100: begin sel_one_hot_n= 4'b0100; tag_o = (lg_inputs_p) ' (2); end
    6'b11_???1: begin sel_one_hot_n= 4'b0001; tag_o = (lg_inputs_p) ' (0); end
    6'b11_??10: begin sel_one_hot_n= 4'b0010; tag_o = (lg_inputs_p) ' (1); end
    6'b11_?100: begin sel_one_hot_n= 4'b0100; tag_o = (lg_inputs_p) ' (2); end
    6'b11_1000: begin sel_one_hot_n= 4'b1000; tag_o = (lg_inputs_p) ' (3); end
    default: begin sel_one_hot_n= {4{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {4{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           2'b00 : hold_on_sr = ( reqs_i == 4'b0100 );
           2'b01 : hold_on_sr = ( reqs_i == 4'b0010 );
           2'b10 : hold_on_sr = ( reqs_i == 4'b0001 );
           default: hold_on_sr = ( reqs_i == 4'b1000 );
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_4 
    assign reset_on_sr = ( reqs_i == 4'b0100 ) 
                       | ( reqs_i == 4'b0010 ) 
                       | ( reqs_i == 4'b0001 ) 
                       | ( reqs_i == 4'b1000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_4

if(inputs_p == 5)
begin: inputs_5

logic [5-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    8'b???_00000: begin sel_one_hot_n = 5'b00000; tag_o = (lg_inputs_p) ' (0); end // X
    8'b000_???1?: begin sel_one_hot_n= 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    8'b000_??10?: begin sel_one_hot_n= 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    8'b000_?100?: begin sel_one_hot_n= 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    8'b000_1000?: begin sel_one_hot_n= 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    8'b000_00001: begin sel_one_hot_n= 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    8'b001_??1??: begin sel_one_hot_n= 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    8'b001_?10??: begin sel_one_hot_n= 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    8'b001_100??: begin sel_one_hot_n= 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    8'b001_000?1: begin sel_one_hot_n= 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    8'b001_00010: begin sel_one_hot_n= 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    8'b010_?1???: begin sel_one_hot_n= 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    8'b010_10???: begin sel_one_hot_n= 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    8'b010_00??1: begin sel_one_hot_n= 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    8'b010_00?10: begin sel_one_hot_n= 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    8'b010_00100: begin sel_one_hot_n= 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    8'b011_1????: begin sel_one_hot_n= 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    8'b011_0???1: begin sel_one_hot_n= 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    8'b011_0??10: begin sel_one_hot_n= 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    8'b011_0?100: begin sel_one_hot_n= 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    8'b011_01000: begin sel_one_hot_n= 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    8'b100_????1: begin sel_one_hot_n= 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    8'b100_???10: begin sel_one_hot_n= 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    8'b100_??100: begin sel_one_hot_n= 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    8'b100_?1000: begin sel_one_hot_n= 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    8'b100_10000: begin sel_one_hot_n= 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    default: begin sel_one_hot_n= {5{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {5{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           3'b000 : hold_on_sr = ( reqs_i == 5'b01000 );
           3'b001 : hold_on_sr = ( reqs_i == 5'b00100 );
           3'b010 : hold_on_sr = ( reqs_i == 5'b00010 );
           3'b011 : hold_on_sr = ( reqs_i == 5'b00001 );
           3'b100 : hold_on_sr = ( reqs_i == 5'b10000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_5 
    assign reset_on_sr = ( reqs_i == 5'b01000 ) 
                       | ( reqs_i == 5'b00100 ) 
                       | ( reqs_i == 5'b00010 ) 
                       | ( reqs_i == 5'b00001 ) 
                       | ( reqs_i == 5'b10000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_5

if(inputs_p == 6)
begin: inputs_6

logic [6-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    9'b???_000000: begin sel_one_hot_n = 6'b000000; tag_o = (lg_inputs_p) ' (0); end // X
    9'b000_????1?: begin sel_one_hot_n= 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    9'b000_???10?: begin sel_one_hot_n= 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    9'b000_??100?: begin sel_one_hot_n= 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    9'b000_?1000?: begin sel_one_hot_n= 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    9'b000_10000?: begin sel_one_hot_n= 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    9'b000_000001: begin sel_one_hot_n= 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    9'b001_???1??: begin sel_one_hot_n= 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    9'b001_??10??: begin sel_one_hot_n= 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    9'b001_?100??: begin sel_one_hot_n= 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    9'b001_1000??: begin sel_one_hot_n= 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    9'b001_0000?1: begin sel_one_hot_n= 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    9'b001_000010: begin sel_one_hot_n= 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    9'b010_??1???: begin sel_one_hot_n= 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    9'b010_?10???: begin sel_one_hot_n= 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    9'b010_100???: begin sel_one_hot_n= 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    9'b010_000??1: begin sel_one_hot_n= 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    9'b010_000?10: begin sel_one_hot_n= 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    9'b010_000100: begin sel_one_hot_n= 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    9'b011_?1????: begin sel_one_hot_n= 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    9'b011_10????: begin sel_one_hot_n= 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    9'b011_00???1: begin sel_one_hot_n= 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    9'b011_00??10: begin sel_one_hot_n= 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    9'b011_00?100: begin sel_one_hot_n= 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    9'b011_001000: begin sel_one_hot_n= 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    9'b100_1?????: begin sel_one_hot_n= 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    9'b100_0????1: begin sel_one_hot_n= 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    9'b100_0???10: begin sel_one_hot_n= 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    9'b100_0??100: begin sel_one_hot_n= 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    9'b100_0?1000: begin sel_one_hot_n= 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    9'b100_010000: begin sel_one_hot_n= 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    9'b101_?????1: begin sel_one_hot_n= 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    9'b101_????10: begin sel_one_hot_n= 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    9'b101_???100: begin sel_one_hot_n= 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    9'b101_??1000: begin sel_one_hot_n= 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    9'b101_?10000: begin sel_one_hot_n= 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    9'b101_100000: begin sel_one_hot_n= 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    default: begin sel_one_hot_n= {6{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {6{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           3'b000 : hold_on_sr = ( reqs_i == 6'b010000 );
           3'b001 : hold_on_sr = ( reqs_i == 6'b001000 );
           3'b010 : hold_on_sr = ( reqs_i == 6'b000100 );
           3'b011 : hold_on_sr = ( reqs_i == 6'b000010 );
           3'b100 : hold_on_sr = ( reqs_i == 6'b000001 );
           3'b101 : hold_on_sr = ( reqs_i == 6'b100000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_6 
    assign reset_on_sr = ( reqs_i == 6'b010000 ) 
                       | ( reqs_i == 6'b001000 ) 
                       | ( reqs_i == 6'b000100 ) 
                       | ( reqs_i == 6'b000010 ) 
                       | ( reqs_i == 6'b000001 ) 
                       | ( reqs_i == 6'b100000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_6

if(inputs_p == 7)
begin: inputs_7

logic [7-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    10'b???_0000000: begin sel_one_hot_n = 7'b0000000; tag_o = (lg_inputs_p) ' (0); end // X
    10'b000_?????1?: begin sel_one_hot_n= 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    10'b000_????10?: begin sel_one_hot_n= 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    10'b000_???100?: begin sel_one_hot_n= 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    10'b000_??1000?: begin sel_one_hot_n= 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    10'b000_?10000?: begin sel_one_hot_n= 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    10'b000_100000?: begin sel_one_hot_n= 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    10'b000_0000001: begin sel_one_hot_n= 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    10'b001_????1??: begin sel_one_hot_n= 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    10'b001_???10??: begin sel_one_hot_n= 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    10'b001_??100??: begin sel_one_hot_n= 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    10'b001_?1000??: begin sel_one_hot_n= 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    10'b001_10000??: begin sel_one_hot_n= 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    10'b001_00000?1: begin sel_one_hot_n= 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    10'b001_0000010: begin sel_one_hot_n= 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    10'b010_???1???: begin sel_one_hot_n= 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    10'b010_??10???: begin sel_one_hot_n= 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    10'b010_?100???: begin sel_one_hot_n= 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    10'b010_1000???: begin sel_one_hot_n= 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    10'b010_0000??1: begin sel_one_hot_n= 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    10'b010_0000?10: begin sel_one_hot_n= 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    10'b010_0000100: begin sel_one_hot_n= 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    10'b011_??1????: begin sel_one_hot_n= 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    10'b011_?10????: begin sel_one_hot_n= 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    10'b011_100????: begin sel_one_hot_n= 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    10'b011_000???1: begin sel_one_hot_n= 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    10'b011_000??10: begin sel_one_hot_n= 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    10'b011_000?100: begin sel_one_hot_n= 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    10'b011_0001000: begin sel_one_hot_n= 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    10'b100_?1?????: begin sel_one_hot_n= 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    10'b100_10?????: begin sel_one_hot_n= 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    10'b100_00????1: begin sel_one_hot_n= 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    10'b100_00???10: begin sel_one_hot_n= 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    10'b100_00??100: begin sel_one_hot_n= 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    10'b100_00?1000: begin sel_one_hot_n= 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    10'b100_0010000: begin sel_one_hot_n= 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    10'b101_1??????: begin sel_one_hot_n= 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    10'b101_0?????1: begin sel_one_hot_n= 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    10'b101_0????10: begin sel_one_hot_n= 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    10'b101_0???100: begin sel_one_hot_n= 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    10'b101_0??1000: begin sel_one_hot_n= 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    10'b101_0?10000: begin sel_one_hot_n= 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    10'b101_0100000: begin sel_one_hot_n= 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    10'b110_??????1: begin sel_one_hot_n= 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    10'b110_?????10: begin sel_one_hot_n= 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    10'b110_????100: begin sel_one_hot_n= 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    10'b110_???1000: begin sel_one_hot_n= 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    10'b110_??10000: begin sel_one_hot_n= 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    10'b110_?100000: begin sel_one_hot_n= 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    10'b110_1000000: begin sel_one_hot_n= 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    default: begin sel_one_hot_n= {7{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {7{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           3'b000 : hold_on_sr = ( reqs_i == 7'b0100000 );
           3'b001 : hold_on_sr = ( reqs_i == 7'b0010000 );
           3'b010 : hold_on_sr = ( reqs_i == 7'b0001000 );
           3'b011 : hold_on_sr = ( reqs_i == 7'b0000100 );
           3'b100 : hold_on_sr = ( reqs_i == 7'b0000010 );
           3'b101 : hold_on_sr = ( reqs_i == 7'b0000001 );
           3'b110 : hold_on_sr = ( reqs_i == 7'b1000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_7 
    assign reset_on_sr = ( reqs_i == 7'b0100000 ) 
                       | ( reqs_i == 7'b0010000 ) 
                       | ( reqs_i == 7'b0001000 ) 
                       | ( reqs_i == 7'b0000100 ) 
                       | ( reqs_i == 7'b0000010 ) 
                       | ( reqs_i == 7'b0000001 ) 
                       | ( reqs_i == 7'b1000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_7

if(inputs_p == 8)
begin: inputs_8

logic [8-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    11'b???_00000000: begin sel_one_hot_n = 8'b00000000; tag_o = (lg_inputs_p) ' (0); end // X
    11'b000_??????1?: begin sel_one_hot_n= 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    11'b000_?????10?: begin sel_one_hot_n= 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    11'b000_????100?: begin sel_one_hot_n= 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    11'b000_???1000?: begin sel_one_hot_n= 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    11'b000_??10000?: begin sel_one_hot_n= 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    11'b000_?100000?: begin sel_one_hot_n= 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    11'b000_1000000?: begin sel_one_hot_n= 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    11'b000_00000001: begin sel_one_hot_n= 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    11'b001_?????1??: begin sel_one_hot_n= 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    11'b001_????10??: begin sel_one_hot_n= 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    11'b001_???100??: begin sel_one_hot_n= 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    11'b001_??1000??: begin sel_one_hot_n= 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    11'b001_?10000??: begin sel_one_hot_n= 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    11'b001_100000??: begin sel_one_hot_n= 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    11'b001_000000?1: begin sel_one_hot_n= 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    11'b001_00000010: begin sel_one_hot_n= 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    11'b010_????1???: begin sel_one_hot_n= 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    11'b010_???10???: begin sel_one_hot_n= 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    11'b010_??100???: begin sel_one_hot_n= 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    11'b010_?1000???: begin sel_one_hot_n= 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    11'b010_10000???: begin sel_one_hot_n= 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    11'b010_00000??1: begin sel_one_hot_n= 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    11'b010_00000?10: begin sel_one_hot_n= 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    11'b010_00000100: begin sel_one_hot_n= 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    11'b011_???1????: begin sel_one_hot_n= 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    11'b011_??10????: begin sel_one_hot_n= 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    11'b011_?100????: begin sel_one_hot_n= 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    11'b011_1000????: begin sel_one_hot_n= 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    11'b011_0000???1: begin sel_one_hot_n= 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    11'b011_0000??10: begin sel_one_hot_n= 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    11'b011_0000?100: begin sel_one_hot_n= 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    11'b011_00001000: begin sel_one_hot_n= 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    11'b100_??1?????: begin sel_one_hot_n= 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    11'b100_?10?????: begin sel_one_hot_n= 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    11'b100_100?????: begin sel_one_hot_n= 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    11'b100_000????1: begin sel_one_hot_n= 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    11'b100_000???10: begin sel_one_hot_n= 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    11'b100_000??100: begin sel_one_hot_n= 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    11'b100_000?1000: begin sel_one_hot_n= 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    11'b100_00010000: begin sel_one_hot_n= 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    11'b101_?1??????: begin sel_one_hot_n= 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    11'b101_10??????: begin sel_one_hot_n= 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    11'b101_00?????1: begin sel_one_hot_n= 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    11'b101_00????10: begin sel_one_hot_n= 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    11'b101_00???100: begin sel_one_hot_n= 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    11'b101_00??1000: begin sel_one_hot_n= 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    11'b101_00?10000: begin sel_one_hot_n= 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    11'b101_00100000: begin sel_one_hot_n= 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    11'b110_1???????: begin sel_one_hot_n= 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    11'b110_0??????1: begin sel_one_hot_n= 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    11'b110_0?????10: begin sel_one_hot_n= 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    11'b110_0????100: begin sel_one_hot_n= 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    11'b110_0???1000: begin sel_one_hot_n= 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    11'b110_0??10000: begin sel_one_hot_n= 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    11'b110_0?100000: begin sel_one_hot_n= 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    11'b110_01000000: begin sel_one_hot_n= 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    11'b111_???????1: begin sel_one_hot_n= 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    11'b111_??????10: begin sel_one_hot_n= 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    11'b111_?????100: begin sel_one_hot_n= 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    11'b111_????1000: begin sel_one_hot_n= 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    11'b111_???10000: begin sel_one_hot_n= 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    11'b111_??100000: begin sel_one_hot_n= 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    11'b111_?1000000: begin sel_one_hot_n= 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    11'b111_10000000: begin sel_one_hot_n= 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    default: begin sel_one_hot_n= {8{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {8{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           3'b000 : hold_on_sr = ( reqs_i == 8'b01000000 );
           3'b001 : hold_on_sr = ( reqs_i == 8'b00100000 );
           3'b010 : hold_on_sr = ( reqs_i == 8'b00010000 );
           3'b011 : hold_on_sr = ( reqs_i == 8'b00001000 );
           3'b100 : hold_on_sr = ( reqs_i == 8'b00000100 );
           3'b101 : hold_on_sr = ( reqs_i == 8'b00000010 );
           3'b110 : hold_on_sr = ( reqs_i == 8'b00000001 );
           default: hold_on_sr = ( reqs_i == 8'b10000000 );
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_8 
    assign reset_on_sr = ( reqs_i == 8'b01000000 ) 
                       | ( reqs_i == 8'b00100000 ) 
                       | ( reqs_i == 8'b00010000 ) 
                       | ( reqs_i == 8'b00001000 ) 
                       | ( reqs_i == 8'b00000100 ) 
                       | ( reqs_i == 8'b00000010 ) 
                       | ( reqs_i == 8'b00000001 ) 
                       | ( reqs_i == 8'b10000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_8

if(inputs_p == 9)
begin: inputs_9

logic [9-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    13'b????_000000000: begin sel_one_hot_n = 9'b000000000; tag_o = (lg_inputs_p) ' (0); end // X
    13'b0000_???????1?: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b0000_??????10?: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b0000_?????100?: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b0000_????1000?: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b0000_???10000?: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b0000_??100000?: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b0000_?1000000?: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b0000_10000000?: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    13'b0000_000000001: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b0001_??????1??: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b0001_?????10??: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b0001_????100??: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b0001_???1000??: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b0001_??10000??: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b0001_?100000??: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b0001_1000000??: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    13'b0001_0000000?1: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b0001_000000010: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b0010_?????1???: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b0010_????10???: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b0010_???100???: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b0010_??1000???: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b0010_?10000???: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b0010_100000???: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    13'b0010_000000??1: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b0010_000000?10: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b0010_000000100: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b0011_????1????: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b0011_???10????: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b0011_??100????: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b0011_?1000????: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b0011_10000????: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    13'b0011_00000???1: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b0011_00000??10: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b0011_00000?100: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b0011_000001000: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b0100_???1?????: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b0100_??10?????: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b0100_?100?????: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b0100_1000?????: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    13'b0100_0000????1: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b0100_0000???10: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b0100_0000??100: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b0100_0000?1000: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b0100_000010000: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b0101_??1??????: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b0101_?10??????: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b0101_100??????: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    13'b0101_000?????1: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b0101_000????10: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b0101_000???100: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b0101_000??1000: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b0101_000?10000: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b0101_000100000: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b0110_?1???????: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b0110_10???????: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    13'b0110_00??????1: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b0110_00?????10: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b0110_00????100: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b0110_00???1000: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b0110_00??10000: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b0110_00?100000: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b0110_001000000: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b0111_1????????: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    13'b0111_0???????1: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b0111_0??????10: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b0111_0?????100: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b0111_0????1000: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b0111_0???10000: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b0111_0??100000: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b0111_0?1000000: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b0111_010000000: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b1000_????????1: begin sel_one_hot_n= 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    13'b1000_???????10: begin sel_one_hot_n= 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    13'b1000_??????100: begin sel_one_hot_n= 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    13'b1000_?????1000: begin sel_one_hot_n= 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    13'b1000_????10000: begin sel_one_hot_n= 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    13'b1000_???100000: begin sel_one_hot_n= 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    13'b1000_??1000000: begin sel_one_hot_n= 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    13'b1000_?10000000: begin sel_one_hot_n= 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    13'b1000_100000000: begin sel_one_hot_n= 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    default: begin sel_one_hot_n= {9{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {9{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           4'b0000 : hold_on_sr = ( reqs_i == 9'b010000000 );
           4'b0001 : hold_on_sr = ( reqs_i == 9'b001000000 );
           4'b0010 : hold_on_sr = ( reqs_i == 9'b000100000 );
           4'b0011 : hold_on_sr = ( reqs_i == 9'b000010000 );
           4'b0100 : hold_on_sr = ( reqs_i == 9'b000001000 );
           4'b0101 : hold_on_sr = ( reqs_i == 9'b000000100 );
           4'b0110 : hold_on_sr = ( reqs_i == 9'b000000010 );
           4'b0111 : hold_on_sr = ( reqs_i == 9'b000000001 );
           4'b1000 : hold_on_sr = ( reqs_i == 9'b100000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_9 
    assign reset_on_sr = ( reqs_i == 9'b010000000 ) 
                       | ( reqs_i == 9'b001000000 ) 
                       | ( reqs_i == 9'b000100000 ) 
                       | ( reqs_i == 9'b000010000 ) 
                       | ( reqs_i == 9'b000001000 ) 
                       | ( reqs_i == 9'b000000100 ) 
                       | ( reqs_i == 9'b000000010 ) 
                       | ( reqs_i == 9'b000000001 ) 
                       | ( reqs_i == 9'b100000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_9

if(inputs_p == 10)
begin: inputs_10

logic [10-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    14'b????_0000000000: begin sel_one_hot_n = 10'b0000000000; tag_o = (lg_inputs_p) ' (0); end // X
    14'b0000_????????1?: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b0000_???????10?: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b0000_??????100?: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b0000_?????1000?: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b0000_????10000?: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b0000_???100000?: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b0000_??1000000?: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b0000_?10000000?: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b0000_100000000?: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b0000_0000000001: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b0001_???????1??: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b0001_??????10??: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b0001_?????100??: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b0001_????1000??: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b0001_???10000??: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b0001_??100000??: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b0001_?1000000??: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b0001_10000000??: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b0001_00000000?1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b0001_0000000010: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b0010_??????1???: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b0010_?????10???: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b0010_????100???: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b0010_???1000???: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b0010_??10000???: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b0010_?100000???: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b0010_1000000???: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b0010_0000000??1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b0010_0000000?10: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b0010_0000000100: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b0011_?????1????: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b0011_????10????: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b0011_???100????: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b0011_??1000????: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b0011_?10000????: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b0011_100000????: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b0011_000000???1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b0011_000000??10: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b0011_000000?100: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b0011_0000001000: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b0100_????1?????: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b0100_???10?????: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b0100_??100?????: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b0100_?1000?????: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b0100_10000?????: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b0100_00000????1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b0100_00000???10: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b0100_00000??100: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b0100_00000?1000: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b0100_0000010000: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b0101_???1??????: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b0101_??10??????: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b0101_?100??????: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b0101_1000??????: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b0101_0000?????1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b0101_0000????10: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b0101_0000???100: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b0101_0000??1000: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b0101_0000?10000: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b0101_0000100000: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b0110_??1???????: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b0110_?10???????: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b0110_100???????: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b0110_000??????1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b0110_000?????10: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b0110_000????100: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b0110_000???1000: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b0110_000??10000: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b0110_000?100000: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b0110_0001000000: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b0111_?1????????: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b0111_10????????: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b0111_00???????1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b0111_00??????10: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b0111_00?????100: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b0111_00????1000: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b0111_00???10000: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b0111_00??100000: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b0111_00?1000000: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b0111_0010000000: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1000_1?????????: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    14'b1000_0????????1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1000_0???????10: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1000_0??????100: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1000_0?????1000: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1000_0????10000: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1000_0???100000: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1000_0??1000000: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1000_0?10000000: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1000_0100000000: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1001_?????????1: begin sel_one_hot_n= 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1001_????????10: begin sel_one_hot_n= 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1001_???????100: begin sel_one_hot_n= 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1001_??????1000: begin sel_one_hot_n= 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1001_?????10000: begin sel_one_hot_n= 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1001_????100000: begin sel_one_hot_n= 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1001_???1000000: begin sel_one_hot_n= 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1001_??10000000: begin sel_one_hot_n= 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1001_?100000000: begin sel_one_hot_n= 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1001_1000000000: begin sel_one_hot_n= 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    default: begin sel_one_hot_n= {10{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {10{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           4'b0000 : hold_on_sr = ( reqs_i == 10'b0100000000 );
           4'b0001 : hold_on_sr = ( reqs_i == 10'b0010000000 );
           4'b0010 : hold_on_sr = ( reqs_i == 10'b0001000000 );
           4'b0011 : hold_on_sr = ( reqs_i == 10'b0000100000 );
           4'b0100 : hold_on_sr = ( reqs_i == 10'b0000010000 );
           4'b0101 : hold_on_sr = ( reqs_i == 10'b0000001000 );
           4'b0110 : hold_on_sr = ( reqs_i == 10'b0000000100 );
           4'b0111 : hold_on_sr = ( reqs_i == 10'b0000000010 );
           4'b1000 : hold_on_sr = ( reqs_i == 10'b0000000001 );
           4'b1001 : hold_on_sr = ( reqs_i == 10'b1000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_10 
    assign reset_on_sr = ( reqs_i == 10'b0100000000 ) 
                       | ( reqs_i == 10'b0010000000 ) 
                       | ( reqs_i == 10'b0001000000 ) 
                       | ( reqs_i == 10'b0000100000 ) 
                       | ( reqs_i == 10'b0000010000 ) 
                       | ( reqs_i == 10'b0000001000 ) 
                       | ( reqs_i == 10'b0000000100 ) 
                       | ( reqs_i == 10'b0000000010 ) 
                       | ( reqs_i == 10'b0000000001 ) 
                       | ( reqs_i == 10'b1000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_10

if(inputs_p == 11)
begin: inputs_11

logic [11-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    15'b????_00000000000: begin sel_one_hot_n = 11'b00000000000; tag_o = (lg_inputs_p) ' (0); end // X
    15'b0000_?????????1?: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b0000_????????10?: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b0000_???????100?: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b0000_??????1000?: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b0000_?????10000?: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b0000_????100000?: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b0000_???1000000?: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b0000_??10000000?: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b0000_?100000000?: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b0000_1000000000?: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b0000_00000000001: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b0001_????????1??: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b0001_???????10??: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b0001_??????100??: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b0001_?????1000??: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b0001_????10000??: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b0001_???100000??: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b0001_??1000000??: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b0001_?10000000??: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b0001_100000000??: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b0001_000000000?1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b0001_00000000010: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b0010_???????1???: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b0010_??????10???: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b0010_?????100???: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b0010_????1000???: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b0010_???10000???: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b0010_??100000???: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b0010_?1000000???: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b0010_10000000???: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b0010_00000000??1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b0010_00000000?10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b0010_00000000100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b0011_??????1????: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b0011_?????10????: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b0011_????100????: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b0011_???1000????: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b0011_??10000????: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b0011_?100000????: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b0011_1000000????: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b0011_0000000???1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b0011_0000000??10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b0011_0000000?100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b0011_00000001000: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b0100_?????1?????: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b0100_????10?????: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b0100_???100?????: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b0100_??1000?????: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b0100_?10000?????: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b0100_100000?????: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b0100_000000????1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b0100_000000???10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b0100_000000??100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b0100_000000?1000: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b0100_00000010000: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b0101_????1??????: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b0101_???10??????: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b0101_??100??????: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b0101_?1000??????: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b0101_10000??????: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b0101_00000?????1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b0101_00000????10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b0101_00000???100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b0101_00000??1000: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b0101_00000?10000: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b0101_00000100000: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b0110_???1???????: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b0110_??10???????: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b0110_?100???????: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b0110_1000???????: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b0110_0000??????1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b0110_0000?????10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b0110_0000????100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b0110_0000???1000: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b0110_0000??10000: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b0110_0000?100000: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b0110_00001000000: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b0111_??1????????: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b0111_?10????????: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b0111_100????????: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b0111_000???????1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b0111_000??????10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b0111_000?????100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b0111_000????1000: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b0111_000???10000: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b0111_000??100000: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b0111_000?1000000: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b0111_00010000000: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1000_?1?????????: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1000_10?????????: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b1000_00????????1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1000_00???????10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1000_00??????100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1000_00?????1000: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1000_00????10000: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1000_00???100000: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1000_00??1000000: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1000_00?10000000: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1000_00100000000: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1001_1??????????: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    15'b1001_0?????????1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1001_0????????10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1001_0???????100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1001_0??????1000: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1001_0?????10000: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1001_0????100000: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1001_0???1000000: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1001_0??10000000: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1001_0?100000000: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1001_01000000000: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1010_??????????1: begin sel_one_hot_n= 11'b00000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1010_?????????10: begin sel_one_hot_n= 11'b00000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1010_????????100: begin sel_one_hot_n= 11'b00000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1010_???????1000: begin sel_one_hot_n= 11'b00000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1010_??????10000: begin sel_one_hot_n= 11'b00000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1010_?????100000: begin sel_one_hot_n= 11'b00000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1010_????1000000: begin sel_one_hot_n= 11'b00001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1010_???10000000: begin sel_one_hot_n= 11'b00010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1010_??100000000: begin sel_one_hot_n= 11'b00100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1010_?1000000000: begin sel_one_hot_n= 11'b01000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1010_10000000000: begin sel_one_hot_n= 11'b10000000000; tag_o = (lg_inputs_p) ' (10); end
    default: begin sel_one_hot_n= {11{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {11{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           4'b0000 : hold_on_sr = ( reqs_i == 11'b01000000000 );
           4'b0001 : hold_on_sr = ( reqs_i == 11'b00100000000 );
           4'b0010 : hold_on_sr = ( reqs_i == 11'b00010000000 );
           4'b0011 : hold_on_sr = ( reqs_i == 11'b00001000000 );
           4'b0100 : hold_on_sr = ( reqs_i == 11'b00000100000 );
           4'b0101 : hold_on_sr = ( reqs_i == 11'b00000010000 );
           4'b0110 : hold_on_sr = ( reqs_i == 11'b00000001000 );
           4'b0111 : hold_on_sr = ( reqs_i == 11'b00000000100 );
           4'b1000 : hold_on_sr = ( reqs_i == 11'b00000000010 );
           4'b1001 : hold_on_sr = ( reqs_i == 11'b00000000001 );
           4'b1010 : hold_on_sr = ( reqs_i == 11'b10000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_11 
    assign reset_on_sr = ( reqs_i == 11'b01000000000 ) 
                       | ( reqs_i == 11'b00100000000 ) 
                       | ( reqs_i == 11'b00010000000 ) 
                       | ( reqs_i == 11'b00001000000 ) 
                       | ( reqs_i == 11'b00000100000 ) 
                       | ( reqs_i == 11'b00000010000 ) 
                       | ( reqs_i == 11'b00000001000 ) 
                       | ( reqs_i == 11'b00000000100 ) 
                       | ( reqs_i == 11'b00000000010 ) 
                       | ( reqs_i == 11'b00000000001 ) 
                       | ( reqs_i == 11'b10000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_11

if(inputs_p == 12)
begin: inputs_12

logic [12-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    16'b????_000000000000: begin sel_one_hot_n = 12'b000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    16'b0000_??????????1?: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b0000_?????????10?: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b0000_????????100?: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b0000_???????1000?: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b0000_??????10000?: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b0000_?????100000?: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b0000_????1000000?: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b0000_???10000000?: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b0000_??100000000?: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b0000_?1000000000?: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b0000_10000000000?: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b0000_000000000001: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b0001_?????????1??: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b0001_????????10??: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b0001_???????100??: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b0001_??????1000??: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b0001_?????10000??: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b0001_????100000??: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b0001_???1000000??: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b0001_??10000000??: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b0001_?100000000??: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b0001_1000000000??: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b0001_0000000000?1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b0001_000000000010: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b0010_????????1???: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b0010_???????10???: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b0010_??????100???: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b0010_?????1000???: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b0010_????10000???: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b0010_???100000???: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b0010_??1000000???: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b0010_?10000000???: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b0010_100000000???: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b0010_000000000??1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b0010_000000000?10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b0010_000000000100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b0011_???????1????: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b0011_??????10????: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b0011_?????100????: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b0011_????1000????: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b0011_???10000????: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b0011_??100000????: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b0011_?1000000????: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b0011_10000000????: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b0011_00000000???1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b0011_00000000??10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b0011_00000000?100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b0011_000000001000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b0100_??????1?????: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b0100_?????10?????: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b0100_????100?????: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b0100_???1000?????: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b0100_??10000?????: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b0100_?100000?????: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b0100_1000000?????: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b0100_0000000????1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b0100_0000000???10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b0100_0000000??100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b0100_0000000?1000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b0100_000000010000: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b0101_?????1??????: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b0101_????10??????: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b0101_???100??????: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b0101_??1000??????: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b0101_?10000??????: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b0101_100000??????: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b0101_000000?????1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b0101_000000????10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b0101_000000???100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b0101_000000??1000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b0101_000000?10000: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b0101_000000100000: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b0110_????1???????: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b0110_???10???????: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b0110_??100???????: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b0110_?1000???????: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b0110_10000???????: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b0110_00000??????1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b0110_00000?????10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b0110_00000????100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b0110_00000???1000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b0110_00000??10000: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b0110_00000?100000: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b0110_000001000000: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b0111_???1????????: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b0111_??10????????: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b0111_?100????????: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b0111_1000????????: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b0111_0000???????1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b0111_0000??????10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b0111_0000?????100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b0111_0000????1000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b0111_0000???10000: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b0111_0000??100000: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b0111_0000?1000000: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b0111_000010000000: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b1000_??1?????????: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b1000_?10?????????: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b1000_100?????????: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b1000_000????????1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b1000_000???????10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b1000_000??????100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b1000_000?????1000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b1000_000????10000: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b1000_000???100000: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b1000_000??1000000: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b1000_000?10000000: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b1000_000100000000: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b1001_?1??????????: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b1001_10??????????: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b1001_00?????????1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b1001_00????????10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b1001_00???????100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b1001_00??????1000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b1001_00?????10000: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b1001_00????100000: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b1001_00???1000000: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b1001_00??10000000: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b1001_00?100000000: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b1001_001000000000: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b1010_1???????????: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    16'b1010_0??????????1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b1010_0?????????10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b1010_0????????100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b1010_0???????1000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b1010_0??????10000: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b1010_0?????100000: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b1010_0????1000000: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b1010_0???10000000: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b1010_0??100000000: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b1010_0?1000000000: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b1010_010000000000: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b1011_???????????1: begin sel_one_hot_n= 12'b000000000001; tag_o = (lg_inputs_p) ' (0); end
    16'b1011_??????????10: begin sel_one_hot_n= 12'b000000000010; tag_o = (lg_inputs_p) ' (1); end
    16'b1011_?????????100: begin sel_one_hot_n= 12'b000000000100; tag_o = (lg_inputs_p) ' (2); end
    16'b1011_????????1000: begin sel_one_hot_n= 12'b000000001000; tag_o = (lg_inputs_p) ' (3); end
    16'b1011_???????10000: begin sel_one_hot_n= 12'b000000010000; tag_o = (lg_inputs_p) ' (4); end
    16'b1011_??????100000: begin sel_one_hot_n= 12'b000000100000; tag_o = (lg_inputs_p) ' (5); end
    16'b1011_?????1000000: begin sel_one_hot_n= 12'b000001000000; tag_o = (lg_inputs_p) ' (6); end
    16'b1011_????10000000: begin sel_one_hot_n= 12'b000010000000; tag_o = (lg_inputs_p) ' (7); end
    16'b1011_???100000000: begin sel_one_hot_n= 12'b000100000000; tag_o = (lg_inputs_p) ' (8); end
    16'b1011_??1000000000: begin sel_one_hot_n= 12'b001000000000; tag_o = (lg_inputs_p) ' (9); end
    16'b1011_?10000000000: begin sel_one_hot_n= 12'b010000000000; tag_o = (lg_inputs_p) ' (10); end
    16'b1011_100000000000: begin sel_one_hot_n= 12'b100000000000; tag_o = (lg_inputs_p) ' (11); end
    default: begin sel_one_hot_n= {12{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {12{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           4'b0000 : hold_on_sr = ( reqs_i == 12'b010000000000 );
           4'b0001 : hold_on_sr = ( reqs_i == 12'b001000000000 );
           4'b0010 : hold_on_sr = ( reqs_i == 12'b000100000000 );
           4'b0011 : hold_on_sr = ( reqs_i == 12'b000010000000 );
           4'b0100 : hold_on_sr = ( reqs_i == 12'b000001000000 );
           4'b0101 : hold_on_sr = ( reqs_i == 12'b000000100000 );
           4'b0110 : hold_on_sr = ( reqs_i == 12'b000000010000 );
           4'b0111 : hold_on_sr = ( reqs_i == 12'b000000001000 );
           4'b1000 : hold_on_sr = ( reqs_i == 12'b000000000100 );
           4'b1001 : hold_on_sr = ( reqs_i == 12'b000000000010 );
           4'b1010 : hold_on_sr = ( reqs_i == 12'b000000000001 );
           4'b1011 : hold_on_sr = ( reqs_i == 12'b100000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_12 
    assign reset_on_sr = ( reqs_i == 12'b010000000000 ) 
                       | ( reqs_i == 12'b001000000000 ) 
                       | ( reqs_i == 12'b000100000000 ) 
                       | ( reqs_i == 12'b000010000000 ) 
                       | ( reqs_i == 12'b000001000000 ) 
                       | ( reqs_i == 12'b000000100000 ) 
                       | ( reqs_i == 12'b000000010000 ) 
                       | ( reqs_i == 12'b000000001000 ) 
                       | ( reqs_i == 12'b000000000100 ) 
                       | ( reqs_i == 12'b000000000010 ) 
                       | ( reqs_i == 12'b000000000001 ) 
                       | ( reqs_i == 12'b100000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_12

if(inputs_p == 13)
begin: inputs_13

logic [13-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    17'b????_0000000000000: begin sel_one_hot_n = 13'b0000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    17'b0000_???????????1?: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b0000_??????????10?: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b0000_?????????100?: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b0000_????????1000?: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b0000_???????10000?: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b0000_??????100000?: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b0000_?????1000000?: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b0000_????10000000?: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b0000_???100000000?: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b0000_??1000000000?: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b0000_?10000000000?: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b0000_100000000000?: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b0000_0000000000001: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b0001_??????????1??: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b0001_?????????10??: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b0001_????????100??: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b0001_???????1000??: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b0001_??????10000??: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b0001_?????100000??: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b0001_????1000000??: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b0001_???10000000??: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b0001_??100000000??: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b0001_?1000000000??: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b0001_10000000000??: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b0001_00000000000?1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b0001_0000000000010: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b0010_?????????1???: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b0010_????????10???: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b0010_???????100???: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b0010_??????1000???: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b0010_?????10000???: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b0010_????100000???: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b0010_???1000000???: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b0010_??10000000???: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b0010_?100000000???: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b0010_1000000000???: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b0010_0000000000??1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b0010_0000000000?10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b0010_0000000000100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b0011_????????1????: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b0011_???????10????: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b0011_??????100????: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b0011_?????1000????: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b0011_????10000????: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b0011_???100000????: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b0011_??1000000????: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b0011_?10000000????: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b0011_100000000????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b0011_000000000???1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b0011_000000000??10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b0011_000000000?100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b0011_0000000001000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b0100_???????1?????: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b0100_??????10?????: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b0100_?????100?????: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b0100_????1000?????: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b0100_???10000?????: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b0100_??100000?????: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b0100_?1000000?????: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b0100_10000000?????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b0100_00000000????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b0100_00000000???10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b0100_00000000??100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b0100_00000000?1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b0100_0000000010000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b0101_??????1??????: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b0101_?????10??????: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b0101_????100??????: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b0101_???1000??????: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b0101_??10000??????: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b0101_?100000??????: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b0101_1000000??????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b0101_0000000?????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b0101_0000000????10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b0101_0000000???100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b0101_0000000??1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b0101_0000000?10000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b0101_0000000100000: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b0110_?????1???????: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b0110_????10???????: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b0110_???100???????: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b0110_??1000???????: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b0110_?10000???????: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b0110_100000???????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b0110_000000??????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b0110_000000?????10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b0110_000000????100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b0110_000000???1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b0110_000000??10000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b0110_000000?100000: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b0110_0000001000000: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b0111_????1????????: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b0111_???10????????: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b0111_??100????????: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b0111_?1000????????: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b0111_10000????????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b0111_00000???????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b0111_00000??????10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b0111_00000?????100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b0111_00000????1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b0111_00000???10000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b0111_00000??100000: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b0111_00000?1000000: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b0111_0000010000000: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b1000_???1?????????: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b1000_??10?????????: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b1000_?100?????????: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b1000_1000?????????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b1000_0000????????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b1000_0000???????10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b1000_0000??????100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b1000_0000?????1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b1000_0000????10000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b1000_0000???100000: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b1000_0000??1000000: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b1000_0000?10000000: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b1000_0000100000000: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b1001_??1??????????: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b1001_?10??????????: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b1001_100??????????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b1001_000?????????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b1001_000????????10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b1001_000???????100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b1001_000??????1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b1001_000?????10000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b1001_000????100000: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b1001_000???1000000: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b1001_000??10000000: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b1001_000?100000000: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b1001_0001000000000: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b1010_?1???????????: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b1010_10???????????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b1010_00??????????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b1010_00?????????10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b1010_00????????100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b1010_00???????1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b1010_00??????10000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b1010_00?????100000: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b1010_00????1000000: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b1010_00???10000000: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b1010_00??100000000: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b1010_00?1000000000: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b1010_0010000000000: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b1011_1????????????: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    17'b1011_0???????????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b1011_0??????????10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b1011_0?????????100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b1011_0????????1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b1011_0???????10000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b1011_0??????100000: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b1011_0?????1000000: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b1011_0????10000000: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b1011_0???100000000: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b1011_0??1000000000: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b1011_0?10000000000: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b1011_0100000000000: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b1100_????????????1: begin sel_one_hot_n= 13'b0000000000001; tag_o = (lg_inputs_p) ' (0); end
    17'b1100_???????????10: begin sel_one_hot_n= 13'b0000000000010; tag_o = (lg_inputs_p) ' (1); end
    17'b1100_??????????100: begin sel_one_hot_n= 13'b0000000000100; tag_o = (lg_inputs_p) ' (2); end
    17'b1100_?????????1000: begin sel_one_hot_n= 13'b0000000001000; tag_o = (lg_inputs_p) ' (3); end
    17'b1100_????????10000: begin sel_one_hot_n= 13'b0000000010000; tag_o = (lg_inputs_p) ' (4); end
    17'b1100_???????100000: begin sel_one_hot_n= 13'b0000000100000; tag_o = (lg_inputs_p) ' (5); end
    17'b1100_??????1000000: begin sel_one_hot_n= 13'b0000001000000; tag_o = (lg_inputs_p) ' (6); end
    17'b1100_?????10000000: begin sel_one_hot_n= 13'b0000010000000; tag_o = (lg_inputs_p) ' (7); end
    17'b1100_????100000000: begin sel_one_hot_n= 13'b0000100000000; tag_o = (lg_inputs_p) ' (8); end
    17'b1100_???1000000000: begin sel_one_hot_n= 13'b0001000000000; tag_o = (lg_inputs_p) ' (9); end
    17'b1100_??10000000000: begin sel_one_hot_n= 13'b0010000000000; tag_o = (lg_inputs_p) ' (10); end
    17'b1100_?100000000000: begin sel_one_hot_n= 13'b0100000000000; tag_o = (lg_inputs_p) ' (11); end
    17'b1100_1000000000000: begin sel_one_hot_n= 13'b1000000000000; tag_o = (lg_inputs_p) ' (12); end
    default: begin sel_one_hot_n= {13{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {13{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           4'b0000 : hold_on_sr = ( reqs_i == 13'b0100000000000 );
           4'b0001 : hold_on_sr = ( reqs_i == 13'b0010000000000 );
           4'b0010 : hold_on_sr = ( reqs_i == 13'b0001000000000 );
           4'b0011 : hold_on_sr = ( reqs_i == 13'b0000100000000 );
           4'b0100 : hold_on_sr = ( reqs_i == 13'b0000010000000 );
           4'b0101 : hold_on_sr = ( reqs_i == 13'b0000001000000 );
           4'b0110 : hold_on_sr = ( reqs_i == 13'b0000000100000 );
           4'b0111 : hold_on_sr = ( reqs_i == 13'b0000000010000 );
           4'b1000 : hold_on_sr = ( reqs_i == 13'b0000000001000 );
           4'b1001 : hold_on_sr = ( reqs_i == 13'b0000000000100 );
           4'b1010 : hold_on_sr = ( reqs_i == 13'b0000000000010 );
           4'b1011 : hold_on_sr = ( reqs_i == 13'b0000000000001 );
           4'b1100 : hold_on_sr = ( reqs_i == 13'b1000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_13 
    assign reset_on_sr = ( reqs_i == 13'b0100000000000 ) 
                       | ( reqs_i == 13'b0010000000000 ) 
                       | ( reqs_i == 13'b0001000000000 ) 
                       | ( reqs_i == 13'b0000100000000 ) 
                       | ( reqs_i == 13'b0000010000000 ) 
                       | ( reqs_i == 13'b0000001000000 ) 
                       | ( reqs_i == 13'b0000000100000 ) 
                       | ( reqs_i == 13'b0000000010000 ) 
                       | ( reqs_i == 13'b0000000001000 ) 
                       | ( reqs_i == 13'b0000000000100 ) 
                       | ( reqs_i == 13'b0000000000010 ) 
                       | ( reqs_i == 13'b0000000000001 ) 
                       | ( reqs_i == 13'b1000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_13

if(inputs_p == 14)
begin: inputs_14

logic [14-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    18'b????_00000000000000: begin sel_one_hot_n = 14'b00000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    18'b0000_????????????1?: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b0000_???????????10?: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b0000_??????????100?: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b0000_?????????1000?: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b0000_????????10000?: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b0000_???????100000?: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b0000_??????1000000?: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b0000_?????10000000?: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b0000_????100000000?: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b0000_???1000000000?: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b0000_??10000000000?: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b0000_?100000000000?: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b0000_1000000000000?: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b0000_00000000000001: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b0001_???????????1??: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b0001_??????????10??: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b0001_?????????100??: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b0001_????????1000??: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b0001_???????10000??: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b0001_??????100000??: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b0001_?????1000000??: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b0001_????10000000??: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b0001_???100000000??: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b0001_??1000000000??: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b0001_?10000000000??: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b0001_100000000000??: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b0001_000000000000?1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b0001_00000000000010: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b0010_??????????1???: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b0010_?????????10???: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b0010_????????100???: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b0010_???????1000???: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b0010_??????10000???: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b0010_?????100000???: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b0010_????1000000???: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b0010_???10000000???: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b0010_??100000000???: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b0010_?1000000000???: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b0010_10000000000???: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b0010_00000000000??1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b0010_00000000000?10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b0010_00000000000100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b0011_?????????1????: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b0011_????????10????: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b0011_???????100????: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b0011_??????1000????: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b0011_?????10000????: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b0011_????100000????: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b0011_???1000000????: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b0011_??10000000????: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b0011_?100000000????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b0011_1000000000????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b0011_0000000000???1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b0011_0000000000??10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b0011_0000000000?100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b0011_00000000001000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b0100_????????1?????: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b0100_???????10?????: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b0100_??????100?????: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b0100_?????1000?????: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b0100_????10000?????: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b0100_???100000?????: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b0100_??1000000?????: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b0100_?10000000?????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b0100_100000000?????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b0100_000000000????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b0100_000000000???10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b0100_000000000??100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b0100_000000000?1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b0100_00000000010000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b0101_???????1??????: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b0101_??????10??????: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b0101_?????100??????: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b0101_????1000??????: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b0101_???10000??????: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b0101_??100000??????: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b0101_?1000000??????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b0101_10000000??????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b0101_00000000?????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b0101_00000000????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b0101_00000000???100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b0101_00000000??1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b0101_00000000?10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b0101_00000000100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b0110_??????1???????: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b0110_?????10???????: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b0110_????100???????: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b0110_???1000???????: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b0110_??10000???????: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b0110_?100000???????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b0110_1000000???????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b0110_0000000??????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b0110_0000000?????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b0110_0000000????100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b0110_0000000???1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b0110_0000000??10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b0110_0000000?100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b0110_00000001000000: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b0111_?????1????????: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b0111_????10????????: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b0111_???100????????: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b0111_??1000????????: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b0111_?10000????????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b0111_100000????????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b0111_000000???????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b0111_000000??????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b0111_000000?????100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b0111_000000????1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b0111_000000???10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b0111_000000??100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b0111_000000?1000000: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b0111_00000010000000: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b1000_????1?????????: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b1000_???10?????????: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b1000_??100?????????: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b1000_?1000?????????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b1000_10000?????????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b1000_00000????????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b1000_00000???????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b1000_00000??????100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b1000_00000?????1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b1000_00000????10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b1000_00000???100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b1000_00000??1000000: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b1000_00000?10000000: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b1000_00000100000000: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b1001_???1??????????: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b1001_??10??????????: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b1001_?100??????????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b1001_1000??????????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b1001_0000?????????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b1001_0000????????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b1001_0000???????100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b1001_0000??????1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b1001_0000?????10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b1001_0000????100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b1001_0000???1000000: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b1001_0000??10000000: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b1001_0000?100000000: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b1001_00001000000000: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b1010_??1???????????: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b1010_?10???????????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b1010_100???????????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b1010_000??????????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b1010_000?????????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b1010_000????????100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b1010_000???????1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b1010_000??????10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b1010_000?????100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b1010_000????1000000: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b1010_000???10000000: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b1010_000??100000000: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b1010_000?1000000000: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b1010_00010000000000: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b1011_?1????????????: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b1011_10????????????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b1011_00???????????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b1011_00??????????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b1011_00?????????100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b1011_00????????1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b1011_00???????10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b1011_00??????100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b1011_00?????1000000: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b1011_00????10000000: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b1011_00???100000000: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b1011_00??1000000000: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b1011_00?10000000000: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b1011_00100000000000: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b1100_1?????????????: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    18'b1100_0????????????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b1100_0???????????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b1100_0??????????100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b1100_0?????????1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b1100_0????????10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b1100_0???????100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b1100_0??????1000000: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b1100_0?????10000000: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b1100_0????100000000: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b1100_0???1000000000: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b1100_0??10000000000: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b1100_0?100000000000: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b1100_01000000000000: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b1101_?????????????1: begin sel_one_hot_n= 14'b00000000000001; tag_o = (lg_inputs_p) ' (0); end
    18'b1101_????????????10: begin sel_one_hot_n= 14'b00000000000010; tag_o = (lg_inputs_p) ' (1); end
    18'b1101_???????????100: begin sel_one_hot_n= 14'b00000000000100; tag_o = (lg_inputs_p) ' (2); end
    18'b1101_??????????1000: begin sel_one_hot_n= 14'b00000000001000; tag_o = (lg_inputs_p) ' (3); end
    18'b1101_?????????10000: begin sel_one_hot_n= 14'b00000000010000; tag_o = (lg_inputs_p) ' (4); end
    18'b1101_????????100000: begin sel_one_hot_n= 14'b00000000100000; tag_o = (lg_inputs_p) ' (5); end
    18'b1101_???????1000000: begin sel_one_hot_n= 14'b00000001000000; tag_o = (lg_inputs_p) ' (6); end
    18'b1101_??????10000000: begin sel_one_hot_n= 14'b00000010000000; tag_o = (lg_inputs_p) ' (7); end
    18'b1101_?????100000000: begin sel_one_hot_n= 14'b00000100000000; tag_o = (lg_inputs_p) ' (8); end
    18'b1101_????1000000000: begin sel_one_hot_n= 14'b00001000000000; tag_o = (lg_inputs_p) ' (9); end
    18'b1101_???10000000000: begin sel_one_hot_n= 14'b00010000000000; tag_o = (lg_inputs_p) ' (10); end
    18'b1101_??100000000000: begin sel_one_hot_n= 14'b00100000000000; tag_o = (lg_inputs_p) ' (11); end
    18'b1101_?1000000000000: begin sel_one_hot_n= 14'b01000000000000; tag_o = (lg_inputs_p) ' (12); end
    18'b1101_10000000000000: begin sel_one_hot_n= 14'b10000000000000; tag_o = (lg_inputs_p) ' (13); end
    default: begin sel_one_hot_n= {14{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {14{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           4'b0000 : hold_on_sr = ( reqs_i == 14'b01000000000000 );
           4'b0001 : hold_on_sr = ( reqs_i == 14'b00100000000000 );
           4'b0010 : hold_on_sr = ( reqs_i == 14'b00010000000000 );
           4'b0011 : hold_on_sr = ( reqs_i == 14'b00001000000000 );
           4'b0100 : hold_on_sr = ( reqs_i == 14'b00000100000000 );
           4'b0101 : hold_on_sr = ( reqs_i == 14'b00000010000000 );
           4'b0110 : hold_on_sr = ( reqs_i == 14'b00000001000000 );
           4'b0111 : hold_on_sr = ( reqs_i == 14'b00000000100000 );
           4'b1000 : hold_on_sr = ( reqs_i == 14'b00000000010000 );
           4'b1001 : hold_on_sr = ( reqs_i == 14'b00000000001000 );
           4'b1010 : hold_on_sr = ( reqs_i == 14'b00000000000100 );
           4'b1011 : hold_on_sr = ( reqs_i == 14'b00000000000010 );
           4'b1100 : hold_on_sr = ( reqs_i == 14'b00000000000001 );
           4'b1101 : hold_on_sr = ( reqs_i == 14'b10000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_14 
    assign reset_on_sr = ( reqs_i == 14'b01000000000000 ) 
                       | ( reqs_i == 14'b00100000000000 ) 
                       | ( reqs_i == 14'b00010000000000 ) 
                       | ( reqs_i == 14'b00001000000000 ) 
                       | ( reqs_i == 14'b00000100000000 ) 
                       | ( reqs_i == 14'b00000010000000 ) 
                       | ( reqs_i == 14'b00000001000000 ) 
                       | ( reqs_i == 14'b00000000100000 ) 
                       | ( reqs_i == 14'b00000000010000 ) 
                       | ( reqs_i == 14'b00000000001000 ) 
                       | ( reqs_i == 14'b00000000000100 ) 
                       | ( reqs_i == 14'b00000000000010 ) 
                       | ( reqs_i == 14'b00000000000001 ) 
                       | ( reqs_i == 14'b10000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_14

if(inputs_p == 15)
begin: inputs_15

logic [15-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    19'b????_000000000000000: begin sel_one_hot_n = 15'b000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    19'b0000_?????????????1?: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b0000_????????????10?: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b0000_???????????100?: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b0000_??????????1000?: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b0000_?????????10000?: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b0000_????????100000?: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b0000_???????1000000?: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b0000_??????10000000?: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b0000_?????100000000?: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b0000_????1000000000?: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b0000_???10000000000?: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b0000_??100000000000?: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b0000_?1000000000000?: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b0000_10000000000000?: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b0000_000000000000001: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b0001_????????????1??: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b0001_???????????10??: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b0001_??????????100??: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b0001_?????????1000??: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b0001_????????10000??: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b0001_???????100000??: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b0001_??????1000000??: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b0001_?????10000000??: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b0001_????100000000??: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b0001_???1000000000??: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b0001_??10000000000??: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b0001_?100000000000??: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b0001_1000000000000??: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b0001_0000000000000?1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b0001_000000000000010: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b0010_???????????1???: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b0010_??????????10???: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b0010_?????????100???: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b0010_????????1000???: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b0010_???????10000???: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b0010_??????100000???: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b0010_?????1000000???: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b0010_????10000000???: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b0010_???100000000???: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b0010_??1000000000???: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b0010_?10000000000???: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b0010_100000000000???: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b0010_000000000000??1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b0010_000000000000?10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b0010_000000000000100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b0011_??????????1????: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b0011_?????????10????: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b0011_????????100????: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b0011_???????1000????: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b0011_??????10000????: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b0011_?????100000????: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b0011_????1000000????: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b0011_???10000000????: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b0011_??100000000????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b0011_?1000000000????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b0011_10000000000????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b0011_00000000000???1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b0011_00000000000??10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b0011_00000000000?100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b0011_000000000001000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b0100_?????????1?????: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b0100_????????10?????: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b0100_???????100?????: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b0100_??????1000?????: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b0100_?????10000?????: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b0100_????100000?????: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b0100_???1000000?????: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b0100_??10000000?????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b0100_?100000000?????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b0100_1000000000?????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b0100_0000000000????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b0100_0000000000???10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b0100_0000000000??100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b0100_0000000000?1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b0100_000000000010000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b0101_????????1??????: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b0101_???????10??????: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b0101_??????100??????: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b0101_?????1000??????: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b0101_????10000??????: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b0101_???100000??????: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b0101_??1000000??????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b0101_?10000000??????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b0101_100000000??????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b0101_000000000?????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b0101_000000000????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b0101_000000000???100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b0101_000000000??1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b0101_000000000?10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b0101_000000000100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b0110_???????1???????: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b0110_??????10???????: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b0110_?????100???????: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b0110_????1000???????: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b0110_???10000???????: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b0110_??100000???????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b0110_?1000000???????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b0110_10000000???????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b0110_00000000??????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b0110_00000000?????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b0110_00000000????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b0110_00000000???1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b0110_00000000??10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b0110_00000000?100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b0110_000000001000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b0111_??????1????????: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b0111_?????10????????: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b0111_????100????????: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b0111_???1000????????: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b0111_??10000????????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b0111_?100000????????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b0111_1000000????????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b0111_0000000???????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b0111_0000000??????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b0111_0000000?????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b0111_0000000????1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b0111_0000000???10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b0111_0000000??100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b0111_0000000?1000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b0111_000000010000000: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b1000_?????1?????????: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b1000_????10?????????: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b1000_???100?????????: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b1000_??1000?????????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b1000_?10000?????????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b1000_100000?????????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b1000_000000????????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b1000_000000???????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b1000_000000??????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b1000_000000?????1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b1000_000000????10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b1000_000000???100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b1000_000000??1000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b1000_000000?10000000: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b1000_000000100000000: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b1001_????1??????????: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b1001_???10??????????: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b1001_??100??????????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b1001_?1000??????????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b1001_10000??????????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b1001_00000?????????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b1001_00000????????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b1001_00000???????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b1001_00000??????1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b1001_00000?????10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b1001_00000????100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b1001_00000???1000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b1001_00000??10000000: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b1001_00000?100000000: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b1001_000001000000000: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b1010_???1???????????: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b1010_??10???????????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b1010_?100???????????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b1010_1000???????????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b1010_0000??????????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b1010_0000?????????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b1010_0000????????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b1010_0000???????1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b1010_0000??????10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b1010_0000?????100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b1010_0000????1000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b1010_0000???10000000: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b1010_0000??100000000: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b1010_0000?1000000000: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b1010_000010000000000: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b1011_??1????????????: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b1011_?10????????????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b1011_100????????????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b1011_000???????????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b1011_000??????????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b1011_000?????????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b1011_000????????1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b1011_000???????10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b1011_000??????100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b1011_000?????1000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b1011_000????10000000: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b1011_000???100000000: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b1011_000??1000000000: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b1011_000?10000000000: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b1011_000100000000000: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b1100_?1?????????????: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b1100_10?????????????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b1100_00????????????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b1100_00???????????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b1100_00??????????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b1100_00?????????1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b1100_00????????10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b1100_00???????100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b1100_00??????1000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b1100_00?????10000000: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b1100_00????100000000: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b1100_00???1000000000: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b1100_00??10000000000: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b1100_00?100000000000: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b1100_001000000000000: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b1101_1??????????????: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    19'b1101_0?????????????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b1101_0????????????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b1101_0???????????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b1101_0??????????1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b1101_0?????????10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b1101_0????????100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b1101_0???????1000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b1101_0??????10000000: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b1101_0?????100000000: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b1101_0????1000000000: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b1101_0???10000000000: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b1101_0??100000000000: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b1101_0?1000000000000: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b1101_010000000000000: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b1110_??????????????1: begin sel_one_hot_n= 15'b000000000000001; tag_o = (lg_inputs_p) ' (0); end
    19'b1110_?????????????10: begin sel_one_hot_n= 15'b000000000000010; tag_o = (lg_inputs_p) ' (1); end
    19'b1110_????????????100: begin sel_one_hot_n= 15'b000000000000100; tag_o = (lg_inputs_p) ' (2); end
    19'b1110_???????????1000: begin sel_one_hot_n= 15'b000000000001000; tag_o = (lg_inputs_p) ' (3); end
    19'b1110_??????????10000: begin sel_one_hot_n= 15'b000000000010000; tag_o = (lg_inputs_p) ' (4); end
    19'b1110_?????????100000: begin sel_one_hot_n= 15'b000000000100000; tag_o = (lg_inputs_p) ' (5); end
    19'b1110_????????1000000: begin sel_one_hot_n= 15'b000000001000000; tag_o = (lg_inputs_p) ' (6); end
    19'b1110_???????10000000: begin sel_one_hot_n= 15'b000000010000000; tag_o = (lg_inputs_p) ' (7); end
    19'b1110_??????100000000: begin sel_one_hot_n= 15'b000000100000000; tag_o = (lg_inputs_p) ' (8); end
    19'b1110_?????1000000000: begin sel_one_hot_n= 15'b000001000000000; tag_o = (lg_inputs_p) ' (9); end
    19'b1110_????10000000000: begin sel_one_hot_n= 15'b000010000000000; tag_o = (lg_inputs_p) ' (10); end
    19'b1110_???100000000000: begin sel_one_hot_n= 15'b000100000000000; tag_o = (lg_inputs_p) ' (11); end
    19'b1110_??1000000000000: begin sel_one_hot_n= 15'b001000000000000; tag_o = (lg_inputs_p) ' (12); end
    19'b1110_?10000000000000: begin sel_one_hot_n= 15'b010000000000000; tag_o = (lg_inputs_p) ' (13); end
    19'b1110_100000000000000: begin sel_one_hot_n= 15'b100000000000000; tag_o = (lg_inputs_p) ' (14); end
    default: begin sel_one_hot_n= {15{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {15{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           4'b0000 : hold_on_sr = ( reqs_i == 15'b010000000000000 );
           4'b0001 : hold_on_sr = ( reqs_i == 15'b001000000000000 );
           4'b0010 : hold_on_sr = ( reqs_i == 15'b000100000000000 );
           4'b0011 : hold_on_sr = ( reqs_i == 15'b000010000000000 );
           4'b0100 : hold_on_sr = ( reqs_i == 15'b000001000000000 );
           4'b0101 : hold_on_sr = ( reqs_i == 15'b000000100000000 );
           4'b0110 : hold_on_sr = ( reqs_i == 15'b000000010000000 );
           4'b0111 : hold_on_sr = ( reqs_i == 15'b000000001000000 );
           4'b1000 : hold_on_sr = ( reqs_i == 15'b000000000100000 );
           4'b1001 : hold_on_sr = ( reqs_i == 15'b000000000010000 );
           4'b1010 : hold_on_sr = ( reqs_i == 15'b000000000001000 );
           4'b1011 : hold_on_sr = ( reqs_i == 15'b000000000000100 );
           4'b1100 : hold_on_sr = ( reqs_i == 15'b000000000000010 );
           4'b1101 : hold_on_sr = ( reqs_i == 15'b000000000000001 );
           4'b1110 : hold_on_sr = ( reqs_i == 15'b100000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_15 
    assign reset_on_sr = ( reqs_i == 15'b010000000000000 ) 
                       | ( reqs_i == 15'b001000000000000 ) 
                       | ( reqs_i == 15'b000100000000000 ) 
                       | ( reqs_i == 15'b000010000000000 ) 
                       | ( reqs_i == 15'b000001000000000 ) 
                       | ( reqs_i == 15'b000000100000000 ) 
                       | ( reqs_i == 15'b000000010000000 ) 
                       | ( reqs_i == 15'b000000001000000 ) 
                       | ( reqs_i == 15'b000000000100000 ) 
                       | ( reqs_i == 15'b000000000010000 ) 
                       | ( reqs_i == 15'b000000000001000 ) 
                       | ( reqs_i == 15'b000000000000100 ) 
                       | ( reqs_i == 15'b000000000000010 ) 
                       | ( reqs_i == 15'b000000000000001 ) 
                       | ( reqs_i == 15'b100000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_15

if(inputs_p == 16)
begin: inputs_16

logic [16-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    20'b????_0000000000000000: begin sel_one_hot_n = 16'b0000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    20'b0000_??????????????1?: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b0000_?????????????10?: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b0000_????????????100?: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b0000_???????????1000?: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b0000_??????????10000?: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b0000_?????????100000?: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b0000_????????1000000?: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b0000_???????10000000?: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b0000_??????100000000?: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b0000_?????1000000000?: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b0000_????10000000000?: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b0000_???100000000000?: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b0000_??1000000000000?: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b0000_?10000000000000?: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b0000_100000000000000?: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b0000_0000000000000001: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b0001_?????????????1??: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b0001_????????????10??: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b0001_???????????100??: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b0001_??????????1000??: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b0001_?????????10000??: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b0001_????????100000??: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b0001_???????1000000??: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b0001_??????10000000??: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b0001_?????100000000??: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b0001_????1000000000??: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b0001_???10000000000??: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b0001_??100000000000??: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b0001_?1000000000000??: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b0001_10000000000000??: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b0001_00000000000000?1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b0001_0000000000000010: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b0010_????????????1???: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b0010_???????????10???: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b0010_??????????100???: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b0010_?????????1000???: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b0010_????????10000???: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b0010_???????100000???: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b0010_??????1000000???: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b0010_?????10000000???: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b0010_????100000000???: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b0010_???1000000000???: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b0010_??10000000000???: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b0010_?100000000000???: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b0010_1000000000000???: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b0010_0000000000000??1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b0010_0000000000000?10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b0010_0000000000000100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b0011_???????????1????: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b0011_??????????10????: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b0011_?????????100????: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b0011_????????1000????: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b0011_???????10000????: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b0011_??????100000????: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b0011_?????1000000????: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b0011_????10000000????: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b0011_???100000000????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b0011_??1000000000????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b0011_?10000000000????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b0011_100000000000????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b0011_000000000000???1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b0011_000000000000??10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b0011_000000000000?100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b0011_0000000000001000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b0100_??????????1?????: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b0100_?????????10?????: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b0100_????????100?????: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b0100_???????1000?????: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b0100_??????10000?????: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b0100_?????100000?????: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b0100_????1000000?????: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b0100_???10000000?????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b0100_??100000000?????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b0100_?1000000000?????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b0100_10000000000?????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b0100_00000000000????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b0100_00000000000???10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b0100_00000000000??100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b0100_00000000000?1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b0100_0000000000010000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b0101_?????????1??????: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b0101_????????10??????: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b0101_???????100??????: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b0101_??????1000??????: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b0101_?????10000??????: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b0101_????100000??????: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b0101_???1000000??????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b0101_??10000000??????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b0101_?100000000??????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b0101_1000000000??????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b0101_0000000000?????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b0101_0000000000????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b0101_0000000000???100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b0101_0000000000??1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b0101_0000000000?10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b0101_0000000000100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b0110_????????1???????: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b0110_???????10???????: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b0110_??????100???????: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b0110_?????1000???????: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b0110_????10000???????: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b0110_???100000???????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b0110_??1000000???????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b0110_?10000000???????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b0110_100000000???????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b0110_000000000??????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b0110_000000000?????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b0110_000000000????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b0110_000000000???1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b0110_000000000??10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b0110_000000000?100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b0110_0000000001000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b0111_???????1????????: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b0111_??????10????????: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b0111_?????100????????: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b0111_????1000????????: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b0111_???10000????????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b0111_??100000????????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b0111_?1000000????????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b0111_10000000????????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b0111_00000000???????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b0111_00000000??????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b0111_00000000?????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b0111_00000000????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b0111_00000000???10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b0111_00000000??100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b0111_00000000?1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b0111_0000000010000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1000_??????1?????????: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b1000_?????10?????????: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b1000_????100?????????: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b1000_???1000?????????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b1000_??10000?????????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b1000_?100000?????????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b1000_1000000?????????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b1000_0000000????????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b1000_0000000???????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b1000_0000000??????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b1000_0000000?????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b1000_0000000????10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b1000_0000000???100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b1000_0000000??1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b1000_0000000?10000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1000_0000000100000000: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b1001_?????1??????????: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b1001_????10??????????: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b1001_???100??????????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b1001_??1000??????????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b1001_?10000??????????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b1001_100000??????????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b1001_000000?????????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b1001_000000????????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b1001_000000???????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b1001_000000??????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b1001_000000?????10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b1001_000000????100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b1001_000000???1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b1001_000000??10000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1001_000000?100000000: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b1001_0000001000000000: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b1010_????1???????????: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b1010_???10???????????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b1010_??100???????????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b1010_?1000???????????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b1010_10000???????????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b1010_00000??????????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b1010_00000?????????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b1010_00000????????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b1010_00000???????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b1010_00000??????10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b1010_00000?????100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b1010_00000????1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b1010_00000???10000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1010_00000??100000000: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b1010_00000?1000000000: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b1010_0000010000000000: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b1011_???1????????????: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b1011_??10????????????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b1011_?100????????????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b1011_1000????????????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b1011_0000???????????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b1011_0000??????????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b1011_0000?????????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b1011_0000????????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b1011_0000???????10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b1011_0000??????100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b1011_0000?????1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b1011_0000????10000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1011_0000???100000000: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b1011_0000??1000000000: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b1011_0000?10000000000: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b1011_0000100000000000: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b1100_??1?????????????: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b1100_?10?????????????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b1100_100?????????????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b1100_000????????????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b1100_000???????????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b1100_000??????????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b1100_000?????????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b1100_000????????10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b1100_000???????100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b1100_000??????1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b1100_000?????10000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1100_000????100000000: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b1100_000???1000000000: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b1100_000??10000000000: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b1100_000?100000000000: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b1100_0001000000000000: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b1101_?1??????????????: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b1101_10??????????????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b1101_00?????????????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b1101_00????????????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b1101_00???????????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b1101_00??????????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b1101_00?????????10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b1101_00????????100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b1101_00???????1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b1101_00??????10000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1101_00?????100000000: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b1101_00????1000000000: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b1101_00???10000000000: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b1101_00??100000000000: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b1101_00?1000000000000: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b1101_0010000000000000: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b1110_1???????????????: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    20'b1110_0??????????????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b1110_0?????????????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b1110_0????????????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b1110_0???????????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b1110_0??????????10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b1110_0?????????100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b1110_0????????1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b1110_0???????10000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1110_0??????100000000: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b1110_0?????1000000000: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b1110_0????10000000000: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b1110_0???100000000000: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b1110_0??1000000000000: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b1110_0?10000000000000: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b1110_0100000000000000: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b1111_???????????????1: begin sel_one_hot_n= 16'b0000000000000001; tag_o = (lg_inputs_p) ' (0); end
    20'b1111_??????????????10: begin sel_one_hot_n= 16'b0000000000000010; tag_o = (lg_inputs_p) ' (1); end
    20'b1111_?????????????100: begin sel_one_hot_n= 16'b0000000000000100; tag_o = (lg_inputs_p) ' (2); end
    20'b1111_????????????1000: begin sel_one_hot_n= 16'b0000000000001000; tag_o = (lg_inputs_p) ' (3); end
    20'b1111_???????????10000: begin sel_one_hot_n= 16'b0000000000010000; tag_o = (lg_inputs_p) ' (4); end
    20'b1111_??????????100000: begin sel_one_hot_n= 16'b0000000000100000; tag_o = (lg_inputs_p) ' (5); end
    20'b1111_?????????1000000: begin sel_one_hot_n= 16'b0000000001000000; tag_o = (lg_inputs_p) ' (6); end
    20'b1111_????????10000000: begin sel_one_hot_n= 16'b0000000010000000; tag_o = (lg_inputs_p) ' (7); end
    20'b1111_???????100000000: begin sel_one_hot_n= 16'b0000000100000000; tag_o = (lg_inputs_p) ' (8); end
    20'b1111_??????1000000000: begin sel_one_hot_n= 16'b0000001000000000; tag_o = (lg_inputs_p) ' (9); end
    20'b1111_?????10000000000: begin sel_one_hot_n= 16'b0000010000000000; tag_o = (lg_inputs_p) ' (10); end
    20'b1111_????100000000000: begin sel_one_hot_n= 16'b0000100000000000; tag_o = (lg_inputs_p) ' (11); end
    20'b1111_???1000000000000: begin sel_one_hot_n= 16'b0001000000000000; tag_o = (lg_inputs_p) ' (12); end
    20'b1111_??10000000000000: begin sel_one_hot_n= 16'b0010000000000000; tag_o = (lg_inputs_p) ' (13); end
    20'b1111_?100000000000000: begin sel_one_hot_n= 16'b0100000000000000; tag_o = (lg_inputs_p) ' (14); end
    20'b1111_1000000000000000: begin sel_one_hot_n= 16'b1000000000000000; tag_o = (lg_inputs_p) ' (15); end
    default: begin sel_one_hot_n= {16{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {16{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           4'b0000 : hold_on_sr = ( reqs_i == 16'b0100000000000000 );
           4'b0001 : hold_on_sr = ( reqs_i == 16'b0010000000000000 );
           4'b0010 : hold_on_sr = ( reqs_i == 16'b0001000000000000 );
           4'b0011 : hold_on_sr = ( reqs_i == 16'b0000100000000000 );
           4'b0100 : hold_on_sr = ( reqs_i == 16'b0000010000000000 );
           4'b0101 : hold_on_sr = ( reqs_i == 16'b0000001000000000 );
           4'b0110 : hold_on_sr = ( reqs_i == 16'b0000000100000000 );
           4'b0111 : hold_on_sr = ( reqs_i == 16'b0000000010000000 );
           4'b1000 : hold_on_sr = ( reqs_i == 16'b0000000001000000 );
           4'b1001 : hold_on_sr = ( reqs_i == 16'b0000000000100000 );
           4'b1010 : hold_on_sr = ( reqs_i == 16'b0000000000010000 );
           4'b1011 : hold_on_sr = ( reqs_i == 16'b0000000000001000 );
           4'b1100 : hold_on_sr = ( reqs_i == 16'b0000000000000100 );
           4'b1101 : hold_on_sr = ( reqs_i == 16'b0000000000000010 );
           4'b1110 : hold_on_sr = ( reqs_i == 16'b0000000000000001 );
           default: hold_on_sr = ( reqs_i == 16'b1000000000000000 );
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_16 
    assign reset_on_sr = ( reqs_i == 16'b0100000000000000 ) 
                       | ( reqs_i == 16'b0010000000000000 ) 
                       | ( reqs_i == 16'b0001000000000000 ) 
                       | ( reqs_i == 16'b0000100000000000 ) 
                       | ( reqs_i == 16'b0000010000000000 ) 
                       | ( reqs_i == 16'b0000001000000000 ) 
                       | ( reqs_i == 16'b0000000100000000 ) 
                       | ( reqs_i == 16'b0000000010000000 ) 
                       | ( reqs_i == 16'b0000000001000000 ) 
                       | ( reqs_i == 16'b0000000000100000 ) 
                       | ( reqs_i == 16'b0000000000010000 ) 
                       | ( reqs_i == 16'b0000000000001000 ) 
                       | ( reqs_i == 16'b0000000000000100 ) 
                       | ( reqs_i == 16'b0000000000000010 ) 
                       | ( reqs_i == 16'b0000000000000001 ) 
                       | ( reqs_i == 16'b1000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_16

if(inputs_p == 17)
begin: inputs_17

logic [17-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    22'b?????_00000000000000000: begin sel_one_hot_n = 17'b00000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    22'b00000_???????????????1?: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b00000_??????????????10?: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b00000_?????????????100?: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b00000_????????????1000?: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b00000_???????????10000?: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b00000_??????????100000?: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b00000_?????????1000000?: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b00000_????????10000000?: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b00000_???????100000000?: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b00000_??????1000000000?: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b00000_?????10000000000?: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b00000_????100000000000?: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b00000_???1000000000000?: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b00000_??10000000000000?: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b00000_?100000000000000?: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b00000_1000000000000000?: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b00000_00000000000000001: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b00001_??????????????1??: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b00001_?????????????10??: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b00001_????????????100??: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b00001_???????????1000??: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b00001_??????????10000??: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b00001_?????????100000??: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b00001_????????1000000??: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b00001_???????10000000??: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b00001_??????100000000??: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b00001_?????1000000000??: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b00001_????10000000000??: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b00001_???100000000000??: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b00001_??1000000000000??: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b00001_?10000000000000??: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b00001_100000000000000??: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b00001_000000000000000?1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b00001_00000000000000010: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b00010_?????????????1???: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b00010_????????????10???: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b00010_???????????100???: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b00010_??????????1000???: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b00010_?????????10000???: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b00010_????????100000???: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b00010_???????1000000???: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b00010_??????10000000???: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b00010_?????100000000???: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b00010_????1000000000???: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b00010_???10000000000???: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b00010_??100000000000???: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b00010_?1000000000000???: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b00010_10000000000000???: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b00010_00000000000000??1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b00010_00000000000000?10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b00010_00000000000000100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b00011_????????????1????: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b00011_???????????10????: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b00011_??????????100????: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b00011_?????????1000????: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b00011_????????10000????: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b00011_???????100000????: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b00011_??????1000000????: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b00011_?????10000000????: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b00011_????100000000????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b00011_???1000000000????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b00011_??10000000000????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b00011_?100000000000????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b00011_1000000000000????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b00011_0000000000000???1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b00011_0000000000000??10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b00011_0000000000000?100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b00011_00000000000001000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b00100_???????????1?????: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b00100_??????????10?????: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b00100_?????????100?????: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b00100_????????1000?????: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b00100_???????10000?????: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b00100_??????100000?????: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b00100_?????1000000?????: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b00100_????10000000?????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b00100_???100000000?????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b00100_??1000000000?????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b00100_?10000000000?????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b00100_100000000000?????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b00100_000000000000????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b00100_000000000000???10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b00100_000000000000??100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b00100_000000000000?1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b00100_00000000000010000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b00101_??????????1??????: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b00101_?????????10??????: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b00101_????????100??????: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b00101_???????1000??????: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b00101_??????10000??????: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b00101_?????100000??????: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b00101_????1000000??????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b00101_???10000000??????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b00101_??100000000??????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b00101_?1000000000??????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b00101_10000000000??????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b00101_00000000000?????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b00101_00000000000????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b00101_00000000000???100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b00101_00000000000??1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b00101_00000000000?10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b00101_00000000000100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b00110_?????????1???????: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b00110_????????10???????: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b00110_???????100???????: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b00110_??????1000???????: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b00110_?????10000???????: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b00110_????100000???????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b00110_???1000000???????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b00110_??10000000???????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b00110_?100000000???????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b00110_1000000000???????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b00110_0000000000??????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b00110_0000000000?????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b00110_0000000000????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b00110_0000000000???1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b00110_0000000000??10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b00110_0000000000?100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b00110_00000000001000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b00111_????????1????????: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b00111_???????10????????: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b00111_??????100????????: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b00111_?????1000????????: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b00111_????10000????????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b00111_???100000????????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b00111_??1000000????????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b00111_?10000000????????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b00111_100000000????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b00111_000000000???????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b00111_000000000??????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b00111_000000000?????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b00111_000000000????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b00111_000000000???10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b00111_000000000??100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b00111_000000000?1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b00111_00000000010000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01000_???????1?????????: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b01000_??????10?????????: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b01000_?????100?????????: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b01000_????1000?????????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b01000_???10000?????????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b01000_??100000?????????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b01000_?1000000?????????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b01000_10000000?????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b01000_00000000????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b01000_00000000???????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b01000_00000000??????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b01000_00000000?????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b01000_00000000????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b01000_00000000???100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b01000_00000000??1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b01000_00000000?10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01000_00000000100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b01001_??????1??????????: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b01001_?????10??????????: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b01001_????100??????????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b01001_???1000??????????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b01001_??10000??????????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b01001_?100000??????????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b01001_1000000??????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b01001_0000000?????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b01001_0000000????????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b01001_0000000???????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b01001_0000000??????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b01001_0000000?????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b01001_0000000????100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b01001_0000000???1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b01001_0000000??10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01001_0000000?100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b01001_00000001000000000: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b01010_?????1???????????: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b01010_????10???????????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b01010_???100???????????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b01010_??1000???????????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b01010_?10000???????????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b01010_100000???????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b01010_000000??????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b01010_000000?????????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b01010_000000????????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b01010_000000???????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b01010_000000??????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b01010_000000?????100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b01010_000000????1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b01010_000000???10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01010_000000??100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b01010_000000?1000000000: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b01010_00000010000000000: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b01011_????1????????????: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b01011_???10????????????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b01011_??100????????????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b01011_?1000????????????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b01011_10000????????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b01011_00000???????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b01011_00000??????????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b01011_00000?????????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b01011_00000????????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b01011_00000???????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b01011_00000??????100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b01011_00000?????1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b01011_00000????10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01011_00000???100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b01011_00000??1000000000: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b01011_00000?10000000000: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b01011_00000100000000000: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b01100_???1?????????????: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b01100_??10?????????????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b01100_?100?????????????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b01100_1000?????????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b01100_0000????????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b01100_0000???????????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b01100_0000??????????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b01100_0000?????????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b01100_0000????????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b01100_0000???????100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b01100_0000??????1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b01100_0000?????10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01100_0000????100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b01100_0000???1000000000: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b01100_0000??10000000000: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b01100_0000?100000000000: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b01100_00001000000000000: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b01101_??1??????????????: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b01101_?10??????????????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b01101_100??????????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b01101_000?????????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b01101_000????????????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b01101_000???????????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b01101_000??????????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b01101_000?????????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b01101_000????????100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b01101_000???????1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b01101_000??????10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01101_000?????100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b01101_000????1000000000: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b01101_000???10000000000: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b01101_000??100000000000: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b01101_000?1000000000000: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b01101_00010000000000000: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b01110_?1???????????????: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b01110_10???????????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b01110_00??????????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b01110_00?????????????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b01110_00????????????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b01110_00???????????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b01110_00??????????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b01110_00?????????100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b01110_00????????1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b01110_00???????10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01110_00??????100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b01110_00?????1000000000: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b01110_00????10000000000: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b01110_00???100000000000: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b01110_00??1000000000000: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b01110_00?10000000000000: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b01110_00100000000000000: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b01111_1????????????????: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    22'b01111_0???????????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b01111_0??????????????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b01111_0?????????????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b01111_0????????????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b01111_0???????????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b01111_0??????????100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b01111_0?????????1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b01111_0????????10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b01111_0???????100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b01111_0??????1000000000: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b01111_0?????10000000000: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b01111_0????100000000000: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b01111_0???1000000000000: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b01111_0??10000000000000: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b01111_0?100000000000000: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b01111_01000000000000000: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b10000_????????????????1: begin sel_one_hot_n= 17'b00000000000000001; tag_o = (lg_inputs_p) ' (0); end
    22'b10000_???????????????10: begin sel_one_hot_n= 17'b00000000000000010; tag_o = (lg_inputs_p) ' (1); end
    22'b10000_??????????????100: begin sel_one_hot_n= 17'b00000000000000100; tag_o = (lg_inputs_p) ' (2); end
    22'b10000_?????????????1000: begin sel_one_hot_n= 17'b00000000000001000; tag_o = (lg_inputs_p) ' (3); end
    22'b10000_????????????10000: begin sel_one_hot_n= 17'b00000000000010000; tag_o = (lg_inputs_p) ' (4); end
    22'b10000_???????????100000: begin sel_one_hot_n= 17'b00000000000100000; tag_o = (lg_inputs_p) ' (5); end
    22'b10000_??????????1000000: begin sel_one_hot_n= 17'b00000000001000000; tag_o = (lg_inputs_p) ' (6); end
    22'b10000_?????????10000000: begin sel_one_hot_n= 17'b00000000010000000; tag_o = (lg_inputs_p) ' (7); end
    22'b10000_????????100000000: begin sel_one_hot_n= 17'b00000000100000000; tag_o = (lg_inputs_p) ' (8); end
    22'b10000_???????1000000000: begin sel_one_hot_n= 17'b00000001000000000; tag_o = (lg_inputs_p) ' (9); end
    22'b10000_??????10000000000: begin sel_one_hot_n= 17'b00000010000000000; tag_o = (lg_inputs_p) ' (10); end
    22'b10000_?????100000000000: begin sel_one_hot_n= 17'b00000100000000000; tag_o = (lg_inputs_p) ' (11); end
    22'b10000_????1000000000000: begin sel_one_hot_n= 17'b00001000000000000; tag_o = (lg_inputs_p) ' (12); end
    22'b10000_???10000000000000: begin sel_one_hot_n= 17'b00010000000000000; tag_o = (lg_inputs_p) ' (13); end
    22'b10000_??100000000000000: begin sel_one_hot_n= 17'b00100000000000000; tag_o = (lg_inputs_p) ' (14); end
    22'b10000_?1000000000000000: begin sel_one_hot_n= 17'b01000000000000000; tag_o = (lg_inputs_p) ' (15); end
    22'b10000_10000000000000000: begin sel_one_hot_n= 17'b10000000000000000; tag_o = (lg_inputs_p) ' (16); end
    default: begin sel_one_hot_n= {17{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {17{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           5'b00000 : hold_on_sr = ( reqs_i == 17'b01000000000000000 );
           5'b00001 : hold_on_sr = ( reqs_i == 17'b00100000000000000 );
           5'b00010 : hold_on_sr = ( reqs_i == 17'b00010000000000000 );
           5'b00011 : hold_on_sr = ( reqs_i == 17'b00001000000000000 );
           5'b00100 : hold_on_sr = ( reqs_i == 17'b00000100000000000 );
           5'b00101 : hold_on_sr = ( reqs_i == 17'b00000010000000000 );
           5'b00110 : hold_on_sr = ( reqs_i == 17'b00000001000000000 );
           5'b00111 : hold_on_sr = ( reqs_i == 17'b00000000100000000 );
           5'b01000 : hold_on_sr = ( reqs_i == 17'b00000000010000000 );
           5'b01001 : hold_on_sr = ( reqs_i == 17'b00000000001000000 );
           5'b01010 : hold_on_sr = ( reqs_i == 17'b00000000000100000 );
           5'b01011 : hold_on_sr = ( reqs_i == 17'b00000000000010000 );
           5'b01100 : hold_on_sr = ( reqs_i == 17'b00000000000001000 );
           5'b01101 : hold_on_sr = ( reqs_i == 17'b00000000000000100 );
           5'b01110 : hold_on_sr = ( reqs_i == 17'b00000000000000010 );
           5'b01111 : hold_on_sr = ( reqs_i == 17'b00000000000000001 );
           5'b10000 : hold_on_sr = ( reqs_i == 17'b10000000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_17 
    assign reset_on_sr = ( reqs_i == 17'b01000000000000000 ) 
                       | ( reqs_i == 17'b00100000000000000 ) 
                       | ( reqs_i == 17'b00010000000000000 ) 
                       | ( reqs_i == 17'b00001000000000000 ) 
                       | ( reqs_i == 17'b00000100000000000 ) 
                       | ( reqs_i == 17'b00000010000000000 ) 
                       | ( reqs_i == 17'b00000001000000000 ) 
                       | ( reqs_i == 17'b00000000100000000 ) 
                       | ( reqs_i == 17'b00000000010000000 ) 
                       | ( reqs_i == 17'b00000000001000000 ) 
                       | ( reqs_i == 17'b00000000000100000 ) 
                       | ( reqs_i == 17'b00000000000010000 ) 
                       | ( reqs_i == 17'b00000000000001000 ) 
                       | ( reqs_i == 17'b00000000000000100 ) 
                       | ( reqs_i == 17'b00000000000000010 ) 
                       | ( reqs_i == 17'b00000000000000001 ) 
                       | ( reqs_i == 17'b10000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_17

if(inputs_p == 18)
begin: inputs_18

logic [18-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    23'b?????_000000000000000000: begin sel_one_hot_n = 18'b000000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    23'b00000_????????????????1?: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b00000_???????????????10?: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b00000_??????????????100?: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b00000_?????????????1000?: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b00000_????????????10000?: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b00000_???????????100000?: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b00000_??????????1000000?: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b00000_?????????10000000?: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b00000_????????100000000?: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b00000_???????1000000000?: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b00000_??????10000000000?: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b00000_?????100000000000?: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b00000_????1000000000000?: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b00000_???10000000000000?: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b00000_??100000000000000?: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b00000_?1000000000000000?: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b00000_10000000000000000?: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b00000_000000000000000001: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b00001_???????????????1??: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b00001_??????????????10??: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b00001_?????????????100??: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b00001_????????????1000??: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b00001_???????????10000??: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b00001_??????????100000??: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b00001_?????????1000000??: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b00001_????????10000000??: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b00001_???????100000000??: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b00001_??????1000000000??: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b00001_?????10000000000??: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b00001_????100000000000??: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b00001_???1000000000000??: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b00001_??10000000000000??: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b00001_?100000000000000??: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b00001_1000000000000000??: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b00001_0000000000000000?1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b00001_000000000000000010: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b00010_??????????????1???: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b00010_?????????????10???: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b00010_????????????100???: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b00010_???????????1000???: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b00010_??????????10000???: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b00010_?????????100000???: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b00010_????????1000000???: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b00010_???????10000000???: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b00010_??????100000000???: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b00010_?????1000000000???: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b00010_????10000000000???: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b00010_???100000000000???: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b00010_??1000000000000???: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b00010_?10000000000000???: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b00010_100000000000000???: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b00010_000000000000000??1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b00010_000000000000000?10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b00010_000000000000000100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b00011_?????????????1????: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b00011_????????????10????: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b00011_???????????100????: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b00011_??????????1000????: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b00011_?????????10000????: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b00011_????????100000????: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b00011_???????1000000????: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b00011_??????10000000????: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b00011_?????100000000????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b00011_????1000000000????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b00011_???10000000000????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b00011_??100000000000????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b00011_?1000000000000????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b00011_10000000000000????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b00011_00000000000000???1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b00011_00000000000000??10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b00011_00000000000000?100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b00011_000000000000001000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b00100_????????????1?????: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b00100_???????????10?????: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b00100_??????????100?????: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b00100_?????????1000?????: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b00100_????????10000?????: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b00100_???????100000?????: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b00100_??????1000000?????: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b00100_?????10000000?????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b00100_????100000000?????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b00100_???1000000000?????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b00100_??10000000000?????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b00100_?100000000000?????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b00100_1000000000000?????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b00100_0000000000000????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b00100_0000000000000???10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b00100_0000000000000??100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b00100_0000000000000?1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b00100_000000000000010000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b00101_???????????1??????: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b00101_??????????10??????: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b00101_?????????100??????: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b00101_????????1000??????: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b00101_???????10000??????: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b00101_??????100000??????: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b00101_?????1000000??????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b00101_????10000000??????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b00101_???100000000??????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b00101_??1000000000??????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b00101_?10000000000??????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b00101_100000000000??????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b00101_000000000000?????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b00101_000000000000????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b00101_000000000000???100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b00101_000000000000??1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b00101_000000000000?10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b00101_000000000000100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b00110_??????????1???????: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b00110_?????????10???????: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b00110_????????100???????: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b00110_???????1000???????: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b00110_??????10000???????: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b00110_?????100000???????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b00110_????1000000???????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b00110_???10000000???????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b00110_??100000000???????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b00110_?1000000000???????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b00110_10000000000???????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b00110_00000000000??????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b00110_00000000000?????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b00110_00000000000????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b00110_00000000000???1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b00110_00000000000??10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b00110_00000000000?100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b00110_000000000001000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b00111_?????????1????????: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b00111_????????10????????: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b00111_???????100????????: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b00111_??????1000????????: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b00111_?????10000????????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b00111_????100000????????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b00111_???1000000????????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b00111_??10000000????????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b00111_?100000000????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b00111_1000000000????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b00111_0000000000???????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b00111_0000000000??????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b00111_0000000000?????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b00111_0000000000????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b00111_0000000000???10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b00111_0000000000??100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b00111_0000000000?1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b00111_000000000010000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01000_????????1?????????: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b01000_???????10?????????: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b01000_??????100?????????: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b01000_?????1000?????????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b01000_????10000?????????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b01000_???100000?????????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b01000_??1000000?????????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b01000_?10000000?????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b01000_100000000?????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b01000_000000000????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b01000_000000000???????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b01000_000000000??????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b01000_000000000?????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b01000_000000000????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b01000_000000000???100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b01000_000000000??1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b01000_000000000?10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01000_000000000100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b01001_???????1??????????: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b01001_??????10??????????: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b01001_?????100??????????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b01001_????1000??????????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b01001_???10000??????????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b01001_??100000??????????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b01001_?1000000??????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b01001_10000000??????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b01001_00000000?????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b01001_00000000????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b01001_00000000???????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b01001_00000000??????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b01001_00000000?????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b01001_00000000????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b01001_00000000???1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b01001_00000000??10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01001_00000000?100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b01001_000000001000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b01010_??????1???????????: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b01010_?????10???????????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b01010_????100???????????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b01010_???1000???????????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b01010_??10000???????????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b01010_?100000???????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b01010_1000000???????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b01010_0000000??????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b01010_0000000?????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b01010_0000000????????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b01010_0000000???????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b01010_0000000??????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b01010_0000000?????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b01010_0000000????1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b01010_0000000???10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01010_0000000??100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b01010_0000000?1000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b01010_000000010000000000: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b01011_?????1????????????: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b01011_????10????????????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b01011_???100????????????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b01011_??1000????????????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b01011_?10000????????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b01011_100000????????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b01011_000000???????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b01011_000000??????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b01011_000000?????????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b01011_000000????????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b01011_000000???????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b01011_000000??????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b01011_000000?????1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b01011_000000????10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01011_000000???100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b01011_000000??1000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b01011_000000?10000000000: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b01011_000000100000000000: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b01100_????1?????????????: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b01100_???10?????????????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b01100_??100?????????????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b01100_?1000?????????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b01100_10000?????????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b01100_00000????????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b01100_00000???????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b01100_00000??????????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b01100_00000?????????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b01100_00000????????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b01100_00000???????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b01100_00000??????1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b01100_00000?????10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01100_00000????100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b01100_00000???1000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b01100_00000??10000000000: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b01100_00000?100000000000: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b01100_000001000000000000: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b01101_???1??????????????: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b01101_??10??????????????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b01101_?100??????????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b01101_1000??????????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b01101_0000?????????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b01101_0000????????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b01101_0000???????????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b01101_0000??????????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b01101_0000?????????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b01101_0000????????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b01101_0000???????1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b01101_0000??????10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01101_0000?????100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b01101_0000????1000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b01101_0000???10000000000: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b01101_0000??100000000000: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b01101_0000?1000000000000: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b01101_000010000000000000: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b01110_??1???????????????: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b01110_?10???????????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b01110_100???????????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b01110_000??????????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b01110_000?????????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b01110_000????????????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b01110_000???????????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b01110_000??????????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b01110_000?????????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b01110_000????????1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b01110_000???????10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01110_000??????100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b01110_000?????1000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b01110_000????10000000000: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b01110_000???100000000000: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b01110_000??1000000000000: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b01110_000?10000000000000: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b01110_000100000000000000: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b01111_?1????????????????: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b01111_10????????????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b01111_00???????????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b01111_00??????????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b01111_00?????????????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b01111_00????????????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b01111_00???????????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b01111_00??????????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b01111_00?????????1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b01111_00????????10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b01111_00???????100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b01111_00??????1000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b01111_00?????10000000000: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b01111_00????100000000000: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b01111_00???1000000000000: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b01111_00??10000000000000: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b01111_00?100000000000000: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b01111_001000000000000000: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b10000_1?????????????????: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    23'b10000_0????????????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b10000_0???????????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b10000_0??????????????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b10000_0?????????????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b10000_0????????????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b10000_0???????????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b10000_0??????????1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b10000_0?????????10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b10000_0????????100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b10000_0???????1000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b10000_0??????10000000000: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b10000_0?????100000000000: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b10000_0????1000000000000: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b10000_0???10000000000000: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b10000_0??100000000000000: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b10000_0?1000000000000000: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b10000_010000000000000000: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b10001_?????????????????1: begin sel_one_hot_n= 18'b000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    23'b10001_????????????????10: begin sel_one_hot_n= 18'b000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    23'b10001_???????????????100: begin sel_one_hot_n= 18'b000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    23'b10001_??????????????1000: begin sel_one_hot_n= 18'b000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    23'b10001_?????????????10000: begin sel_one_hot_n= 18'b000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    23'b10001_????????????100000: begin sel_one_hot_n= 18'b000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    23'b10001_???????????1000000: begin sel_one_hot_n= 18'b000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    23'b10001_??????????10000000: begin sel_one_hot_n= 18'b000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    23'b10001_?????????100000000: begin sel_one_hot_n= 18'b000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    23'b10001_????????1000000000: begin sel_one_hot_n= 18'b000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    23'b10001_???????10000000000: begin sel_one_hot_n= 18'b000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    23'b10001_??????100000000000: begin sel_one_hot_n= 18'b000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    23'b10001_?????1000000000000: begin sel_one_hot_n= 18'b000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    23'b10001_????10000000000000: begin sel_one_hot_n= 18'b000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    23'b10001_???100000000000000: begin sel_one_hot_n= 18'b000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    23'b10001_??1000000000000000: begin sel_one_hot_n= 18'b001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    23'b10001_?10000000000000000: begin sel_one_hot_n= 18'b010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    23'b10001_100000000000000000: begin sel_one_hot_n= 18'b100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    default: begin sel_one_hot_n= {18{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {18{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           5'b00000 : hold_on_sr = ( reqs_i == 18'b010000000000000000 );
           5'b00001 : hold_on_sr = ( reqs_i == 18'b001000000000000000 );
           5'b00010 : hold_on_sr = ( reqs_i == 18'b000100000000000000 );
           5'b00011 : hold_on_sr = ( reqs_i == 18'b000010000000000000 );
           5'b00100 : hold_on_sr = ( reqs_i == 18'b000001000000000000 );
           5'b00101 : hold_on_sr = ( reqs_i == 18'b000000100000000000 );
           5'b00110 : hold_on_sr = ( reqs_i == 18'b000000010000000000 );
           5'b00111 : hold_on_sr = ( reqs_i == 18'b000000001000000000 );
           5'b01000 : hold_on_sr = ( reqs_i == 18'b000000000100000000 );
           5'b01001 : hold_on_sr = ( reqs_i == 18'b000000000010000000 );
           5'b01010 : hold_on_sr = ( reqs_i == 18'b000000000001000000 );
           5'b01011 : hold_on_sr = ( reqs_i == 18'b000000000000100000 );
           5'b01100 : hold_on_sr = ( reqs_i == 18'b000000000000010000 );
           5'b01101 : hold_on_sr = ( reqs_i == 18'b000000000000001000 );
           5'b01110 : hold_on_sr = ( reqs_i == 18'b000000000000000100 );
           5'b01111 : hold_on_sr = ( reqs_i == 18'b000000000000000010 );
           5'b10000 : hold_on_sr = ( reqs_i == 18'b000000000000000001 );
           5'b10001 : hold_on_sr = ( reqs_i == 18'b100000000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_18 
    assign reset_on_sr = ( reqs_i == 18'b010000000000000000 ) 
                       | ( reqs_i == 18'b001000000000000000 ) 
                       | ( reqs_i == 18'b000100000000000000 ) 
                       | ( reqs_i == 18'b000010000000000000 ) 
                       | ( reqs_i == 18'b000001000000000000 ) 
                       | ( reqs_i == 18'b000000100000000000 ) 
                       | ( reqs_i == 18'b000000010000000000 ) 
                       | ( reqs_i == 18'b000000001000000000 ) 
                       | ( reqs_i == 18'b000000000100000000 ) 
                       | ( reqs_i == 18'b000000000010000000 ) 
                       | ( reqs_i == 18'b000000000001000000 ) 
                       | ( reqs_i == 18'b000000000000100000 ) 
                       | ( reqs_i == 18'b000000000000010000 ) 
                       | ( reqs_i == 18'b000000000000001000 ) 
                       | ( reqs_i == 18'b000000000000000100 ) 
                       | ( reqs_i == 18'b000000000000000010 ) 
                       | ( reqs_i == 18'b000000000000000001 ) 
                       | ( reqs_i == 18'b100000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_18

if(inputs_p == 19)
begin: inputs_19

logic [19-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    24'b?????_0000000000000000000: begin sel_one_hot_n = 19'b0000000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    24'b00000_?????????????????1?: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b00000_????????????????10?: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b00000_???????????????100?: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b00000_??????????????1000?: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b00000_?????????????10000?: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b00000_????????????100000?: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b00000_???????????1000000?: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b00000_??????????10000000?: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b00000_?????????100000000?: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b00000_????????1000000000?: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b00000_???????10000000000?: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b00000_??????100000000000?: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b00000_?????1000000000000?: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b00000_????10000000000000?: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b00000_???100000000000000?: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b00000_??1000000000000000?: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b00000_?10000000000000000?: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b00000_100000000000000000?: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b00000_0000000000000000001: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b00001_????????????????1??: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b00001_???????????????10??: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b00001_??????????????100??: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b00001_?????????????1000??: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b00001_????????????10000??: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b00001_???????????100000??: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b00001_??????????1000000??: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b00001_?????????10000000??: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b00001_????????100000000??: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b00001_???????1000000000??: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b00001_??????10000000000??: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b00001_?????100000000000??: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b00001_????1000000000000??: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b00001_???10000000000000??: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b00001_??100000000000000??: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b00001_?1000000000000000??: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b00001_10000000000000000??: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b00001_00000000000000000?1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b00001_0000000000000000010: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b00010_???????????????1???: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b00010_??????????????10???: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b00010_?????????????100???: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b00010_????????????1000???: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b00010_???????????10000???: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b00010_??????????100000???: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b00010_?????????1000000???: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b00010_????????10000000???: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b00010_???????100000000???: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b00010_??????1000000000???: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b00010_?????10000000000???: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b00010_????100000000000???: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b00010_???1000000000000???: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b00010_??10000000000000???: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b00010_?100000000000000???: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b00010_1000000000000000???: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b00010_0000000000000000??1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b00010_0000000000000000?10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b00010_0000000000000000100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b00011_??????????????1????: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b00011_?????????????10????: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b00011_????????????100????: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b00011_???????????1000????: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b00011_??????????10000????: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b00011_?????????100000????: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b00011_????????1000000????: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b00011_???????10000000????: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b00011_??????100000000????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b00011_?????1000000000????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b00011_????10000000000????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b00011_???100000000000????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b00011_??1000000000000????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b00011_?10000000000000????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b00011_100000000000000????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b00011_000000000000000???1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b00011_000000000000000??10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b00011_000000000000000?100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b00011_0000000000000001000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b00100_?????????????1?????: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b00100_????????????10?????: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b00100_???????????100?????: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b00100_??????????1000?????: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b00100_?????????10000?????: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b00100_????????100000?????: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b00100_???????1000000?????: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b00100_??????10000000?????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b00100_?????100000000?????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b00100_????1000000000?????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b00100_???10000000000?????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b00100_??100000000000?????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b00100_?1000000000000?????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b00100_10000000000000?????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b00100_00000000000000????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b00100_00000000000000???10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b00100_00000000000000??100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b00100_00000000000000?1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b00100_0000000000000010000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b00101_????????????1??????: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b00101_???????????10??????: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b00101_??????????100??????: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b00101_?????????1000??????: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b00101_????????10000??????: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b00101_???????100000??????: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b00101_??????1000000??????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b00101_?????10000000??????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b00101_????100000000??????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b00101_???1000000000??????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b00101_??10000000000??????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b00101_?100000000000??????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b00101_1000000000000??????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b00101_0000000000000?????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b00101_0000000000000????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b00101_0000000000000???100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b00101_0000000000000??1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b00101_0000000000000?10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b00101_0000000000000100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b00110_???????????1???????: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b00110_??????????10???????: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b00110_?????????100???????: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b00110_????????1000???????: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b00110_???????10000???????: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b00110_??????100000???????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b00110_?????1000000???????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b00110_????10000000???????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b00110_???100000000???????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b00110_??1000000000???????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b00110_?10000000000???????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b00110_100000000000???????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b00110_000000000000??????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b00110_000000000000?????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b00110_000000000000????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b00110_000000000000???1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b00110_000000000000??10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b00110_000000000000?100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b00110_0000000000001000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b00111_??????????1????????: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b00111_?????????10????????: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b00111_????????100????????: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b00111_???????1000????????: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b00111_??????10000????????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b00111_?????100000????????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b00111_????1000000????????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b00111_???10000000????????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b00111_??100000000????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b00111_?1000000000????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b00111_10000000000????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b00111_00000000000???????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b00111_00000000000??????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b00111_00000000000?????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b00111_00000000000????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b00111_00000000000???10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b00111_00000000000??100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b00111_00000000000?1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b00111_0000000000010000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01000_?????????1?????????: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b01000_????????10?????????: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b01000_???????100?????????: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b01000_??????1000?????????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b01000_?????10000?????????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b01000_????100000?????????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b01000_???1000000?????????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b01000_??10000000?????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b01000_?100000000?????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b01000_1000000000?????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b01000_0000000000????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b01000_0000000000???????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b01000_0000000000??????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b01000_0000000000?????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b01000_0000000000????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b01000_0000000000???100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b01000_0000000000??1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b01000_0000000000?10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01000_0000000000100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b01001_????????1??????????: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b01001_???????10??????????: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b01001_??????100??????????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b01001_?????1000??????????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b01001_????10000??????????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b01001_???100000??????????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b01001_??1000000??????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b01001_?10000000??????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b01001_100000000??????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b01001_000000000?????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b01001_000000000????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b01001_000000000???????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b01001_000000000??????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b01001_000000000?????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b01001_000000000????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b01001_000000000???1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b01001_000000000??10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01001_000000000?100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b01001_0000000001000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b01010_???????1???????????: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b01010_??????10???????????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b01010_?????100???????????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b01010_????1000???????????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b01010_???10000???????????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b01010_??100000???????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b01010_?1000000???????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b01010_10000000???????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b01010_00000000??????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b01010_00000000?????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b01010_00000000????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b01010_00000000???????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b01010_00000000??????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b01010_00000000?????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b01010_00000000????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b01010_00000000???10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01010_00000000??100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b01010_00000000?1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b01010_0000000010000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b01011_??????1????????????: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b01011_?????10????????????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b01011_????100????????????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b01011_???1000????????????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b01011_??10000????????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b01011_?100000????????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b01011_1000000????????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b01011_0000000???????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b01011_0000000??????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b01011_0000000?????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b01011_0000000????????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b01011_0000000???????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b01011_0000000??????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b01011_0000000?????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b01011_0000000????10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01011_0000000???100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b01011_0000000??1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b01011_0000000?10000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b01011_0000000100000000000: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b01100_?????1?????????????: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b01100_????10?????????????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b01100_???100?????????????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b01100_??1000?????????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b01100_?10000?????????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b01100_100000?????????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b01100_000000????????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b01100_000000???????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b01100_000000??????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b01100_000000?????????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b01100_000000????????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b01100_000000???????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b01100_000000??????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b01100_000000?????10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01100_000000????100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b01100_000000???1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b01100_000000??10000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b01100_000000?100000000000: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b01100_0000001000000000000: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b01101_????1??????????????: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b01101_???10??????????????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b01101_??100??????????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b01101_?1000??????????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b01101_10000??????????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b01101_00000?????????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b01101_00000????????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b01101_00000???????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b01101_00000??????????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b01101_00000?????????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b01101_00000????????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b01101_00000???????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b01101_00000??????10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01101_00000?????100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b01101_00000????1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b01101_00000???10000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b01101_00000??100000000000: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b01101_00000?1000000000000: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b01101_0000010000000000000: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b01110_???1???????????????: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b01110_??10???????????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b01110_?100???????????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b01110_1000???????????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b01110_0000??????????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b01110_0000?????????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b01110_0000????????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b01110_0000???????????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b01110_0000??????????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b01110_0000?????????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b01110_0000????????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b01110_0000???????10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01110_0000??????100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b01110_0000?????1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b01110_0000????10000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b01110_0000???100000000000: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b01110_0000??1000000000000: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b01110_0000?10000000000000: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b01110_0000100000000000000: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b01111_??1????????????????: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b01111_?10????????????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b01111_100????????????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b01111_000???????????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b01111_000??????????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b01111_000?????????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b01111_000????????????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b01111_000???????????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b01111_000??????????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b01111_000?????????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b01111_000????????10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b01111_000???????100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b01111_000??????1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b01111_000?????10000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b01111_000????100000000000: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b01111_000???1000000000000: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b01111_000??10000000000000: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b01111_000?100000000000000: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b01111_0001000000000000000: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b10000_?1?????????????????: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b10000_10?????????????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b10000_00????????????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b10000_00???????????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b10000_00??????????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b10000_00?????????????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b10000_00????????????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b10000_00???????????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b10000_00??????????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b10000_00?????????10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b10000_00????????100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b10000_00???????1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b10000_00??????10000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b10000_00?????100000000000: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b10000_00????1000000000000: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b10000_00???10000000000000: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b10000_00??100000000000000: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b10000_00?1000000000000000: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b10000_0010000000000000000: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b10001_1??????????????????: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    24'b10001_0?????????????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b10001_0????????????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b10001_0???????????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b10001_0??????????????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b10001_0?????????????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b10001_0????????????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b10001_0???????????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b10001_0??????????10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b10001_0?????????100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b10001_0????????1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b10001_0???????10000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b10001_0??????100000000000: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b10001_0?????1000000000000: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b10001_0????10000000000000: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b10001_0???100000000000000: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b10001_0??1000000000000000: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b10001_0?10000000000000000: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b10001_0100000000000000000: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b10010_??????????????????1: begin sel_one_hot_n= 19'b0000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    24'b10010_?????????????????10: begin sel_one_hot_n= 19'b0000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    24'b10010_????????????????100: begin sel_one_hot_n= 19'b0000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    24'b10010_???????????????1000: begin sel_one_hot_n= 19'b0000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    24'b10010_??????????????10000: begin sel_one_hot_n= 19'b0000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    24'b10010_?????????????100000: begin sel_one_hot_n= 19'b0000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    24'b10010_????????????1000000: begin sel_one_hot_n= 19'b0000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    24'b10010_???????????10000000: begin sel_one_hot_n= 19'b0000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    24'b10010_??????????100000000: begin sel_one_hot_n= 19'b0000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    24'b10010_?????????1000000000: begin sel_one_hot_n= 19'b0000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    24'b10010_????????10000000000: begin sel_one_hot_n= 19'b0000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    24'b10010_???????100000000000: begin sel_one_hot_n= 19'b0000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    24'b10010_??????1000000000000: begin sel_one_hot_n= 19'b0000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    24'b10010_?????10000000000000: begin sel_one_hot_n= 19'b0000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    24'b10010_????100000000000000: begin sel_one_hot_n= 19'b0000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    24'b10010_???1000000000000000: begin sel_one_hot_n= 19'b0001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    24'b10010_??10000000000000000: begin sel_one_hot_n= 19'b0010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    24'b10010_?100000000000000000: begin sel_one_hot_n= 19'b0100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    24'b10010_1000000000000000000: begin sel_one_hot_n= 19'b1000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    default: begin sel_one_hot_n= {19{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {19{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           5'b00000 : hold_on_sr = ( reqs_i == 19'b0100000000000000000 );
           5'b00001 : hold_on_sr = ( reqs_i == 19'b0010000000000000000 );
           5'b00010 : hold_on_sr = ( reqs_i == 19'b0001000000000000000 );
           5'b00011 : hold_on_sr = ( reqs_i == 19'b0000100000000000000 );
           5'b00100 : hold_on_sr = ( reqs_i == 19'b0000010000000000000 );
           5'b00101 : hold_on_sr = ( reqs_i == 19'b0000001000000000000 );
           5'b00110 : hold_on_sr = ( reqs_i == 19'b0000000100000000000 );
           5'b00111 : hold_on_sr = ( reqs_i == 19'b0000000010000000000 );
           5'b01000 : hold_on_sr = ( reqs_i == 19'b0000000001000000000 );
           5'b01001 : hold_on_sr = ( reqs_i == 19'b0000000000100000000 );
           5'b01010 : hold_on_sr = ( reqs_i == 19'b0000000000010000000 );
           5'b01011 : hold_on_sr = ( reqs_i == 19'b0000000000001000000 );
           5'b01100 : hold_on_sr = ( reqs_i == 19'b0000000000000100000 );
           5'b01101 : hold_on_sr = ( reqs_i == 19'b0000000000000010000 );
           5'b01110 : hold_on_sr = ( reqs_i == 19'b0000000000000001000 );
           5'b01111 : hold_on_sr = ( reqs_i == 19'b0000000000000000100 );
           5'b10000 : hold_on_sr = ( reqs_i == 19'b0000000000000000010 );
           5'b10001 : hold_on_sr = ( reqs_i == 19'b0000000000000000001 );
           5'b10010 : hold_on_sr = ( reqs_i == 19'b1000000000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_19 
    assign reset_on_sr = ( reqs_i == 19'b0100000000000000000 ) 
                       | ( reqs_i == 19'b0010000000000000000 ) 
                       | ( reqs_i == 19'b0001000000000000000 ) 
                       | ( reqs_i == 19'b0000100000000000000 ) 
                       | ( reqs_i == 19'b0000010000000000000 ) 
                       | ( reqs_i == 19'b0000001000000000000 ) 
                       | ( reqs_i == 19'b0000000100000000000 ) 
                       | ( reqs_i == 19'b0000000010000000000 ) 
                       | ( reqs_i == 19'b0000000001000000000 ) 
                       | ( reqs_i == 19'b0000000000100000000 ) 
                       | ( reqs_i == 19'b0000000000010000000 ) 
                       | ( reqs_i == 19'b0000000000001000000 ) 
                       | ( reqs_i == 19'b0000000000000100000 ) 
                       | ( reqs_i == 19'b0000000000000010000 ) 
                       | ( reqs_i == 19'b0000000000000001000 ) 
                       | ( reqs_i == 19'b0000000000000000100 ) 
                       | ( reqs_i == 19'b0000000000000000010 ) 
                       | ( reqs_i == 19'b0000000000000000001 ) 
                       | ( reqs_i == 19'b1000000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_19

if(inputs_p == 20)
begin: inputs_20

logic [20-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    25'b?????_00000000000000000000: begin sel_one_hot_n = 20'b00000000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    25'b00000_??????????????????1?: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b00000_?????????????????10?: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b00000_????????????????100?: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b00000_???????????????1000?: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b00000_??????????????10000?: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b00000_?????????????100000?: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b00000_????????????1000000?: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b00000_???????????10000000?: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b00000_??????????100000000?: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b00000_?????????1000000000?: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b00000_????????10000000000?: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b00000_???????100000000000?: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b00000_??????1000000000000?: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b00000_?????10000000000000?: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b00000_????100000000000000?: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b00000_???1000000000000000?: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b00000_??10000000000000000?: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b00000_?100000000000000000?: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b00000_1000000000000000000?: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b00000_00000000000000000001: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b00001_?????????????????1??: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b00001_????????????????10??: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b00001_???????????????100??: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b00001_??????????????1000??: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b00001_?????????????10000??: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b00001_????????????100000??: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b00001_???????????1000000??: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b00001_??????????10000000??: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b00001_?????????100000000??: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b00001_????????1000000000??: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b00001_???????10000000000??: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b00001_??????100000000000??: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b00001_?????1000000000000??: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b00001_????10000000000000??: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b00001_???100000000000000??: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b00001_??1000000000000000??: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b00001_?10000000000000000??: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b00001_100000000000000000??: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b00001_000000000000000000?1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b00001_00000000000000000010: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b00010_????????????????1???: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b00010_???????????????10???: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b00010_??????????????100???: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b00010_?????????????1000???: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b00010_????????????10000???: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b00010_???????????100000???: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b00010_??????????1000000???: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b00010_?????????10000000???: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b00010_????????100000000???: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b00010_???????1000000000???: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b00010_??????10000000000???: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b00010_?????100000000000???: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b00010_????1000000000000???: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b00010_???10000000000000???: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b00010_??100000000000000???: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b00010_?1000000000000000???: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b00010_10000000000000000???: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b00010_00000000000000000??1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b00010_00000000000000000?10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b00010_00000000000000000100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b00011_???????????????1????: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b00011_??????????????10????: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b00011_?????????????100????: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b00011_????????????1000????: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b00011_???????????10000????: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b00011_??????????100000????: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b00011_?????????1000000????: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b00011_????????10000000????: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b00011_???????100000000????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b00011_??????1000000000????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b00011_?????10000000000????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b00011_????100000000000????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b00011_???1000000000000????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b00011_??10000000000000????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b00011_?100000000000000????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b00011_1000000000000000????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b00011_0000000000000000???1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b00011_0000000000000000??10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b00011_0000000000000000?100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b00011_00000000000000001000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b00100_??????????????1?????: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b00100_?????????????10?????: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b00100_????????????100?????: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b00100_???????????1000?????: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b00100_??????????10000?????: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b00100_?????????100000?????: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b00100_????????1000000?????: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b00100_???????10000000?????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b00100_??????100000000?????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b00100_?????1000000000?????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b00100_????10000000000?????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b00100_???100000000000?????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b00100_??1000000000000?????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b00100_?10000000000000?????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b00100_100000000000000?????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b00100_000000000000000????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b00100_000000000000000???10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b00100_000000000000000??100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b00100_000000000000000?1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b00100_00000000000000010000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b00101_?????????????1??????: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b00101_????????????10??????: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b00101_???????????100??????: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b00101_??????????1000??????: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b00101_?????????10000??????: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b00101_????????100000??????: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b00101_???????1000000??????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b00101_??????10000000??????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b00101_?????100000000??????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b00101_????1000000000??????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b00101_???10000000000??????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b00101_??100000000000??????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b00101_?1000000000000??????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b00101_10000000000000??????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b00101_00000000000000?????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b00101_00000000000000????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b00101_00000000000000???100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b00101_00000000000000??1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b00101_00000000000000?10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b00101_00000000000000100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b00110_????????????1???????: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b00110_???????????10???????: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b00110_??????????100???????: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b00110_?????????1000???????: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b00110_????????10000???????: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b00110_???????100000???????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b00110_??????1000000???????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b00110_?????10000000???????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b00110_????100000000???????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b00110_???1000000000???????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b00110_??10000000000???????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b00110_?100000000000???????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b00110_1000000000000???????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b00110_0000000000000??????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b00110_0000000000000?????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b00110_0000000000000????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b00110_0000000000000???1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b00110_0000000000000??10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b00110_0000000000000?100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b00110_00000000000001000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b00111_???????????1????????: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b00111_??????????10????????: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b00111_?????????100????????: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b00111_????????1000????????: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b00111_???????10000????????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b00111_??????100000????????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b00111_?????1000000????????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b00111_????10000000????????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b00111_???100000000????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b00111_??1000000000????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b00111_?10000000000????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b00111_100000000000????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b00111_000000000000???????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b00111_000000000000??????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b00111_000000000000?????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b00111_000000000000????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b00111_000000000000???10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b00111_000000000000??100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b00111_000000000000?1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b00111_00000000000010000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01000_??????????1?????????: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b01000_?????????10?????????: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b01000_????????100?????????: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b01000_???????1000?????????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b01000_??????10000?????????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b01000_?????100000?????????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b01000_????1000000?????????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b01000_???10000000?????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b01000_??100000000?????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b01000_?1000000000?????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b01000_10000000000?????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b01000_00000000000????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b01000_00000000000???????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b01000_00000000000??????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b01000_00000000000?????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b01000_00000000000????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b01000_00000000000???100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b01000_00000000000??1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b01000_00000000000?10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01000_00000000000100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b01001_?????????1??????????: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b01001_????????10??????????: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b01001_???????100??????????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b01001_??????1000??????????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b01001_?????10000??????????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b01001_????100000??????????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b01001_???1000000??????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b01001_??10000000??????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b01001_?100000000??????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b01001_1000000000??????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b01001_0000000000?????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b01001_0000000000????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b01001_0000000000???????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b01001_0000000000??????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b01001_0000000000?????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b01001_0000000000????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b01001_0000000000???1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b01001_0000000000??10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01001_0000000000?100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b01001_00000000001000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b01010_????????1???????????: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b01010_???????10???????????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b01010_??????100???????????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b01010_?????1000???????????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b01010_????10000???????????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b01010_???100000???????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b01010_??1000000???????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b01010_?10000000???????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b01010_100000000???????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b01010_000000000??????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b01010_000000000?????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b01010_000000000????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b01010_000000000???????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b01010_000000000??????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b01010_000000000?????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b01010_000000000????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b01010_000000000???10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01010_000000000??100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b01010_000000000?1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b01010_00000000010000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b01011_???????1????????????: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b01011_??????10????????????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b01011_?????100????????????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b01011_????1000????????????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b01011_???10000????????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b01011_??100000????????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b01011_?1000000????????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b01011_10000000????????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b01011_00000000???????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b01011_00000000??????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b01011_00000000?????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b01011_00000000????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b01011_00000000???????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b01011_00000000??????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b01011_00000000?????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b01011_00000000????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01011_00000000???100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b01011_00000000??1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b01011_00000000?10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b01011_00000000100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b01100_??????1?????????????: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b01100_?????10?????????????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b01100_????100?????????????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b01100_???1000?????????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b01100_??10000?????????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b01100_?100000?????????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b01100_1000000?????????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b01100_0000000????????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b01100_0000000???????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b01100_0000000??????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b01100_0000000?????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b01100_0000000????????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b01100_0000000???????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b01100_0000000??????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b01100_0000000?????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01100_0000000????100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b01100_0000000???1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b01100_0000000??10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b01100_0000000?100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b01100_00000001000000000000: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b01101_?????1??????????????: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b01101_????10??????????????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b01101_???100??????????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b01101_??1000??????????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b01101_?10000??????????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b01101_100000??????????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b01101_000000?????????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b01101_000000????????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b01101_000000???????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b01101_000000??????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b01101_000000?????????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b01101_000000????????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b01101_000000???????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b01101_000000??????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01101_000000?????100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b01101_000000????1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b01101_000000???10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b01101_000000??100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b01101_000000?1000000000000: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b01101_00000010000000000000: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b01110_????1???????????????: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b01110_???10???????????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b01110_??100???????????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b01110_?1000???????????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b01110_10000???????????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b01110_00000??????????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b01110_00000?????????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b01110_00000????????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b01110_00000???????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b01110_00000??????????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b01110_00000?????????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b01110_00000????????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b01110_00000???????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01110_00000??????100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b01110_00000?????1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b01110_00000????10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b01110_00000???100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b01110_00000??1000000000000: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b01110_00000?10000000000000: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b01110_00000100000000000000: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b01111_???1????????????????: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b01111_??10????????????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b01111_?100????????????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b01111_1000????????????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b01111_0000???????????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b01111_0000??????????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b01111_0000?????????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b01111_0000????????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b01111_0000???????????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b01111_0000??????????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b01111_0000?????????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b01111_0000????????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b01111_0000???????100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b01111_0000??????1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b01111_0000?????10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b01111_0000????100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b01111_0000???1000000000000: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b01111_0000??10000000000000: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b01111_0000?100000000000000: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b01111_00001000000000000000: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b10000_??1?????????????????: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b10000_?10?????????????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b10000_100?????????????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b10000_000????????????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b10000_000???????????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b10000_000??????????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b10000_000?????????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b10000_000????????????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b10000_000???????????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b10000_000??????????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b10000_000?????????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b10000_000????????100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b10000_000???????1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b10000_000??????10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b10000_000?????100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b10000_000????1000000000000: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b10000_000???10000000000000: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b10000_000??100000000000000: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b10000_000?1000000000000000: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b10000_00010000000000000000: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b10001_?1??????????????????: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b10001_10??????????????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b10001_00?????????????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b10001_00????????????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b10001_00???????????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b10001_00??????????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b10001_00?????????????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b10001_00????????????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b10001_00???????????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b10001_00??????????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b10001_00?????????100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b10001_00????????1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b10001_00???????10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b10001_00??????100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b10001_00?????1000000000000: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b10001_00????10000000000000: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b10001_00???100000000000000: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b10001_00??1000000000000000: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b10001_00?10000000000000000: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b10001_00100000000000000000: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b10010_1???????????????????: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    25'b10010_0??????????????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b10010_0?????????????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b10010_0????????????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b10010_0???????????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b10010_0??????????????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b10010_0?????????????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b10010_0????????????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b10010_0???????????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b10010_0??????????100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b10010_0?????????1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b10010_0????????10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b10010_0???????100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b10010_0??????1000000000000: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b10010_0?????10000000000000: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b10010_0????100000000000000: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b10010_0???1000000000000000: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b10010_0??10000000000000000: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b10010_0?100000000000000000: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b10010_01000000000000000000: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b10011_???????????????????1: begin sel_one_hot_n= 20'b00000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    25'b10011_??????????????????10: begin sel_one_hot_n= 20'b00000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    25'b10011_?????????????????100: begin sel_one_hot_n= 20'b00000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    25'b10011_????????????????1000: begin sel_one_hot_n= 20'b00000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    25'b10011_???????????????10000: begin sel_one_hot_n= 20'b00000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    25'b10011_??????????????100000: begin sel_one_hot_n= 20'b00000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    25'b10011_?????????????1000000: begin sel_one_hot_n= 20'b00000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    25'b10011_????????????10000000: begin sel_one_hot_n= 20'b00000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    25'b10011_???????????100000000: begin sel_one_hot_n= 20'b00000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    25'b10011_??????????1000000000: begin sel_one_hot_n= 20'b00000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    25'b10011_?????????10000000000: begin sel_one_hot_n= 20'b00000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    25'b10011_????????100000000000: begin sel_one_hot_n= 20'b00000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    25'b10011_???????1000000000000: begin sel_one_hot_n= 20'b00000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    25'b10011_??????10000000000000: begin sel_one_hot_n= 20'b00000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    25'b10011_?????100000000000000: begin sel_one_hot_n= 20'b00000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    25'b10011_????1000000000000000: begin sel_one_hot_n= 20'b00001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    25'b10011_???10000000000000000: begin sel_one_hot_n= 20'b00010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    25'b10011_??100000000000000000: begin sel_one_hot_n= 20'b00100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    25'b10011_?1000000000000000000: begin sel_one_hot_n= 20'b01000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    25'b10011_10000000000000000000: begin sel_one_hot_n= 20'b10000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    default: begin sel_one_hot_n= {20{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {20{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           5'b00000 : hold_on_sr = ( reqs_i == 20'b01000000000000000000 );
           5'b00001 : hold_on_sr = ( reqs_i == 20'b00100000000000000000 );
           5'b00010 : hold_on_sr = ( reqs_i == 20'b00010000000000000000 );
           5'b00011 : hold_on_sr = ( reqs_i == 20'b00001000000000000000 );
           5'b00100 : hold_on_sr = ( reqs_i == 20'b00000100000000000000 );
           5'b00101 : hold_on_sr = ( reqs_i == 20'b00000010000000000000 );
           5'b00110 : hold_on_sr = ( reqs_i == 20'b00000001000000000000 );
           5'b00111 : hold_on_sr = ( reqs_i == 20'b00000000100000000000 );
           5'b01000 : hold_on_sr = ( reqs_i == 20'b00000000010000000000 );
           5'b01001 : hold_on_sr = ( reqs_i == 20'b00000000001000000000 );
           5'b01010 : hold_on_sr = ( reqs_i == 20'b00000000000100000000 );
           5'b01011 : hold_on_sr = ( reqs_i == 20'b00000000000010000000 );
           5'b01100 : hold_on_sr = ( reqs_i == 20'b00000000000001000000 );
           5'b01101 : hold_on_sr = ( reqs_i == 20'b00000000000000100000 );
           5'b01110 : hold_on_sr = ( reqs_i == 20'b00000000000000010000 );
           5'b01111 : hold_on_sr = ( reqs_i == 20'b00000000000000001000 );
           5'b10000 : hold_on_sr = ( reqs_i == 20'b00000000000000000100 );
           5'b10001 : hold_on_sr = ( reqs_i == 20'b00000000000000000010 );
           5'b10010 : hold_on_sr = ( reqs_i == 20'b00000000000000000001 );
           5'b10011 : hold_on_sr = ( reqs_i == 20'b10000000000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_20 
    assign reset_on_sr = ( reqs_i == 20'b01000000000000000000 ) 
                       | ( reqs_i == 20'b00100000000000000000 ) 
                       | ( reqs_i == 20'b00010000000000000000 ) 
                       | ( reqs_i == 20'b00001000000000000000 ) 
                       | ( reqs_i == 20'b00000100000000000000 ) 
                       | ( reqs_i == 20'b00000010000000000000 ) 
                       | ( reqs_i == 20'b00000001000000000000 ) 
                       | ( reqs_i == 20'b00000000100000000000 ) 
                       | ( reqs_i == 20'b00000000010000000000 ) 
                       | ( reqs_i == 20'b00000000001000000000 ) 
                       | ( reqs_i == 20'b00000000000100000000 ) 
                       | ( reqs_i == 20'b00000000000010000000 ) 
                       | ( reqs_i == 20'b00000000000001000000 ) 
                       | ( reqs_i == 20'b00000000000000100000 ) 
                       | ( reqs_i == 20'b00000000000000010000 ) 
                       | ( reqs_i == 20'b00000000000000001000 ) 
                       | ( reqs_i == 20'b00000000000000000100 ) 
                       | ( reqs_i == 20'b00000000000000000010 ) 
                       | ( reqs_i == 20'b00000000000000000001 ) 
                       | ( reqs_i == 20'b10000000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_20

if(inputs_p == 21)
begin: inputs_21

logic [21-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    26'b?????_000000000000000000000: begin sel_one_hot_n = 21'b000000000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    26'b00000_???????????????????1?: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b00000_??????????????????10?: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b00000_?????????????????100?: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b00000_????????????????1000?: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b00000_???????????????10000?: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b00000_??????????????100000?: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b00000_?????????????1000000?: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b00000_????????????10000000?: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b00000_???????????100000000?: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b00000_??????????1000000000?: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b00000_?????????10000000000?: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b00000_????????100000000000?: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b00000_???????1000000000000?: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b00000_??????10000000000000?: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b00000_?????100000000000000?: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b00000_????1000000000000000?: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b00000_???10000000000000000?: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b00000_??100000000000000000?: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b00000_?1000000000000000000?: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b00000_10000000000000000000?: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b00000_000000000000000000001: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b00001_??????????????????1??: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b00001_?????????????????10??: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b00001_????????????????100??: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b00001_???????????????1000??: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b00001_??????????????10000??: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b00001_?????????????100000??: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b00001_????????????1000000??: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b00001_???????????10000000??: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b00001_??????????100000000??: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b00001_?????????1000000000??: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b00001_????????10000000000??: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b00001_???????100000000000??: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b00001_??????1000000000000??: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b00001_?????10000000000000??: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b00001_????100000000000000??: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b00001_???1000000000000000??: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b00001_??10000000000000000??: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b00001_?100000000000000000??: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b00001_1000000000000000000??: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b00001_0000000000000000000?1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b00001_000000000000000000010: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b00010_?????????????????1???: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b00010_????????????????10???: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b00010_???????????????100???: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b00010_??????????????1000???: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b00010_?????????????10000???: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b00010_????????????100000???: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b00010_???????????1000000???: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b00010_??????????10000000???: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b00010_?????????100000000???: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b00010_????????1000000000???: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b00010_???????10000000000???: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b00010_??????100000000000???: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b00010_?????1000000000000???: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b00010_????10000000000000???: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b00010_???100000000000000???: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b00010_??1000000000000000???: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b00010_?10000000000000000???: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b00010_100000000000000000???: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b00010_000000000000000000??1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b00010_000000000000000000?10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b00010_000000000000000000100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b00011_????????????????1????: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b00011_???????????????10????: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b00011_??????????????100????: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b00011_?????????????1000????: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b00011_????????????10000????: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b00011_???????????100000????: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b00011_??????????1000000????: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b00011_?????????10000000????: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b00011_????????100000000????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b00011_???????1000000000????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b00011_??????10000000000????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b00011_?????100000000000????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b00011_????1000000000000????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b00011_???10000000000000????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b00011_??100000000000000????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b00011_?1000000000000000????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b00011_10000000000000000????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b00011_00000000000000000???1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b00011_00000000000000000??10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b00011_00000000000000000?100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b00011_000000000000000001000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b00100_???????????????1?????: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b00100_??????????????10?????: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b00100_?????????????100?????: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b00100_????????????1000?????: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b00100_???????????10000?????: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b00100_??????????100000?????: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b00100_?????????1000000?????: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b00100_????????10000000?????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b00100_???????100000000?????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b00100_??????1000000000?????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b00100_?????10000000000?????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b00100_????100000000000?????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b00100_???1000000000000?????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b00100_??10000000000000?????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b00100_?100000000000000?????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b00100_1000000000000000?????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b00100_0000000000000000????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b00100_0000000000000000???10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b00100_0000000000000000??100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b00100_0000000000000000?1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b00100_000000000000000010000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b00101_??????????????1??????: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b00101_?????????????10??????: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b00101_????????????100??????: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b00101_???????????1000??????: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b00101_??????????10000??????: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b00101_?????????100000??????: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b00101_????????1000000??????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b00101_???????10000000??????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b00101_??????100000000??????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b00101_?????1000000000??????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b00101_????10000000000??????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b00101_???100000000000??????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b00101_??1000000000000??????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b00101_?10000000000000??????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b00101_100000000000000??????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b00101_000000000000000?????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b00101_000000000000000????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b00101_000000000000000???100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b00101_000000000000000??1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b00101_000000000000000?10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b00101_000000000000000100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b00110_?????????????1???????: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b00110_????????????10???????: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b00110_???????????100???????: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b00110_??????????1000???????: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b00110_?????????10000???????: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b00110_????????100000???????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b00110_???????1000000???????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b00110_??????10000000???????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b00110_?????100000000???????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b00110_????1000000000???????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b00110_???10000000000???????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b00110_??100000000000???????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b00110_?1000000000000???????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b00110_10000000000000???????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b00110_00000000000000??????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b00110_00000000000000?????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b00110_00000000000000????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b00110_00000000000000???1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b00110_00000000000000??10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b00110_00000000000000?100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b00110_000000000000001000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b00111_????????????1????????: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b00111_???????????10????????: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b00111_??????????100????????: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b00111_?????????1000????????: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b00111_????????10000????????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b00111_???????100000????????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b00111_??????1000000????????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b00111_?????10000000????????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b00111_????100000000????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b00111_???1000000000????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b00111_??10000000000????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b00111_?100000000000????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b00111_1000000000000????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b00111_0000000000000???????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b00111_0000000000000??????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b00111_0000000000000?????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b00111_0000000000000????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b00111_0000000000000???10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b00111_0000000000000??100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b00111_0000000000000?1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b00111_000000000000010000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01000_???????????1?????????: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b01000_??????????10?????????: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b01000_?????????100?????????: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b01000_????????1000?????????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b01000_???????10000?????????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b01000_??????100000?????????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b01000_?????1000000?????????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b01000_????10000000?????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b01000_???100000000?????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b01000_??1000000000?????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b01000_?10000000000?????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b01000_100000000000?????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b01000_000000000000????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b01000_000000000000???????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b01000_000000000000??????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b01000_000000000000?????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b01000_000000000000????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b01000_000000000000???100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b01000_000000000000??1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b01000_000000000000?10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01000_000000000000100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b01001_??????????1??????????: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b01001_?????????10??????????: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b01001_????????100??????????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b01001_???????1000??????????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b01001_??????10000??????????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b01001_?????100000??????????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b01001_????1000000??????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b01001_???10000000??????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b01001_??100000000??????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b01001_?1000000000??????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b01001_10000000000??????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b01001_00000000000?????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b01001_00000000000????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b01001_00000000000???????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b01001_00000000000??????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b01001_00000000000?????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b01001_00000000000????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b01001_00000000000???1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b01001_00000000000??10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01001_00000000000?100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b01001_000000000001000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b01010_?????????1???????????: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b01010_????????10???????????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b01010_???????100???????????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b01010_??????1000???????????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b01010_?????10000???????????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b01010_????100000???????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b01010_???1000000???????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b01010_??10000000???????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b01010_?100000000???????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b01010_1000000000???????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b01010_0000000000??????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b01010_0000000000?????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b01010_0000000000????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b01010_0000000000???????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b01010_0000000000??????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b01010_0000000000?????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b01010_0000000000????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b01010_0000000000???10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01010_0000000000??100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b01010_0000000000?1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b01010_000000000010000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b01011_????????1????????????: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b01011_???????10????????????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b01011_??????100????????????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b01011_?????1000????????????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b01011_????10000????????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b01011_???100000????????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b01011_??1000000????????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b01011_?10000000????????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b01011_100000000????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b01011_000000000???????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b01011_000000000??????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b01011_000000000?????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b01011_000000000????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b01011_000000000???????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b01011_000000000??????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b01011_000000000?????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b01011_000000000????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01011_000000000???100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b01011_000000000??1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b01011_000000000?10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b01011_000000000100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b01100_???????1?????????????: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b01100_??????10?????????????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b01100_?????100?????????????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b01100_????1000?????????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b01100_???10000?????????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b01100_??100000?????????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b01100_?1000000?????????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b01100_10000000?????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b01100_00000000????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b01100_00000000???????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b01100_00000000??????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b01100_00000000?????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b01100_00000000????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b01100_00000000???????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b01100_00000000??????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b01100_00000000?????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01100_00000000????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b01100_00000000???1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b01100_00000000??10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b01100_00000000?100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b01100_000000001000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b01101_??????1??????????????: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b01101_?????10??????????????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b01101_????100??????????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b01101_???1000??????????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b01101_??10000??????????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b01101_?100000??????????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b01101_1000000??????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b01101_0000000?????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b01101_0000000????????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b01101_0000000???????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b01101_0000000??????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b01101_0000000?????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b01101_0000000????????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b01101_0000000???????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b01101_0000000??????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01101_0000000?????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b01101_0000000????1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b01101_0000000???10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b01101_0000000??100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b01101_0000000?1000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b01101_000000010000000000000: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b01110_?????1???????????????: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b01110_????10???????????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b01110_???100???????????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b01110_??1000???????????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b01110_?10000???????????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b01110_100000???????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b01110_000000??????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b01110_000000?????????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b01110_000000????????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b01110_000000???????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b01110_000000??????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b01110_000000?????????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b01110_000000????????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b01110_000000???????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01110_000000??????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b01110_000000?????1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b01110_000000????10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b01110_000000???100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b01110_000000??1000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b01110_000000?10000000000000: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b01110_000000100000000000000: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b01111_????1????????????????: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b01111_???10????????????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b01111_??100????????????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b01111_?1000????????????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b01111_10000????????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b01111_00000???????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b01111_00000??????????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b01111_00000?????????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b01111_00000????????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b01111_00000???????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b01111_00000??????????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b01111_00000?????????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b01111_00000????????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b01111_00000???????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b01111_00000??????1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b01111_00000?????10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b01111_00000????100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b01111_00000???1000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b01111_00000??10000000000000: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b01111_00000?100000000000000: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b01111_000001000000000000000: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b10000_???1?????????????????: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b10000_??10?????????????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b10000_?100?????????????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b10000_1000?????????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b10000_0000????????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b10000_0000???????????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b10000_0000??????????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b10000_0000?????????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b10000_0000????????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b10000_0000???????????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b10000_0000??????????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b10000_0000?????????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b10000_0000????????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b10000_0000???????1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b10000_0000??????10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b10000_0000?????100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b10000_0000????1000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b10000_0000???10000000000000: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b10000_0000??100000000000000: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b10000_0000?1000000000000000: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b10000_000010000000000000000: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b10001_??1??????????????????: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b10001_?10??????????????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b10001_100??????????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b10001_000?????????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b10001_000????????????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b10001_000???????????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b10001_000??????????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b10001_000?????????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b10001_000????????????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b10001_000???????????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b10001_000??????????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b10001_000?????????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b10001_000????????1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b10001_000???????10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b10001_000??????100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b10001_000?????1000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b10001_000????10000000000000: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b10001_000???100000000000000: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b10001_000??1000000000000000: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b10001_000?10000000000000000: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b10001_000100000000000000000: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b10010_?1???????????????????: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b10010_10???????????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b10010_00??????????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b10010_00?????????????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b10010_00????????????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b10010_00???????????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b10010_00??????????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b10010_00?????????????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b10010_00????????????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b10010_00???????????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b10010_00??????????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b10010_00?????????1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b10010_00????????10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b10010_00???????100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b10010_00??????1000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b10010_00?????10000000000000: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b10010_00????100000000000000: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b10010_00???1000000000000000: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b10010_00??10000000000000000: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b10010_00?100000000000000000: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b10010_001000000000000000000: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b10011_1????????????????????: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    26'b10011_0???????????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b10011_0??????????????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b10011_0?????????????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b10011_0????????????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b10011_0???????????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b10011_0??????????????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b10011_0?????????????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b10011_0????????????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b10011_0???????????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b10011_0??????????1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b10011_0?????????10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b10011_0????????100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b10011_0???????1000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b10011_0??????10000000000000: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b10011_0?????100000000000000: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b10011_0????1000000000000000: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b10011_0???10000000000000000: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b10011_0??100000000000000000: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b10011_0?1000000000000000000: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b10011_010000000000000000000: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b10100_????????????????????1: begin sel_one_hot_n= 21'b000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    26'b10100_???????????????????10: begin sel_one_hot_n= 21'b000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    26'b10100_??????????????????100: begin sel_one_hot_n= 21'b000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    26'b10100_?????????????????1000: begin sel_one_hot_n= 21'b000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    26'b10100_????????????????10000: begin sel_one_hot_n= 21'b000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    26'b10100_???????????????100000: begin sel_one_hot_n= 21'b000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    26'b10100_??????????????1000000: begin sel_one_hot_n= 21'b000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    26'b10100_?????????????10000000: begin sel_one_hot_n= 21'b000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    26'b10100_????????????100000000: begin sel_one_hot_n= 21'b000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    26'b10100_???????????1000000000: begin sel_one_hot_n= 21'b000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    26'b10100_??????????10000000000: begin sel_one_hot_n= 21'b000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    26'b10100_?????????100000000000: begin sel_one_hot_n= 21'b000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    26'b10100_????????1000000000000: begin sel_one_hot_n= 21'b000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    26'b10100_???????10000000000000: begin sel_one_hot_n= 21'b000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    26'b10100_??????100000000000000: begin sel_one_hot_n= 21'b000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    26'b10100_?????1000000000000000: begin sel_one_hot_n= 21'b000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    26'b10100_????10000000000000000: begin sel_one_hot_n= 21'b000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    26'b10100_???100000000000000000: begin sel_one_hot_n= 21'b000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    26'b10100_??1000000000000000000: begin sel_one_hot_n= 21'b001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    26'b10100_?10000000000000000000: begin sel_one_hot_n= 21'b010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    26'b10100_100000000000000000000: begin sel_one_hot_n= 21'b100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    default: begin sel_one_hot_n= {21{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {21{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           5'b00000 : hold_on_sr = ( reqs_i == 21'b010000000000000000000 );
           5'b00001 : hold_on_sr = ( reqs_i == 21'b001000000000000000000 );
           5'b00010 : hold_on_sr = ( reqs_i == 21'b000100000000000000000 );
           5'b00011 : hold_on_sr = ( reqs_i == 21'b000010000000000000000 );
           5'b00100 : hold_on_sr = ( reqs_i == 21'b000001000000000000000 );
           5'b00101 : hold_on_sr = ( reqs_i == 21'b000000100000000000000 );
           5'b00110 : hold_on_sr = ( reqs_i == 21'b000000010000000000000 );
           5'b00111 : hold_on_sr = ( reqs_i == 21'b000000001000000000000 );
           5'b01000 : hold_on_sr = ( reqs_i == 21'b000000000100000000000 );
           5'b01001 : hold_on_sr = ( reqs_i == 21'b000000000010000000000 );
           5'b01010 : hold_on_sr = ( reqs_i == 21'b000000000001000000000 );
           5'b01011 : hold_on_sr = ( reqs_i == 21'b000000000000100000000 );
           5'b01100 : hold_on_sr = ( reqs_i == 21'b000000000000010000000 );
           5'b01101 : hold_on_sr = ( reqs_i == 21'b000000000000001000000 );
           5'b01110 : hold_on_sr = ( reqs_i == 21'b000000000000000100000 );
           5'b01111 : hold_on_sr = ( reqs_i == 21'b000000000000000010000 );
           5'b10000 : hold_on_sr = ( reqs_i == 21'b000000000000000001000 );
           5'b10001 : hold_on_sr = ( reqs_i == 21'b000000000000000000100 );
           5'b10010 : hold_on_sr = ( reqs_i == 21'b000000000000000000010 );
           5'b10011 : hold_on_sr = ( reqs_i == 21'b000000000000000000001 );
           5'b10100 : hold_on_sr = ( reqs_i == 21'b100000000000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_21 
    assign reset_on_sr = ( reqs_i == 21'b010000000000000000000 ) 
                       | ( reqs_i == 21'b001000000000000000000 ) 
                       | ( reqs_i == 21'b000100000000000000000 ) 
                       | ( reqs_i == 21'b000010000000000000000 ) 
                       | ( reqs_i == 21'b000001000000000000000 ) 
                       | ( reqs_i == 21'b000000100000000000000 ) 
                       | ( reqs_i == 21'b000000010000000000000 ) 
                       | ( reqs_i == 21'b000000001000000000000 ) 
                       | ( reqs_i == 21'b000000000100000000000 ) 
                       | ( reqs_i == 21'b000000000010000000000 ) 
                       | ( reqs_i == 21'b000000000001000000000 ) 
                       | ( reqs_i == 21'b000000000000100000000 ) 
                       | ( reqs_i == 21'b000000000000010000000 ) 
                       | ( reqs_i == 21'b000000000000001000000 ) 
                       | ( reqs_i == 21'b000000000000000100000 ) 
                       | ( reqs_i == 21'b000000000000000010000 ) 
                       | ( reqs_i == 21'b000000000000000001000 ) 
                       | ( reqs_i == 21'b000000000000000000100 ) 
                       | ( reqs_i == 21'b000000000000000000010 ) 
                       | ( reqs_i == 21'b000000000000000000001 ) 
                       | ( reqs_i == 21'b100000000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_21

if(inputs_p == 22)
begin: inputs_22

logic [22-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    27'b?????_0000000000000000000000: begin sel_one_hot_n = 22'b0000000000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    27'b00000_????????????????????1?: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b00000_???????????????????10?: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b00000_??????????????????100?: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b00000_?????????????????1000?: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b00000_????????????????10000?: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b00000_???????????????100000?: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b00000_??????????????1000000?: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b00000_?????????????10000000?: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b00000_????????????100000000?: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b00000_???????????1000000000?: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b00000_??????????10000000000?: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b00000_?????????100000000000?: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b00000_????????1000000000000?: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b00000_???????10000000000000?: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b00000_??????100000000000000?: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b00000_?????1000000000000000?: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b00000_????10000000000000000?: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b00000_???100000000000000000?: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b00000_??1000000000000000000?: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b00000_?10000000000000000000?: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b00000_100000000000000000000?: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b00000_0000000000000000000001: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b00001_???????????????????1??: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b00001_??????????????????10??: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b00001_?????????????????100??: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b00001_????????????????1000??: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b00001_???????????????10000??: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b00001_??????????????100000??: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b00001_?????????????1000000??: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b00001_????????????10000000??: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b00001_???????????100000000??: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b00001_??????????1000000000??: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b00001_?????????10000000000??: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b00001_????????100000000000??: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b00001_???????1000000000000??: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b00001_??????10000000000000??: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b00001_?????100000000000000??: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b00001_????1000000000000000??: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b00001_???10000000000000000??: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b00001_??100000000000000000??: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b00001_?1000000000000000000??: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b00001_10000000000000000000??: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b00001_00000000000000000000?1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b00001_0000000000000000000010: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b00010_??????????????????1???: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b00010_?????????????????10???: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b00010_????????????????100???: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b00010_???????????????1000???: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b00010_??????????????10000???: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b00010_?????????????100000???: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b00010_????????????1000000???: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b00010_???????????10000000???: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b00010_??????????100000000???: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b00010_?????????1000000000???: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b00010_????????10000000000???: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b00010_???????100000000000???: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b00010_??????1000000000000???: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b00010_?????10000000000000???: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b00010_????100000000000000???: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b00010_???1000000000000000???: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b00010_??10000000000000000???: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b00010_?100000000000000000???: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b00010_1000000000000000000???: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b00010_0000000000000000000??1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b00010_0000000000000000000?10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b00010_0000000000000000000100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b00011_?????????????????1????: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b00011_????????????????10????: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b00011_???????????????100????: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b00011_??????????????1000????: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b00011_?????????????10000????: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b00011_????????????100000????: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b00011_???????????1000000????: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b00011_??????????10000000????: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b00011_?????????100000000????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b00011_????????1000000000????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b00011_???????10000000000????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b00011_??????100000000000????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b00011_?????1000000000000????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b00011_????10000000000000????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b00011_???100000000000000????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b00011_??1000000000000000????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b00011_?10000000000000000????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b00011_100000000000000000????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b00011_000000000000000000???1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b00011_000000000000000000??10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b00011_000000000000000000?100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b00011_0000000000000000001000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b00100_????????????????1?????: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b00100_???????????????10?????: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b00100_??????????????100?????: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b00100_?????????????1000?????: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b00100_????????????10000?????: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b00100_???????????100000?????: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b00100_??????????1000000?????: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b00100_?????????10000000?????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b00100_????????100000000?????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b00100_???????1000000000?????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b00100_??????10000000000?????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b00100_?????100000000000?????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b00100_????1000000000000?????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b00100_???10000000000000?????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b00100_??100000000000000?????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b00100_?1000000000000000?????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b00100_10000000000000000?????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b00100_00000000000000000????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b00100_00000000000000000???10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b00100_00000000000000000??100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b00100_00000000000000000?1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b00100_0000000000000000010000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b00101_???????????????1??????: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b00101_??????????????10??????: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b00101_?????????????100??????: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b00101_????????????1000??????: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b00101_???????????10000??????: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b00101_??????????100000??????: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b00101_?????????1000000??????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b00101_????????10000000??????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b00101_???????100000000??????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b00101_??????1000000000??????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b00101_?????10000000000??????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b00101_????100000000000??????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b00101_???1000000000000??????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b00101_??10000000000000??????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b00101_?100000000000000??????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b00101_1000000000000000??????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b00101_0000000000000000?????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b00101_0000000000000000????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b00101_0000000000000000???100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b00101_0000000000000000??1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b00101_0000000000000000?10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b00101_0000000000000000100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b00110_??????????????1???????: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b00110_?????????????10???????: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b00110_????????????100???????: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b00110_???????????1000???????: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b00110_??????????10000???????: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b00110_?????????100000???????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b00110_????????1000000???????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b00110_???????10000000???????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b00110_??????100000000???????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b00110_?????1000000000???????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b00110_????10000000000???????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b00110_???100000000000???????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b00110_??1000000000000???????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b00110_?10000000000000???????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b00110_100000000000000???????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b00110_000000000000000??????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b00110_000000000000000?????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b00110_000000000000000????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b00110_000000000000000???1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b00110_000000000000000??10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b00110_000000000000000?100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b00110_0000000000000001000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b00111_?????????????1????????: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b00111_????????????10????????: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b00111_???????????100????????: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b00111_??????????1000????????: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b00111_?????????10000????????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b00111_????????100000????????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b00111_???????1000000????????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b00111_??????10000000????????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b00111_?????100000000????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b00111_????1000000000????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b00111_???10000000000????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b00111_??100000000000????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b00111_?1000000000000????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b00111_10000000000000????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b00111_00000000000000???????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b00111_00000000000000??????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b00111_00000000000000?????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b00111_00000000000000????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b00111_00000000000000???10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b00111_00000000000000??100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b00111_00000000000000?1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b00111_0000000000000010000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01000_????????????1?????????: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b01000_???????????10?????????: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b01000_??????????100?????????: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b01000_?????????1000?????????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b01000_????????10000?????????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b01000_???????100000?????????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b01000_??????1000000?????????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b01000_?????10000000?????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b01000_????100000000?????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b01000_???1000000000?????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b01000_??10000000000?????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b01000_?100000000000?????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b01000_1000000000000?????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b01000_0000000000000????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b01000_0000000000000???????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b01000_0000000000000??????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b01000_0000000000000?????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b01000_0000000000000????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b01000_0000000000000???100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b01000_0000000000000??1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b01000_0000000000000?10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01000_0000000000000100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b01001_???????????1??????????: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b01001_??????????10??????????: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b01001_?????????100??????????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b01001_????????1000??????????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b01001_???????10000??????????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b01001_??????100000??????????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b01001_?????1000000??????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b01001_????10000000??????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b01001_???100000000??????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b01001_??1000000000??????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b01001_?10000000000??????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b01001_100000000000??????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b01001_000000000000?????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b01001_000000000000????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b01001_000000000000???????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b01001_000000000000??????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b01001_000000000000?????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b01001_000000000000????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b01001_000000000000???1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b01001_000000000000??10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01001_000000000000?100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b01001_0000000000001000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b01010_??????????1???????????: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b01010_?????????10???????????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b01010_????????100???????????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b01010_???????1000???????????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b01010_??????10000???????????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b01010_?????100000???????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b01010_????1000000???????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b01010_???10000000???????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b01010_??100000000???????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b01010_?1000000000???????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b01010_10000000000???????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b01010_00000000000??????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b01010_00000000000?????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b01010_00000000000????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b01010_00000000000???????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b01010_00000000000??????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b01010_00000000000?????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b01010_00000000000????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b01010_00000000000???10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01010_00000000000??100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b01010_00000000000?1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b01010_0000000000010000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b01011_?????????1????????????: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b01011_????????10????????????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b01011_???????100????????????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b01011_??????1000????????????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b01011_?????10000????????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b01011_????100000????????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b01011_???1000000????????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b01011_??10000000????????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b01011_?100000000????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b01011_1000000000????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b01011_0000000000???????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b01011_0000000000??????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b01011_0000000000?????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b01011_0000000000????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b01011_0000000000???????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b01011_0000000000??????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b01011_0000000000?????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b01011_0000000000????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01011_0000000000???100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b01011_0000000000??1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b01011_0000000000?10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b01011_0000000000100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b01100_????????1?????????????: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b01100_???????10?????????????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b01100_??????100?????????????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b01100_?????1000?????????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b01100_????10000?????????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b01100_???100000?????????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b01100_??1000000?????????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b01100_?10000000?????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b01100_100000000?????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b01100_000000000????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b01100_000000000???????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b01100_000000000??????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b01100_000000000?????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b01100_000000000????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b01100_000000000???????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b01100_000000000??????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b01100_000000000?????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01100_000000000????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b01100_000000000???1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b01100_000000000??10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b01100_000000000?100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b01100_0000000001000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b01101_???????1??????????????: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b01101_??????10??????????????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b01101_?????100??????????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b01101_????1000??????????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b01101_???10000??????????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b01101_??100000??????????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b01101_?1000000??????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b01101_10000000??????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b01101_00000000?????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b01101_00000000????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b01101_00000000???????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b01101_00000000??????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b01101_00000000?????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b01101_00000000????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b01101_00000000???????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b01101_00000000??????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01101_00000000?????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b01101_00000000????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b01101_00000000???10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b01101_00000000??100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b01101_00000000?1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b01101_0000000010000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b01110_??????1???????????????: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b01110_?????10???????????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b01110_????100???????????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b01110_???1000???????????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b01110_??10000???????????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b01110_?100000???????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b01110_1000000???????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b01110_0000000??????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b01110_0000000?????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b01110_0000000????????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b01110_0000000???????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b01110_0000000??????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b01110_0000000?????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b01110_0000000????????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b01110_0000000???????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01110_0000000??????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b01110_0000000?????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b01110_0000000????10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b01110_0000000???100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b01110_0000000??1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b01110_0000000?10000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b01110_0000000100000000000000: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b01111_?????1????????????????: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b01111_????10????????????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b01111_???100????????????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b01111_??1000????????????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b01111_?10000????????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b01111_100000????????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b01111_000000???????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b01111_000000??????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b01111_000000?????????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b01111_000000????????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b01111_000000???????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b01111_000000??????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b01111_000000?????????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b01111_000000????????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b01111_000000???????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b01111_000000??????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b01111_000000?????10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b01111_000000????100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b01111_000000???1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b01111_000000??10000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b01111_000000?100000000000000: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b01111_0000001000000000000000: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b10000_????1?????????????????: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b10000_???10?????????????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b10000_??100?????????????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b10000_?1000?????????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b10000_10000?????????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b10000_00000????????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b10000_00000???????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b10000_00000??????????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b10000_00000?????????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b10000_00000????????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b10000_00000???????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b10000_00000??????????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b10000_00000?????????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b10000_00000????????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b10000_00000???????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b10000_00000??????10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b10000_00000?????100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b10000_00000????1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b10000_00000???10000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b10000_00000??100000000000000: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b10000_00000?1000000000000000: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b10000_0000010000000000000000: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b10001_???1??????????????????: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b10001_??10??????????????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b10001_?100??????????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b10001_1000??????????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b10001_0000?????????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b10001_0000????????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b10001_0000???????????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b10001_0000??????????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b10001_0000?????????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b10001_0000????????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b10001_0000???????????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b10001_0000??????????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b10001_0000?????????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b10001_0000????????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b10001_0000???????10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b10001_0000??????100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b10001_0000?????1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b10001_0000????10000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b10001_0000???100000000000000: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b10001_0000??1000000000000000: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b10001_0000?10000000000000000: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b10001_0000100000000000000000: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b10010_??1???????????????????: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b10010_?10???????????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b10010_100???????????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b10010_000??????????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b10010_000?????????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b10010_000????????????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b10010_000???????????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b10010_000??????????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b10010_000?????????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b10010_000????????????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b10010_000???????????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b10010_000??????????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b10010_000?????????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b10010_000????????10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b10010_000???????100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b10010_000??????1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b10010_000?????10000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b10010_000????100000000000000: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b10010_000???1000000000000000: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b10010_000??10000000000000000: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b10010_000?100000000000000000: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b10010_0001000000000000000000: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b10011_?1????????????????????: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b10011_10????????????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b10011_00???????????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b10011_00??????????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b10011_00?????????????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b10011_00????????????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b10011_00???????????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b10011_00??????????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b10011_00?????????????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b10011_00????????????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b10011_00???????????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b10011_00??????????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b10011_00?????????10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b10011_00????????100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b10011_00???????1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b10011_00??????10000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b10011_00?????100000000000000: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b10011_00????1000000000000000: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b10011_00???10000000000000000: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b10011_00??100000000000000000: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b10011_00?1000000000000000000: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b10011_0010000000000000000000: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b10100_1?????????????????????: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    27'b10100_0????????????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b10100_0???????????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b10100_0??????????????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b10100_0?????????????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b10100_0????????????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b10100_0???????????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b10100_0??????????????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b10100_0?????????????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b10100_0????????????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b10100_0???????????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b10100_0??????????10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b10100_0?????????100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b10100_0????????1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b10100_0???????10000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b10100_0??????100000000000000: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b10100_0?????1000000000000000: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b10100_0????10000000000000000: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b10100_0???100000000000000000: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b10100_0??1000000000000000000: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b10100_0?10000000000000000000: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b10100_0100000000000000000000: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b10101_?????????????????????1: begin sel_one_hot_n= 22'b0000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    27'b10101_????????????????????10: begin sel_one_hot_n= 22'b0000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    27'b10101_???????????????????100: begin sel_one_hot_n= 22'b0000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    27'b10101_??????????????????1000: begin sel_one_hot_n= 22'b0000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    27'b10101_?????????????????10000: begin sel_one_hot_n= 22'b0000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    27'b10101_????????????????100000: begin sel_one_hot_n= 22'b0000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    27'b10101_???????????????1000000: begin sel_one_hot_n= 22'b0000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    27'b10101_??????????????10000000: begin sel_one_hot_n= 22'b0000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    27'b10101_?????????????100000000: begin sel_one_hot_n= 22'b0000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    27'b10101_????????????1000000000: begin sel_one_hot_n= 22'b0000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    27'b10101_???????????10000000000: begin sel_one_hot_n= 22'b0000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    27'b10101_??????????100000000000: begin sel_one_hot_n= 22'b0000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    27'b10101_?????????1000000000000: begin sel_one_hot_n= 22'b0000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    27'b10101_????????10000000000000: begin sel_one_hot_n= 22'b0000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    27'b10101_???????100000000000000: begin sel_one_hot_n= 22'b0000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    27'b10101_??????1000000000000000: begin sel_one_hot_n= 22'b0000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    27'b10101_?????10000000000000000: begin sel_one_hot_n= 22'b0000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    27'b10101_????100000000000000000: begin sel_one_hot_n= 22'b0000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    27'b10101_???1000000000000000000: begin sel_one_hot_n= 22'b0001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    27'b10101_??10000000000000000000: begin sel_one_hot_n= 22'b0010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    27'b10101_?100000000000000000000: begin sel_one_hot_n= 22'b0100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    27'b10101_1000000000000000000000: begin sel_one_hot_n= 22'b1000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    default: begin sel_one_hot_n= {22{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {22{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           5'b00000 : hold_on_sr = ( reqs_i == 22'b0100000000000000000000 );
           5'b00001 : hold_on_sr = ( reqs_i == 22'b0010000000000000000000 );
           5'b00010 : hold_on_sr = ( reqs_i == 22'b0001000000000000000000 );
           5'b00011 : hold_on_sr = ( reqs_i == 22'b0000100000000000000000 );
           5'b00100 : hold_on_sr = ( reqs_i == 22'b0000010000000000000000 );
           5'b00101 : hold_on_sr = ( reqs_i == 22'b0000001000000000000000 );
           5'b00110 : hold_on_sr = ( reqs_i == 22'b0000000100000000000000 );
           5'b00111 : hold_on_sr = ( reqs_i == 22'b0000000010000000000000 );
           5'b01000 : hold_on_sr = ( reqs_i == 22'b0000000001000000000000 );
           5'b01001 : hold_on_sr = ( reqs_i == 22'b0000000000100000000000 );
           5'b01010 : hold_on_sr = ( reqs_i == 22'b0000000000010000000000 );
           5'b01011 : hold_on_sr = ( reqs_i == 22'b0000000000001000000000 );
           5'b01100 : hold_on_sr = ( reqs_i == 22'b0000000000000100000000 );
           5'b01101 : hold_on_sr = ( reqs_i == 22'b0000000000000010000000 );
           5'b01110 : hold_on_sr = ( reqs_i == 22'b0000000000000001000000 );
           5'b01111 : hold_on_sr = ( reqs_i == 22'b0000000000000000100000 );
           5'b10000 : hold_on_sr = ( reqs_i == 22'b0000000000000000010000 );
           5'b10001 : hold_on_sr = ( reqs_i == 22'b0000000000000000001000 );
           5'b10010 : hold_on_sr = ( reqs_i == 22'b0000000000000000000100 );
           5'b10011 : hold_on_sr = ( reqs_i == 22'b0000000000000000000010 );
           5'b10100 : hold_on_sr = ( reqs_i == 22'b0000000000000000000001 );
           5'b10101 : hold_on_sr = ( reqs_i == 22'b1000000000000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_22 
    assign reset_on_sr = ( reqs_i == 22'b0100000000000000000000 ) 
                       | ( reqs_i == 22'b0010000000000000000000 ) 
                       | ( reqs_i == 22'b0001000000000000000000 ) 
                       | ( reqs_i == 22'b0000100000000000000000 ) 
                       | ( reqs_i == 22'b0000010000000000000000 ) 
                       | ( reqs_i == 22'b0000001000000000000000 ) 
                       | ( reqs_i == 22'b0000000100000000000000 ) 
                       | ( reqs_i == 22'b0000000010000000000000 ) 
                       | ( reqs_i == 22'b0000000001000000000000 ) 
                       | ( reqs_i == 22'b0000000000100000000000 ) 
                       | ( reqs_i == 22'b0000000000010000000000 ) 
                       | ( reqs_i == 22'b0000000000001000000000 ) 
                       | ( reqs_i == 22'b0000000000000100000000 ) 
                       | ( reqs_i == 22'b0000000000000010000000 ) 
                       | ( reqs_i == 22'b0000000000000001000000 ) 
                       | ( reqs_i == 22'b0000000000000000100000 ) 
                       | ( reqs_i == 22'b0000000000000000010000 ) 
                       | ( reqs_i == 22'b0000000000000000001000 ) 
                       | ( reqs_i == 22'b0000000000000000000100 ) 
                       | ( reqs_i == 22'b0000000000000000000010 ) 
                       | ( reqs_i == 22'b0000000000000000000001 ) 
                       | ( reqs_i == 22'b1000000000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_22

if(inputs_p == 23)
begin: inputs_23

logic [23-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    28'b?????_00000000000000000000000: begin sel_one_hot_n = 23'b00000000000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    28'b00000_?????????????????????1?: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b00000_????????????????????10?: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b00000_???????????????????100?: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b00000_??????????????????1000?: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b00000_?????????????????10000?: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b00000_????????????????100000?: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b00000_???????????????1000000?: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b00000_??????????????10000000?: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b00000_?????????????100000000?: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b00000_????????????1000000000?: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b00000_???????????10000000000?: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b00000_??????????100000000000?: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b00000_?????????1000000000000?: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b00000_????????10000000000000?: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b00000_???????100000000000000?: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b00000_??????1000000000000000?: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b00000_?????10000000000000000?: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b00000_????100000000000000000?: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b00000_???1000000000000000000?: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b00000_??10000000000000000000?: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b00000_?100000000000000000000?: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b00000_1000000000000000000000?: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b00000_00000000000000000000001: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b00001_????????????????????1??: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b00001_???????????????????10??: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b00001_??????????????????100??: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b00001_?????????????????1000??: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b00001_????????????????10000??: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b00001_???????????????100000??: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b00001_??????????????1000000??: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b00001_?????????????10000000??: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b00001_????????????100000000??: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b00001_???????????1000000000??: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b00001_??????????10000000000??: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b00001_?????????100000000000??: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b00001_????????1000000000000??: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b00001_???????10000000000000??: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b00001_??????100000000000000??: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b00001_?????1000000000000000??: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b00001_????10000000000000000??: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b00001_???100000000000000000??: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b00001_??1000000000000000000??: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b00001_?10000000000000000000??: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b00001_100000000000000000000??: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b00001_000000000000000000000?1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b00001_00000000000000000000010: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b00010_???????????????????1???: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b00010_??????????????????10???: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b00010_?????????????????100???: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b00010_????????????????1000???: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b00010_???????????????10000???: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b00010_??????????????100000???: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b00010_?????????????1000000???: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b00010_????????????10000000???: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b00010_???????????100000000???: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b00010_??????????1000000000???: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b00010_?????????10000000000???: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b00010_????????100000000000???: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b00010_???????1000000000000???: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b00010_??????10000000000000???: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b00010_?????100000000000000???: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b00010_????1000000000000000???: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b00010_???10000000000000000???: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b00010_??100000000000000000???: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b00010_?1000000000000000000???: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b00010_10000000000000000000???: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b00010_00000000000000000000??1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b00010_00000000000000000000?10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b00010_00000000000000000000100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b00011_??????????????????1????: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b00011_?????????????????10????: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b00011_????????????????100????: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b00011_???????????????1000????: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b00011_??????????????10000????: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b00011_?????????????100000????: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b00011_????????????1000000????: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b00011_???????????10000000????: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b00011_??????????100000000????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b00011_?????????1000000000????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b00011_????????10000000000????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b00011_???????100000000000????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b00011_??????1000000000000????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b00011_?????10000000000000????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b00011_????100000000000000????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b00011_???1000000000000000????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b00011_??10000000000000000????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b00011_?100000000000000000????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b00011_1000000000000000000????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b00011_0000000000000000000???1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b00011_0000000000000000000??10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b00011_0000000000000000000?100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b00011_00000000000000000001000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b00100_?????????????????1?????: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b00100_????????????????10?????: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b00100_???????????????100?????: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b00100_??????????????1000?????: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b00100_?????????????10000?????: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b00100_????????????100000?????: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b00100_???????????1000000?????: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b00100_??????????10000000?????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b00100_?????????100000000?????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b00100_????????1000000000?????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b00100_???????10000000000?????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b00100_??????100000000000?????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b00100_?????1000000000000?????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b00100_????10000000000000?????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b00100_???100000000000000?????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b00100_??1000000000000000?????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b00100_?10000000000000000?????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b00100_100000000000000000?????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b00100_000000000000000000????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b00100_000000000000000000???10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b00100_000000000000000000??100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b00100_000000000000000000?1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b00100_00000000000000000010000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b00101_????????????????1??????: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b00101_???????????????10??????: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b00101_??????????????100??????: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b00101_?????????????1000??????: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b00101_????????????10000??????: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b00101_???????????100000??????: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b00101_??????????1000000??????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b00101_?????????10000000??????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b00101_????????100000000??????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b00101_???????1000000000??????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b00101_??????10000000000??????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b00101_?????100000000000??????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b00101_????1000000000000??????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b00101_???10000000000000??????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b00101_??100000000000000??????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b00101_?1000000000000000??????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b00101_10000000000000000??????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b00101_00000000000000000?????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b00101_00000000000000000????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b00101_00000000000000000???100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b00101_00000000000000000??1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b00101_00000000000000000?10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b00101_00000000000000000100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b00110_???????????????1???????: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b00110_??????????????10???????: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b00110_?????????????100???????: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b00110_????????????1000???????: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b00110_???????????10000???????: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b00110_??????????100000???????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b00110_?????????1000000???????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b00110_????????10000000???????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b00110_???????100000000???????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b00110_??????1000000000???????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b00110_?????10000000000???????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b00110_????100000000000???????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b00110_???1000000000000???????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b00110_??10000000000000???????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b00110_?100000000000000???????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b00110_1000000000000000???????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b00110_0000000000000000??????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b00110_0000000000000000?????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b00110_0000000000000000????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b00110_0000000000000000???1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b00110_0000000000000000??10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b00110_0000000000000000?100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b00110_00000000000000001000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b00111_??????????????1????????: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b00111_?????????????10????????: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b00111_????????????100????????: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b00111_???????????1000????????: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b00111_??????????10000????????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b00111_?????????100000????????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b00111_????????1000000????????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b00111_???????10000000????????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b00111_??????100000000????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b00111_?????1000000000????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b00111_????10000000000????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b00111_???100000000000????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b00111_??1000000000000????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b00111_?10000000000000????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b00111_100000000000000????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b00111_000000000000000???????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b00111_000000000000000??????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b00111_000000000000000?????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b00111_000000000000000????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b00111_000000000000000???10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b00111_000000000000000??100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b00111_000000000000000?1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b00111_00000000000000010000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01000_?????????????1?????????: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b01000_????????????10?????????: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b01000_???????????100?????????: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b01000_??????????1000?????????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b01000_?????????10000?????????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b01000_????????100000?????????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b01000_???????1000000?????????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b01000_??????10000000?????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b01000_?????100000000?????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b01000_????1000000000?????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b01000_???10000000000?????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b01000_??100000000000?????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b01000_?1000000000000?????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b01000_10000000000000?????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b01000_00000000000000????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b01000_00000000000000???????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b01000_00000000000000??????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b01000_00000000000000?????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b01000_00000000000000????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b01000_00000000000000???100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b01000_00000000000000??1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b01000_00000000000000?10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01000_00000000000000100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b01001_????????????1??????????: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b01001_???????????10??????????: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b01001_??????????100??????????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b01001_?????????1000??????????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b01001_????????10000??????????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b01001_???????100000??????????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b01001_??????1000000??????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b01001_?????10000000??????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b01001_????100000000??????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b01001_???1000000000??????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b01001_??10000000000??????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b01001_?100000000000??????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b01001_1000000000000??????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b01001_0000000000000?????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b01001_0000000000000????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b01001_0000000000000???????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b01001_0000000000000??????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b01001_0000000000000?????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b01001_0000000000000????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b01001_0000000000000???1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b01001_0000000000000??10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01001_0000000000000?100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b01001_00000000000001000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b01010_???????????1???????????: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b01010_??????????10???????????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b01010_?????????100???????????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b01010_????????1000???????????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b01010_???????10000???????????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b01010_??????100000???????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b01010_?????1000000???????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b01010_????10000000???????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b01010_???100000000???????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b01010_??1000000000???????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b01010_?10000000000???????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b01010_100000000000???????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b01010_000000000000??????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b01010_000000000000?????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b01010_000000000000????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b01010_000000000000???????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b01010_000000000000??????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b01010_000000000000?????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b01010_000000000000????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b01010_000000000000???10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01010_000000000000??100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b01010_000000000000?1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b01010_00000000000010000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b01011_??????????1????????????: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b01011_?????????10????????????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b01011_????????100????????????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b01011_???????1000????????????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b01011_??????10000????????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b01011_?????100000????????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b01011_????1000000????????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b01011_???10000000????????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b01011_??100000000????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b01011_?1000000000????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b01011_10000000000????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b01011_00000000000???????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b01011_00000000000??????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b01011_00000000000?????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b01011_00000000000????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b01011_00000000000???????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b01011_00000000000??????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b01011_00000000000?????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b01011_00000000000????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01011_00000000000???100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b01011_00000000000??1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b01011_00000000000?10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b01011_00000000000100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b01100_?????????1?????????????: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b01100_????????10?????????????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b01100_???????100?????????????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b01100_??????1000?????????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b01100_?????10000?????????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b01100_????100000?????????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b01100_???1000000?????????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b01100_??10000000?????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b01100_?100000000?????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b01100_1000000000?????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b01100_0000000000????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b01100_0000000000???????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b01100_0000000000??????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b01100_0000000000?????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b01100_0000000000????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b01100_0000000000???????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b01100_0000000000??????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b01100_0000000000?????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01100_0000000000????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b01100_0000000000???1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b01100_0000000000??10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b01100_0000000000?100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b01100_00000000001000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b01101_????????1??????????????: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b01101_???????10??????????????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b01101_??????100??????????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b01101_?????1000??????????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b01101_????10000??????????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b01101_???100000??????????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b01101_??1000000??????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b01101_?10000000??????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b01101_100000000??????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b01101_000000000?????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b01101_000000000????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b01101_000000000???????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b01101_000000000??????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b01101_000000000?????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b01101_000000000????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b01101_000000000???????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b01101_000000000??????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01101_000000000?????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b01101_000000000????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b01101_000000000???10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b01101_000000000??100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b01101_000000000?1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b01101_00000000010000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b01110_???????1???????????????: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b01110_??????10???????????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b01110_?????100???????????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b01110_????1000???????????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b01110_???10000???????????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b01110_??100000???????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b01110_?1000000???????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b01110_10000000???????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b01110_00000000??????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b01110_00000000?????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b01110_00000000????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b01110_00000000???????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b01110_00000000??????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b01110_00000000?????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b01110_00000000????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b01110_00000000???????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01110_00000000??????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b01110_00000000?????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b01110_00000000????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b01110_00000000???100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b01110_00000000??1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b01110_00000000?10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b01110_00000000100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b01111_??????1????????????????: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b01111_?????10????????????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b01111_????100????????????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b01111_???1000????????????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b01111_??10000????????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b01111_?100000????????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b01111_1000000????????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b01111_0000000???????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b01111_0000000??????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b01111_0000000?????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b01111_0000000????????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b01111_0000000???????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b01111_0000000??????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b01111_0000000?????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b01111_0000000????????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b01111_0000000???????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b01111_0000000??????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b01111_0000000?????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b01111_0000000????100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b01111_0000000???1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b01111_0000000??10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b01111_0000000?100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b01111_00000001000000000000000: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b10000_?????1?????????????????: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b10000_????10?????????????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b10000_???100?????????????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b10000_??1000?????????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b10000_?10000?????????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b10000_100000?????????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b10000_000000????????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b10000_000000???????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b10000_000000??????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b10000_000000?????????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b10000_000000????????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b10000_000000???????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b10000_000000??????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b10000_000000?????????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b10000_000000????????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b10000_000000???????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b10000_000000??????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b10000_000000?????100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b10000_000000????1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b10000_000000???10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b10000_000000??100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b10000_000000?1000000000000000: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b10000_00000010000000000000000: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b10001_????1??????????????????: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b10001_???10??????????????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b10001_??100??????????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b10001_?1000??????????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b10001_10000??????????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b10001_00000?????????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b10001_00000????????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b10001_00000???????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b10001_00000??????????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b10001_00000?????????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b10001_00000????????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b10001_00000???????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b10001_00000??????????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b10001_00000?????????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b10001_00000????????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b10001_00000???????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b10001_00000??????100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b10001_00000?????1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b10001_00000????10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b10001_00000???100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b10001_00000??1000000000000000: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b10001_00000?10000000000000000: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b10001_00000100000000000000000: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b10010_???1???????????????????: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b10010_??10???????????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b10010_?100???????????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b10010_1000???????????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b10010_0000??????????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b10010_0000?????????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b10010_0000????????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b10010_0000???????????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b10010_0000??????????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b10010_0000?????????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b10010_0000????????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b10010_0000???????????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b10010_0000??????????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b10010_0000?????????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b10010_0000????????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b10010_0000???????100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b10010_0000??????1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b10010_0000?????10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b10010_0000????100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b10010_0000???1000000000000000: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b10010_0000??10000000000000000: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b10010_0000?100000000000000000: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b10010_00001000000000000000000: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b10011_??1????????????????????: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b10011_?10????????????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b10011_100????????????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b10011_000???????????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b10011_000??????????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b10011_000?????????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b10011_000????????????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b10011_000???????????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b10011_000??????????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b10011_000?????????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b10011_000????????????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b10011_000???????????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b10011_000??????????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b10011_000?????????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b10011_000????????100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b10011_000???????1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b10011_000??????10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b10011_000?????100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b10011_000????1000000000000000: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b10011_000???10000000000000000: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b10011_000??100000000000000000: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b10011_000?1000000000000000000: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b10011_00010000000000000000000: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b10100_?1?????????????????????: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b10100_10?????????????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b10100_00????????????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b10100_00???????????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b10100_00??????????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b10100_00?????????????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b10100_00????????????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b10100_00???????????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b10100_00??????????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b10100_00?????????????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b10100_00????????????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b10100_00???????????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b10100_00??????????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b10100_00?????????100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b10100_00????????1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b10100_00???????10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b10100_00??????100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b10100_00?????1000000000000000: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b10100_00????10000000000000000: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b10100_00???100000000000000000: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b10100_00??1000000000000000000: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b10100_00?10000000000000000000: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b10100_00100000000000000000000: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b10101_1??????????????????????: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    28'b10101_0?????????????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b10101_0????????????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b10101_0???????????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b10101_0??????????????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b10101_0?????????????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b10101_0????????????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b10101_0???????????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b10101_0??????????????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b10101_0?????????????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b10101_0????????????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b10101_0???????????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b10101_0??????????100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b10101_0?????????1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b10101_0????????10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b10101_0???????100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b10101_0??????1000000000000000: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b10101_0?????10000000000000000: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b10101_0????100000000000000000: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b10101_0???1000000000000000000: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b10101_0??10000000000000000000: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b10101_0?100000000000000000000: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b10101_01000000000000000000000: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b10110_??????????????????????1: begin sel_one_hot_n= 23'b00000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    28'b10110_?????????????????????10: begin sel_one_hot_n= 23'b00000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    28'b10110_????????????????????100: begin sel_one_hot_n= 23'b00000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    28'b10110_???????????????????1000: begin sel_one_hot_n= 23'b00000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    28'b10110_??????????????????10000: begin sel_one_hot_n= 23'b00000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    28'b10110_?????????????????100000: begin sel_one_hot_n= 23'b00000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    28'b10110_????????????????1000000: begin sel_one_hot_n= 23'b00000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    28'b10110_???????????????10000000: begin sel_one_hot_n= 23'b00000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    28'b10110_??????????????100000000: begin sel_one_hot_n= 23'b00000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    28'b10110_?????????????1000000000: begin sel_one_hot_n= 23'b00000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    28'b10110_????????????10000000000: begin sel_one_hot_n= 23'b00000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    28'b10110_???????????100000000000: begin sel_one_hot_n= 23'b00000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    28'b10110_??????????1000000000000: begin sel_one_hot_n= 23'b00000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    28'b10110_?????????10000000000000: begin sel_one_hot_n= 23'b00000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    28'b10110_????????100000000000000: begin sel_one_hot_n= 23'b00000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    28'b10110_???????1000000000000000: begin sel_one_hot_n= 23'b00000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    28'b10110_??????10000000000000000: begin sel_one_hot_n= 23'b00000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    28'b10110_?????100000000000000000: begin sel_one_hot_n= 23'b00000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    28'b10110_????1000000000000000000: begin sel_one_hot_n= 23'b00001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    28'b10110_???10000000000000000000: begin sel_one_hot_n= 23'b00010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    28'b10110_??100000000000000000000: begin sel_one_hot_n= 23'b00100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    28'b10110_?1000000000000000000000: begin sel_one_hot_n= 23'b01000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    28'b10110_10000000000000000000000: begin sel_one_hot_n= 23'b10000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    default: begin sel_one_hot_n= {23{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {23{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           5'b00000 : hold_on_sr = ( reqs_i == 23'b01000000000000000000000 );
           5'b00001 : hold_on_sr = ( reqs_i == 23'b00100000000000000000000 );
           5'b00010 : hold_on_sr = ( reqs_i == 23'b00010000000000000000000 );
           5'b00011 : hold_on_sr = ( reqs_i == 23'b00001000000000000000000 );
           5'b00100 : hold_on_sr = ( reqs_i == 23'b00000100000000000000000 );
           5'b00101 : hold_on_sr = ( reqs_i == 23'b00000010000000000000000 );
           5'b00110 : hold_on_sr = ( reqs_i == 23'b00000001000000000000000 );
           5'b00111 : hold_on_sr = ( reqs_i == 23'b00000000100000000000000 );
           5'b01000 : hold_on_sr = ( reqs_i == 23'b00000000010000000000000 );
           5'b01001 : hold_on_sr = ( reqs_i == 23'b00000000001000000000000 );
           5'b01010 : hold_on_sr = ( reqs_i == 23'b00000000000100000000000 );
           5'b01011 : hold_on_sr = ( reqs_i == 23'b00000000000010000000000 );
           5'b01100 : hold_on_sr = ( reqs_i == 23'b00000000000001000000000 );
           5'b01101 : hold_on_sr = ( reqs_i == 23'b00000000000000100000000 );
           5'b01110 : hold_on_sr = ( reqs_i == 23'b00000000000000010000000 );
           5'b01111 : hold_on_sr = ( reqs_i == 23'b00000000000000001000000 );
           5'b10000 : hold_on_sr = ( reqs_i == 23'b00000000000000000100000 );
           5'b10001 : hold_on_sr = ( reqs_i == 23'b00000000000000000010000 );
           5'b10010 : hold_on_sr = ( reqs_i == 23'b00000000000000000001000 );
           5'b10011 : hold_on_sr = ( reqs_i == 23'b00000000000000000000100 );
           5'b10100 : hold_on_sr = ( reqs_i == 23'b00000000000000000000010 );
           5'b10101 : hold_on_sr = ( reqs_i == 23'b00000000000000000000001 );
           5'b10110 : hold_on_sr = ( reqs_i == 23'b10000000000000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_23 
    assign reset_on_sr = ( reqs_i == 23'b01000000000000000000000 ) 
                       | ( reqs_i == 23'b00100000000000000000000 ) 
                       | ( reqs_i == 23'b00010000000000000000000 ) 
                       | ( reqs_i == 23'b00001000000000000000000 ) 
                       | ( reqs_i == 23'b00000100000000000000000 ) 
                       | ( reqs_i == 23'b00000010000000000000000 ) 
                       | ( reqs_i == 23'b00000001000000000000000 ) 
                       | ( reqs_i == 23'b00000000100000000000000 ) 
                       | ( reqs_i == 23'b00000000010000000000000 ) 
                       | ( reqs_i == 23'b00000000001000000000000 ) 
                       | ( reqs_i == 23'b00000000000100000000000 ) 
                       | ( reqs_i == 23'b00000000000010000000000 ) 
                       | ( reqs_i == 23'b00000000000001000000000 ) 
                       | ( reqs_i == 23'b00000000000000100000000 ) 
                       | ( reqs_i == 23'b00000000000000010000000 ) 
                       | ( reqs_i == 23'b00000000000000001000000 ) 
                       | ( reqs_i == 23'b00000000000000000100000 ) 
                       | ( reqs_i == 23'b00000000000000000010000 ) 
                       | ( reqs_i == 23'b00000000000000000001000 ) 
                       | ( reqs_i == 23'b00000000000000000000100 ) 
                       | ( reqs_i == 23'b00000000000000000000010 ) 
                       | ( reqs_i == 23'b00000000000000000000001 ) 
                       | ( reqs_i == 23'b10000000000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_23

if(inputs_p == 24)
begin: inputs_24

logic [24-1: 0 ] sel_one_hot_n;

always_comb
begin
  unique casez({last_r, reqs_i})
    29'b?????_000000000000000000000000: begin sel_one_hot_n = 24'b000000000000000000000000; tag_o = (lg_inputs_p) ' (0); end // X
    29'b00000_??????????????????????1?: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b00000_?????????????????????10?: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b00000_????????????????????100?: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b00000_???????????????????1000?: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b00000_??????????????????10000?: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b00000_?????????????????100000?: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b00000_????????????????1000000?: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b00000_???????????????10000000?: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b00000_??????????????100000000?: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b00000_?????????????1000000000?: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b00000_????????????10000000000?: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b00000_???????????100000000000?: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b00000_??????????1000000000000?: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b00000_?????????10000000000000?: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b00000_????????100000000000000?: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b00000_???????1000000000000000?: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b00000_??????10000000000000000?: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b00000_?????100000000000000000?: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b00000_????1000000000000000000?: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b00000_???10000000000000000000?: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b00000_??100000000000000000000?: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b00000_?1000000000000000000000?: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b00000_10000000000000000000000?: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b00000_000000000000000000000001: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b00001_?????????????????????1??: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b00001_????????????????????10??: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b00001_???????????????????100??: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b00001_??????????????????1000??: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b00001_?????????????????10000??: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b00001_????????????????100000??: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b00001_???????????????1000000??: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b00001_??????????????10000000??: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b00001_?????????????100000000??: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b00001_????????????1000000000??: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b00001_???????????10000000000??: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b00001_??????????100000000000??: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b00001_?????????1000000000000??: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b00001_????????10000000000000??: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b00001_???????100000000000000??: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b00001_??????1000000000000000??: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b00001_?????10000000000000000??: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b00001_????100000000000000000??: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b00001_???1000000000000000000??: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b00001_??10000000000000000000??: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b00001_?100000000000000000000??: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b00001_1000000000000000000000??: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b00001_0000000000000000000000?1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b00001_000000000000000000000010: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b00010_????????????????????1???: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b00010_???????????????????10???: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b00010_??????????????????100???: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b00010_?????????????????1000???: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b00010_????????????????10000???: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b00010_???????????????100000???: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b00010_??????????????1000000???: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b00010_?????????????10000000???: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b00010_????????????100000000???: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b00010_???????????1000000000???: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b00010_??????????10000000000???: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b00010_?????????100000000000???: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b00010_????????1000000000000???: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b00010_???????10000000000000???: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b00010_??????100000000000000???: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b00010_?????1000000000000000???: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b00010_????10000000000000000???: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b00010_???100000000000000000???: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b00010_??1000000000000000000???: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b00010_?10000000000000000000???: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b00010_100000000000000000000???: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b00010_000000000000000000000??1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b00010_000000000000000000000?10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b00010_000000000000000000000100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b00011_???????????????????1????: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b00011_??????????????????10????: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b00011_?????????????????100????: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b00011_????????????????1000????: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b00011_???????????????10000????: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b00011_??????????????100000????: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b00011_?????????????1000000????: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b00011_????????????10000000????: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b00011_???????????100000000????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b00011_??????????1000000000????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b00011_?????????10000000000????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b00011_????????100000000000????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b00011_???????1000000000000????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b00011_??????10000000000000????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b00011_?????100000000000000????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b00011_????1000000000000000????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b00011_???10000000000000000????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b00011_??100000000000000000????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b00011_?1000000000000000000????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b00011_10000000000000000000????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b00011_00000000000000000000???1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b00011_00000000000000000000??10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b00011_00000000000000000000?100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b00011_000000000000000000001000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b00100_??????????????????1?????: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b00100_?????????????????10?????: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b00100_????????????????100?????: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b00100_???????????????1000?????: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b00100_??????????????10000?????: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b00100_?????????????100000?????: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b00100_????????????1000000?????: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b00100_???????????10000000?????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b00100_??????????100000000?????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b00100_?????????1000000000?????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b00100_????????10000000000?????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b00100_???????100000000000?????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b00100_??????1000000000000?????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b00100_?????10000000000000?????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b00100_????100000000000000?????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b00100_???1000000000000000?????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b00100_??10000000000000000?????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b00100_?100000000000000000?????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b00100_1000000000000000000?????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b00100_0000000000000000000????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b00100_0000000000000000000???10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b00100_0000000000000000000??100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b00100_0000000000000000000?1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b00100_000000000000000000010000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b00101_?????????????????1??????: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b00101_????????????????10??????: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b00101_???????????????100??????: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b00101_??????????????1000??????: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b00101_?????????????10000??????: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b00101_????????????100000??????: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b00101_???????????1000000??????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b00101_??????????10000000??????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b00101_?????????100000000??????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b00101_????????1000000000??????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b00101_???????10000000000??????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b00101_??????100000000000??????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b00101_?????1000000000000??????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b00101_????10000000000000??????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b00101_???100000000000000??????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b00101_??1000000000000000??????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b00101_?10000000000000000??????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b00101_100000000000000000??????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b00101_000000000000000000?????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b00101_000000000000000000????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b00101_000000000000000000???100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b00101_000000000000000000??1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b00101_000000000000000000?10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b00101_000000000000000000100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b00110_????????????????1???????: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b00110_???????????????10???????: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b00110_??????????????100???????: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b00110_?????????????1000???????: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b00110_????????????10000???????: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b00110_???????????100000???????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b00110_??????????1000000???????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b00110_?????????10000000???????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b00110_????????100000000???????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b00110_???????1000000000???????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b00110_??????10000000000???????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b00110_?????100000000000???????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b00110_????1000000000000???????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b00110_???10000000000000???????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b00110_??100000000000000???????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b00110_?1000000000000000???????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b00110_10000000000000000???????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b00110_00000000000000000??????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b00110_00000000000000000?????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b00110_00000000000000000????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b00110_00000000000000000???1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b00110_00000000000000000??10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b00110_00000000000000000?100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b00110_000000000000000001000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b00111_???????????????1????????: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b00111_??????????????10????????: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b00111_?????????????100????????: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b00111_????????????1000????????: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b00111_???????????10000????????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b00111_??????????100000????????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b00111_?????????1000000????????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b00111_????????10000000????????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b00111_???????100000000????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b00111_??????1000000000????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b00111_?????10000000000????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b00111_????100000000000????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b00111_???1000000000000????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b00111_??10000000000000????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b00111_?100000000000000????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b00111_1000000000000000????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b00111_0000000000000000???????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b00111_0000000000000000??????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b00111_0000000000000000?????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b00111_0000000000000000????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b00111_0000000000000000???10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b00111_0000000000000000??100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b00111_0000000000000000?1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b00111_000000000000000010000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01000_??????????????1?????????: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b01000_?????????????10?????????: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b01000_????????????100?????????: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b01000_???????????1000?????????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b01000_??????????10000?????????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b01000_?????????100000?????????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b01000_????????1000000?????????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b01000_???????10000000?????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b01000_??????100000000?????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b01000_?????1000000000?????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b01000_????10000000000?????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b01000_???100000000000?????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b01000_??1000000000000?????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b01000_?10000000000000?????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b01000_100000000000000?????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b01000_000000000000000????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b01000_000000000000000???????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b01000_000000000000000??????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b01000_000000000000000?????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b01000_000000000000000????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b01000_000000000000000???100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b01000_000000000000000??1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b01000_000000000000000?10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01000_000000000000000100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b01001_?????????????1??????????: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b01001_????????????10??????????: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b01001_???????????100??????????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b01001_??????????1000??????????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b01001_?????????10000??????????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b01001_????????100000??????????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b01001_???????1000000??????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b01001_??????10000000??????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b01001_?????100000000??????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b01001_????1000000000??????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b01001_???10000000000??????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b01001_??100000000000??????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b01001_?1000000000000??????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b01001_10000000000000??????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b01001_00000000000000?????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b01001_00000000000000????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b01001_00000000000000???????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b01001_00000000000000??????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b01001_00000000000000?????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b01001_00000000000000????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b01001_00000000000000???1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b01001_00000000000000??10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01001_00000000000000?100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b01001_000000000000001000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b01010_????????????1???????????: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b01010_???????????10???????????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b01010_??????????100???????????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b01010_?????????1000???????????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b01010_????????10000???????????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b01010_???????100000???????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b01010_??????1000000???????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b01010_?????10000000???????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b01010_????100000000???????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b01010_???1000000000???????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b01010_??10000000000???????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b01010_?100000000000???????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b01010_1000000000000???????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b01010_0000000000000??????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b01010_0000000000000?????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b01010_0000000000000????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b01010_0000000000000???????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b01010_0000000000000??????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b01010_0000000000000?????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b01010_0000000000000????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b01010_0000000000000???10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01010_0000000000000??100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b01010_0000000000000?1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b01010_000000000000010000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b01011_???????????1????????????: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b01011_??????????10????????????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b01011_?????????100????????????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b01011_????????1000????????????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b01011_???????10000????????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b01011_??????100000????????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b01011_?????1000000????????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b01011_????10000000????????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b01011_???100000000????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b01011_??1000000000????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b01011_?10000000000????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b01011_100000000000????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b01011_000000000000???????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b01011_000000000000??????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b01011_000000000000?????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b01011_000000000000????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b01011_000000000000???????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b01011_000000000000??????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b01011_000000000000?????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b01011_000000000000????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01011_000000000000???100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b01011_000000000000??1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b01011_000000000000?10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b01011_000000000000100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b01100_??????????1?????????????: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b01100_?????????10?????????????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b01100_????????100?????????????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b01100_???????1000?????????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b01100_??????10000?????????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b01100_?????100000?????????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b01100_????1000000?????????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b01100_???10000000?????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b01100_??100000000?????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b01100_?1000000000?????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b01100_10000000000?????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b01100_00000000000????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b01100_00000000000???????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b01100_00000000000??????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b01100_00000000000?????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b01100_00000000000????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b01100_00000000000???????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b01100_00000000000??????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b01100_00000000000?????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01100_00000000000????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b01100_00000000000???1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b01100_00000000000??10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b01100_00000000000?100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b01100_000000000001000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b01101_?????????1??????????????: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b01101_????????10??????????????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b01101_???????100??????????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b01101_??????1000??????????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b01101_?????10000??????????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b01101_????100000??????????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b01101_???1000000??????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b01101_??10000000??????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b01101_?100000000??????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b01101_1000000000??????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b01101_0000000000?????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b01101_0000000000????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b01101_0000000000???????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b01101_0000000000??????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b01101_0000000000?????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b01101_0000000000????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b01101_0000000000???????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b01101_0000000000??????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01101_0000000000?????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b01101_0000000000????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b01101_0000000000???10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b01101_0000000000??100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b01101_0000000000?1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b01101_000000000010000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b01110_????????1???????????????: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b01110_???????10???????????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b01110_??????100???????????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b01110_?????1000???????????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b01110_????10000???????????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b01110_???100000???????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b01110_??1000000???????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b01110_?10000000???????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b01110_100000000???????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b01110_000000000??????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b01110_000000000?????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b01110_000000000????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b01110_000000000???????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b01110_000000000??????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b01110_000000000?????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b01110_000000000????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b01110_000000000???????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01110_000000000??????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b01110_000000000?????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b01110_000000000????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b01110_000000000???100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b01110_000000000??1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b01110_000000000?10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b01110_000000000100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b01111_???????1????????????????: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b01111_??????10????????????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b01111_?????100????????????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b01111_????1000????????????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b01111_???10000????????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b01111_??100000????????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b01111_?1000000????????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b01111_10000000????????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b01111_00000000???????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b01111_00000000??????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b01111_00000000?????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b01111_00000000????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b01111_00000000???????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b01111_00000000??????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b01111_00000000?????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b01111_00000000????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b01111_00000000???????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b01111_00000000??????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b01111_00000000?????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b01111_00000000????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b01111_00000000???1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b01111_00000000??10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b01111_00000000?100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b01111_000000001000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10000_??????1?????????????????: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b10000_?????10?????????????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b10000_????100?????????????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b10000_???1000?????????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b10000_??10000?????????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b10000_?100000?????????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b10000_1000000?????????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b10000_0000000????????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b10000_0000000???????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b10000_0000000??????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b10000_0000000?????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b10000_0000000????????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b10000_0000000???????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b10000_0000000??????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b10000_0000000?????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b10000_0000000????????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b10000_0000000???????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b10000_0000000??????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b10000_0000000?????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b10000_0000000????1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b10000_0000000???10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b10000_0000000??100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b10000_0000000?1000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10000_000000010000000000000000: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b10001_?????1??????????????????: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b10001_????10??????????????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b10001_???100??????????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b10001_??1000??????????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b10001_?10000??????????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b10001_100000??????????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b10001_000000?????????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b10001_000000????????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b10001_000000???????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b10001_000000??????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b10001_000000?????????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b10001_000000????????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b10001_000000???????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b10001_000000??????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b10001_000000?????????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b10001_000000????????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b10001_000000???????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b10001_000000??????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b10001_000000?????1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b10001_000000????10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b10001_000000???100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b10001_000000??1000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10001_000000?10000000000000000: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b10001_000000100000000000000000: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b10010_????1???????????????????: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b10010_???10???????????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b10010_??100???????????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b10010_?1000???????????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b10010_10000???????????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b10010_00000??????????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b10010_00000?????????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b10010_00000????????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b10010_00000???????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b10010_00000??????????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b10010_00000?????????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b10010_00000????????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b10010_00000???????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b10010_00000??????????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b10010_00000?????????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b10010_00000????????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b10010_00000???????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b10010_00000??????1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b10010_00000?????10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b10010_00000????100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b10010_00000???1000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10010_00000??10000000000000000: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b10010_00000?100000000000000000: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b10010_000001000000000000000000: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b10011_???1????????????????????: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b10011_??10????????????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b10011_?100????????????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b10011_1000????????????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b10011_0000???????????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b10011_0000??????????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b10011_0000?????????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b10011_0000????????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b10011_0000???????????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b10011_0000??????????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b10011_0000?????????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b10011_0000????????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b10011_0000???????????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b10011_0000??????????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b10011_0000?????????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b10011_0000????????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b10011_0000???????1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b10011_0000??????10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b10011_0000?????100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b10011_0000????1000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10011_0000???10000000000000000: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b10011_0000??100000000000000000: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b10011_0000?1000000000000000000: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b10011_000010000000000000000000: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b10100_??1?????????????????????: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b10100_?10?????????????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b10100_100?????????????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b10100_000????????????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b10100_000???????????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b10100_000??????????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b10100_000?????????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b10100_000????????????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b10100_000???????????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b10100_000??????????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b10100_000?????????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b10100_000????????????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b10100_000???????????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b10100_000??????????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b10100_000?????????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b10100_000????????1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b10100_000???????10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b10100_000??????100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b10100_000?????1000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10100_000????10000000000000000: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b10100_000???100000000000000000: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b10100_000??1000000000000000000: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b10100_000?10000000000000000000: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b10100_000100000000000000000000: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b10101_?1??????????????????????: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b10101_10??????????????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b10101_00?????????????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b10101_00????????????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b10101_00???????????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b10101_00??????????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b10101_00?????????????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b10101_00????????????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b10101_00???????????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b10101_00??????????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b10101_00?????????????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b10101_00????????????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b10101_00???????????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b10101_00??????????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b10101_00?????????1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b10101_00????????10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b10101_00???????100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b10101_00??????1000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10101_00?????10000000000000000: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b10101_00????100000000000000000: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b10101_00???1000000000000000000: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b10101_00??10000000000000000000: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b10101_00?100000000000000000000: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b10101_001000000000000000000000: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b10110_1???????????????????????: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    29'b10110_0??????????????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b10110_0?????????????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b10110_0????????????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b10110_0???????????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b10110_0??????????????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b10110_0?????????????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b10110_0????????????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b10110_0???????????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b10110_0??????????????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b10110_0?????????????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b10110_0????????????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b10110_0???????????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b10110_0??????????1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b10110_0?????????10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b10110_0????????100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b10110_0???????1000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10110_0??????10000000000000000: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b10110_0?????100000000000000000: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b10110_0????1000000000000000000: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b10110_0???10000000000000000000: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b10110_0??100000000000000000000: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b10110_0?1000000000000000000000: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b10110_010000000000000000000000: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b10111_???????????????????????1: begin sel_one_hot_n= 24'b000000000000000000000001; tag_o = (lg_inputs_p) ' (0); end
    29'b10111_??????????????????????10: begin sel_one_hot_n= 24'b000000000000000000000010; tag_o = (lg_inputs_p) ' (1); end
    29'b10111_?????????????????????100: begin sel_one_hot_n= 24'b000000000000000000000100; tag_o = (lg_inputs_p) ' (2); end
    29'b10111_????????????????????1000: begin sel_one_hot_n= 24'b000000000000000000001000; tag_o = (lg_inputs_p) ' (3); end
    29'b10111_???????????????????10000: begin sel_one_hot_n= 24'b000000000000000000010000; tag_o = (lg_inputs_p) ' (4); end
    29'b10111_??????????????????100000: begin sel_one_hot_n= 24'b000000000000000000100000; tag_o = (lg_inputs_p) ' (5); end
    29'b10111_?????????????????1000000: begin sel_one_hot_n= 24'b000000000000000001000000; tag_o = (lg_inputs_p) ' (6); end
    29'b10111_????????????????10000000: begin sel_one_hot_n= 24'b000000000000000010000000; tag_o = (lg_inputs_p) ' (7); end
    29'b10111_???????????????100000000: begin sel_one_hot_n= 24'b000000000000000100000000; tag_o = (lg_inputs_p) ' (8); end
    29'b10111_??????????????1000000000: begin sel_one_hot_n= 24'b000000000000001000000000; tag_o = (lg_inputs_p) ' (9); end
    29'b10111_?????????????10000000000: begin sel_one_hot_n= 24'b000000000000010000000000; tag_o = (lg_inputs_p) ' (10); end
    29'b10111_????????????100000000000: begin sel_one_hot_n= 24'b000000000000100000000000; tag_o = (lg_inputs_p) ' (11); end
    29'b10111_???????????1000000000000: begin sel_one_hot_n= 24'b000000000001000000000000; tag_o = (lg_inputs_p) ' (12); end
    29'b10111_??????????10000000000000: begin sel_one_hot_n= 24'b000000000010000000000000; tag_o = (lg_inputs_p) ' (13); end
    29'b10111_?????????100000000000000: begin sel_one_hot_n= 24'b000000000100000000000000; tag_o = (lg_inputs_p) ' (14); end
    29'b10111_????????1000000000000000: begin sel_one_hot_n= 24'b000000001000000000000000; tag_o = (lg_inputs_p) ' (15); end
    29'b10111_???????10000000000000000: begin sel_one_hot_n= 24'b000000010000000000000000; tag_o = (lg_inputs_p) ' (16); end
    29'b10111_??????100000000000000000: begin sel_one_hot_n= 24'b000000100000000000000000; tag_o = (lg_inputs_p) ' (17); end
    29'b10111_?????1000000000000000000: begin sel_one_hot_n= 24'b000001000000000000000000; tag_o = (lg_inputs_p) ' (18); end
    29'b10111_????10000000000000000000: begin sel_one_hot_n= 24'b000010000000000000000000; tag_o = (lg_inputs_p) ' (19); end
    29'b10111_???100000000000000000000: begin sel_one_hot_n= 24'b000100000000000000000000; tag_o = (lg_inputs_p) ' (20); end
    29'b10111_??1000000000000000000000: begin sel_one_hot_n= 24'b001000000000000000000000; tag_o = (lg_inputs_p) ' (21); end
    29'b10111_?10000000000000000000000: begin sel_one_hot_n= 24'b010000000000000000000000; tag_o = (lg_inputs_p) ' (22); end
    29'b10111_100000000000000000000000: begin sel_one_hot_n= 24'b100000000000000000000000; tag_o = (lg_inputs_p) ' (23); end
    default: begin sel_one_hot_n= {24{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

assign sel_one_hot_o = sel_one_hot_n;
assign grants_o      = sel_one_hot_n & {24{grants_en_i}} ;   
    

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           5'b00000 : hold_on_sr = ( reqs_i == 24'b010000000000000000000000 );
           5'b00001 : hold_on_sr = ( reqs_i == 24'b001000000000000000000000 );
           5'b00010 : hold_on_sr = ( reqs_i == 24'b000100000000000000000000 );
           5'b00011 : hold_on_sr = ( reqs_i == 24'b000010000000000000000000 );
           5'b00100 : hold_on_sr = ( reqs_i == 24'b000001000000000000000000 );
           5'b00101 : hold_on_sr = ( reqs_i == 24'b000000100000000000000000 );
           5'b00110 : hold_on_sr = ( reqs_i == 24'b000000010000000000000000 );
           5'b00111 : hold_on_sr = ( reqs_i == 24'b000000001000000000000000 );
           5'b01000 : hold_on_sr = ( reqs_i == 24'b000000000100000000000000 );
           5'b01001 : hold_on_sr = ( reqs_i == 24'b000000000010000000000000 );
           5'b01010 : hold_on_sr = ( reqs_i == 24'b000000000001000000000000 );
           5'b01011 : hold_on_sr = ( reqs_i == 24'b000000000000100000000000 );
           5'b01100 : hold_on_sr = ( reqs_i == 24'b000000000000010000000000 );
           5'b01101 : hold_on_sr = ( reqs_i == 24'b000000000000001000000000 );
           5'b01110 : hold_on_sr = ( reqs_i == 24'b000000000000000100000000 );
           5'b01111 : hold_on_sr = ( reqs_i == 24'b000000000000000010000000 );
           5'b10000 : hold_on_sr = ( reqs_i == 24'b000000000000000001000000 );
           5'b10001 : hold_on_sr = ( reqs_i == 24'b000000000000000000100000 );
           5'b10010 : hold_on_sr = ( reqs_i == 24'b000000000000000000010000 );
           5'b10011 : hold_on_sr = ( reqs_i == 24'b000000000000000000001000 );
           5'b10100 : hold_on_sr = ( reqs_i == 24'b000000000000000000000100 );
           5'b10101 : hold_on_sr = ( reqs_i == 24'b000000000000000000000010 );
           5'b10110 : hold_on_sr = ( reqs_i == 24'b000000000000000000000001 );
           5'b10111 : hold_on_sr = ( reqs_i == 24'b100000000000000000000000 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of always_comb

end else begin:not_hold_on_sr_p
    assign hold_on_sr = '0;
end //end of hold_on_sr_p 

if ( reset_on_sr_p ) begin:reset_on_24 
    assign reset_on_sr = ( reqs_i == 24'b010000000000000000000000 ) 
                       | ( reqs_i == 24'b001000000000000000000000 ) 
                       | ( reqs_i == 24'b000100000000000000000000 ) 
                       | ( reqs_i == 24'b000010000000000000000000 ) 
                       | ( reqs_i == 24'b000001000000000000000000 ) 
                       | ( reqs_i == 24'b000000100000000000000000 ) 
                       | ( reqs_i == 24'b000000010000000000000000 ) 
                       | ( reqs_i == 24'b000000001000000000000000 ) 
                       | ( reqs_i == 24'b000000000100000000000000 ) 
                       | ( reqs_i == 24'b000000000010000000000000 ) 
                       | ( reqs_i == 24'b000000000001000000000000 ) 
                       | ( reqs_i == 24'b000000000000100000000000 ) 
                       | ( reqs_i == 24'b000000000000010000000000 ) 
                       | ( reqs_i == 24'b000000000000001000000000 ) 
                       | ( reqs_i == 24'b000000000000000100000000 ) 
                       | ( reqs_i == 24'b000000000000000010000000 ) 
                       | ( reqs_i == 24'b000000000000000001000000 ) 
                       | ( reqs_i == 24'b000000000000000000100000 ) 
                       | ( reqs_i == 24'b000000000000000000010000 ) 
                       | ( reqs_i == 24'b000000000000000000001000 ) 
                       | ( reqs_i == 24'b000000000000000000000100 ) 
                       | ( reqs_i == 24'b000000000000000000000010 ) 
                       | ( reqs_i == 24'b000000000000000000000001 ) 
                       | ( reqs_i == 24'b100000000000000000000000 ) 
                       ;

end else begin:not_reset_on_sr_p
    assign reset_on_sr = '0;
end //end of reset_on_sr_p 

end: inputs_24
// if (inputs_p >  24 ) initial begin $error("unhandled number of inputs"); end


assign v_o = | reqs_i ;

if(inputs_p == 1)
  assign last_r = 1'b0;
else
  begin
    always_comb
      if( hold_on_sr_p ) begin: last_n_gen
        last_n = hold_on_sr ? last_r :
               ( yumi_i     ? tag_o  : last_r );  
      end else if( reset_on_sr_p ) begin: reset_on_last_n_gen
        last_n = reset_on_sr? (inputs_p-2'd2) :
               ( yumi_i     ?tag_o : last_r );  
      end else if( hold_on_valid_p ) begin: hold_on_last_n_gen
        // Need to manually handle wrap around on non-power of two case, else reuse subtraction
        last_n = yumi_i ? tag_o
               : v_o ? ((~`BSG_IS_POW2(inputs_p) && tag_o == '0) ? (lg_inputs_p)'(inputs_p-1) : (tag_o-1'b1))
                     : last_r;
      end else
        last_n = (yumi_i ? tag_o:last_r);

    always_ff @(posedge clk_i)
      last_r <= (reset_i) ? (lg_inputs_p)'(0):last_n;
  end

endmodule

`BSG_ABSTRACT_MODULE(bsg_round_robin_arb)
