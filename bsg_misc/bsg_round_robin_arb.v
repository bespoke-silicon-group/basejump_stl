// Round robin arbitration unit

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

module bsg_round_robin_arb #(inputs_p      = -1
                                     ,lg_inputs_p   =`BSG_SAFE_CLOG2(inputs_p)
                                     ,reset_on_sr_p = 1'b0
                                     ,hold_on_sr_p  = 1'b0 )
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
        last_n = reset_on_sr? (inputs_p-2) :
               ( yumi_i     ?tag_o : last_r );  
      end else
        last_n = (yumi_i ? tag_o:last_r);

    always_ff @(posedge clk_i)
      last_r <= (reset_i) ? (lg_inputs_p)'(0):last_n;
  end

endmodule
