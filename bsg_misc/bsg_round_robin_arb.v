// Round robin arbitration unit

// Automatically generated using bsg_round_robin_arb.py
// DO NOT MODIFY

module bsg_round_robin_arb #(inputs_p      = "not assigned" 
                                     ,lg_inputs_p   =`BSG_SAFE_CLOG2(inputs_p)
                                     ,hold_on_sr_p  =1'b0 )
    (input clk_i
    , input reset_i
    , input grants_en_i // whether to suppress grants_o

    // these are "third-party" inputs/outputs
    // that are part of the "data plane"

    , input  [inputs_p-1:0] reqs_i
    , output logic [inputs_p-1:0] grants_o

    // end third-party inputs/outputs

    , output v_o                           // whether any grants were given
    , output logic [lg_inputs_p-1:0] tag_o // to which input the grant was given
    , input yumi_i                         // yes, go ahead with whatever grants_o proposed
    );

logic [lg_inputs_p-1:0] last, last_n, last_r;
logic hold_on_sr;




if(inputs_p == 1)
begin: inputs_1
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    3'b0_?_?: begin grants_o = 1'b0; tag_o = (lg_inputs_p) ' (0); end // X
    3'b1_?_0: begin grants_o = 1'b0; tag_o = (lg_inputs_p) ' (0); end // X
    3'b1_0_1: begin grants_o = 1'b1; tag_o = (lg_inputs_p) ' (0); end
    default: begin grants_o = {1{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           1'b0 : hold_on_sr = ( reqs_i == 1'b1 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_1

if(inputs_p == 2)
begin: inputs_2
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    4'b0_?_??: begin grants_o = 2'b00; tag_o = (lg_inputs_p) ' (0); end // X
    4'b1_?_00: begin grants_o = 2'b00; tag_o = (lg_inputs_p) ' (0); end // X
    4'b1_0_1?: begin grants_o = 2'b10; tag_o = (lg_inputs_p) ' (1); end
    4'b1_0_01: begin grants_o = 2'b01; tag_o = (lg_inputs_p) ' (0); end
    4'b1_1_?1: begin grants_o = 2'b01; tag_o = (lg_inputs_p) ' (0); end
    4'b1_1_10: begin grants_o = 2'b10; tag_o = (lg_inputs_p) ' (1); end
    default: begin grants_o = {2{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           1'b0 : hold_on_sr = ( reqs_i == 2'b01 );
           default: hold_on_sr = ( reqs_i == 2'b10 );
       endcase
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_2

if(inputs_p == 3)
begin: inputs_3
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    6'b0_??_???: begin grants_o = 3'b000; tag_o = (lg_inputs_p) ' (0); end // X
    6'b1_??_000: begin grants_o = 3'b000; tag_o = (lg_inputs_p) ' (0); end // X
    6'b1_00_?1?: begin grants_o = 3'b010; tag_o = (lg_inputs_p) ' (1); end
    6'b1_00_10?: begin grants_o = 3'b100; tag_o = (lg_inputs_p) ' (2); end
    6'b1_00_001: begin grants_o = 3'b001; tag_o = (lg_inputs_p) ' (0); end
    6'b1_01_1??: begin grants_o = 3'b100; tag_o = (lg_inputs_p) ' (2); end
    6'b1_01_0?1: begin grants_o = 3'b001; tag_o = (lg_inputs_p) ' (0); end
    6'b1_01_010: begin grants_o = 3'b010; tag_o = (lg_inputs_p) ' (1); end
    6'b1_10_??1: begin grants_o = 3'b001; tag_o = (lg_inputs_p) ' (0); end
    6'b1_10_?10: begin grants_o = 3'b010; tag_o = (lg_inputs_p) ' (1); end
    6'b1_10_100: begin grants_o = 3'b100; tag_o = (lg_inputs_p) ' (2); end
    default: begin grants_o = {3{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           2'b00 : hold_on_sr = ( reqs_i == 3'b010 );
           2'b01 : hold_on_sr = ( reqs_i == 3'b001 );
           2'b10 : hold_on_sr = ( reqs_i == 3'b100 );
           default : hold_on_sr = 1'b0;
       endcase
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_3

if(inputs_p == 4)
begin: inputs_4
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    7'b0_??_????: begin grants_o = 4'b0000; tag_o = (lg_inputs_p) ' (0); end // X
    7'b1_??_0000: begin grants_o = 4'b0000; tag_o = (lg_inputs_p) ' (0); end // X
    7'b1_00_??1?: begin grants_o = 4'b0010; tag_o = (lg_inputs_p) ' (1); end
    7'b1_00_?10?: begin grants_o = 4'b0100; tag_o = (lg_inputs_p) ' (2); end
    7'b1_00_100?: begin grants_o = 4'b1000; tag_o = (lg_inputs_p) ' (3); end
    7'b1_00_0001: begin grants_o = 4'b0001; tag_o = (lg_inputs_p) ' (0); end
    7'b1_01_?1??: begin grants_o = 4'b0100; tag_o = (lg_inputs_p) ' (2); end
    7'b1_01_10??: begin grants_o = 4'b1000; tag_o = (lg_inputs_p) ' (3); end
    7'b1_01_00?1: begin grants_o = 4'b0001; tag_o = (lg_inputs_p) ' (0); end
    7'b1_01_0010: begin grants_o = 4'b0010; tag_o = (lg_inputs_p) ' (1); end
    7'b1_10_1???: begin grants_o = 4'b1000; tag_o = (lg_inputs_p) ' (3); end
    7'b1_10_0??1: begin grants_o = 4'b0001; tag_o = (lg_inputs_p) ' (0); end
    7'b1_10_0?10: begin grants_o = 4'b0010; tag_o = (lg_inputs_p) ' (1); end
    7'b1_10_0100: begin grants_o = 4'b0100; tag_o = (lg_inputs_p) ' (2); end
    7'b1_11_???1: begin grants_o = 4'b0001; tag_o = (lg_inputs_p) ' (0); end
    7'b1_11_??10: begin grants_o = 4'b0010; tag_o = (lg_inputs_p) ' (1); end
    7'b1_11_?100: begin grants_o = 4'b0100; tag_o = (lg_inputs_p) ' (2); end
    7'b1_11_1000: begin grants_o = 4'b1000; tag_o = (lg_inputs_p) ' (3); end
    default: begin grants_o = {4{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

if ( hold_on_sr_p ) begin 
   
    always_comb begin
        unique casez( last_r )
           2'b00 : hold_on_sr = ( reqs_i == 4'b0100 );
           2'b01 : hold_on_sr = ( reqs_i == 4'b0010 );
           2'b10 : hold_on_sr = ( reqs_i == 4'b0001 );
           default: hold_on_sr = ( reqs_i == 4'b1000 );
       endcase
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_4

if(inputs_p == 5)
begin: inputs_5
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    9'b0_???_?????: begin grants_o = 5'b00000; tag_o = (lg_inputs_p) ' (0); end // X
    9'b1_???_00000: begin grants_o = 5'b00000; tag_o = (lg_inputs_p) ' (0); end // X
    9'b1_000_???1?: begin grants_o = 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    9'b1_000_??10?: begin grants_o = 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    9'b1_000_?100?: begin grants_o = 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    9'b1_000_1000?: begin grants_o = 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    9'b1_000_00001: begin grants_o = 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    9'b1_001_??1??: begin grants_o = 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    9'b1_001_?10??: begin grants_o = 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    9'b1_001_100??: begin grants_o = 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    9'b1_001_000?1: begin grants_o = 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    9'b1_001_00010: begin grants_o = 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    9'b1_010_?1???: begin grants_o = 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    9'b1_010_10???: begin grants_o = 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    9'b1_010_00??1: begin grants_o = 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    9'b1_010_00?10: begin grants_o = 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    9'b1_010_00100: begin grants_o = 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    9'b1_011_1????: begin grants_o = 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    9'b1_011_0???1: begin grants_o = 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    9'b1_011_0??10: begin grants_o = 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    9'b1_011_0?100: begin grants_o = 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    9'b1_011_01000: begin grants_o = 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    9'b1_100_????1: begin grants_o = 5'b00001; tag_o = (lg_inputs_p) ' (0); end
    9'b1_100_???10: begin grants_o = 5'b00010; tag_o = (lg_inputs_p) ' (1); end
    9'b1_100_??100: begin grants_o = 5'b00100; tag_o = (lg_inputs_p) ' (2); end
    9'b1_100_?1000: begin grants_o = 5'b01000; tag_o = (lg_inputs_p) ' (3); end
    9'b1_100_10000: begin grants_o = 5'b10000; tag_o = (lg_inputs_p) ' (4); end
    default: begin grants_o = {5{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

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
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_5

if(inputs_p == 6)
begin: inputs_6
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    10'b0_???_??????: begin grants_o = 6'b000000; tag_o = (lg_inputs_p) ' (0); end // X
    10'b1_???_000000: begin grants_o = 6'b000000; tag_o = (lg_inputs_p) ' (0); end // X
    10'b1_000_????1?: begin grants_o = 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    10'b1_000_???10?: begin grants_o = 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    10'b1_000_??100?: begin grants_o = 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    10'b1_000_?1000?: begin grants_o = 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    10'b1_000_10000?: begin grants_o = 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    10'b1_000_000001: begin grants_o = 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    10'b1_001_???1??: begin grants_o = 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    10'b1_001_??10??: begin grants_o = 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    10'b1_001_?100??: begin grants_o = 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    10'b1_001_1000??: begin grants_o = 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    10'b1_001_0000?1: begin grants_o = 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    10'b1_001_000010: begin grants_o = 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    10'b1_010_??1???: begin grants_o = 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    10'b1_010_?10???: begin grants_o = 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    10'b1_010_100???: begin grants_o = 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    10'b1_010_000??1: begin grants_o = 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    10'b1_010_000?10: begin grants_o = 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    10'b1_010_000100: begin grants_o = 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    10'b1_011_?1????: begin grants_o = 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    10'b1_011_10????: begin grants_o = 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    10'b1_011_00???1: begin grants_o = 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    10'b1_011_00??10: begin grants_o = 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    10'b1_011_00?100: begin grants_o = 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    10'b1_011_001000: begin grants_o = 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    10'b1_100_1?????: begin grants_o = 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    10'b1_100_0????1: begin grants_o = 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    10'b1_100_0???10: begin grants_o = 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    10'b1_100_0??100: begin grants_o = 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    10'b1_100_0?1000: begin grants_o = 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    10'b1_100_010000: begin grants_o = 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    10'b1_101_?????1: begin grants_o = 6'b000001; tag_o = (lg_inputs_p) ' (0); end
    10'b1_101_????10: begin grants_o = 6'b000010; tag_o = (lg_inputs_p) ' (1); end
    10'b1_101_???100: begin grants_o = 6'b000100; tag_o = (lg_inputs_p) ' (2); end
    10'b1_101_??1000: begin grants_o = 6'b001000; tag_o = (lg_inputs_p) ' (3); end
    10'b1_101_?10000: begin grants_o = 6'b010000; tag_o = (lg_inputs_p) ' (4); end
    10'b1_101_100000: begin grants_o = 6'b100000; tag_o = (lg_inputs_p) ' (5); end
    default: begin grants_o = {6{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

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
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_6

if(inputs_p == 7)
begin: inputs_7
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    11'b0_???_???????: begin grants_o = 7'b0000000; tag_o = (lg_inputs_p) ' (0); end // X
    11'b1_???_0000000: begin grants_o = 7'b0000000; tag_o = (lg_inputs_p) ' (0); end // X
    11'b1_000_?????1?: begin grants_o = 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    11'b1_000_????10?: begin grants_o = 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    11'b1_000_???100?: begin grants_o = 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    11'b1_000_??1000?: begin grants_o = 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    11'b1_000_?10000?: begin grants_o = 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    11'b1_000_100000?: begin grants_o = 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    11'b1_000_0000001: begin grants_o = 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    11'b1_001_????1??: begin grants_o = 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    11'b1_001_???10??: begin grants_o = 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    11'b1_001_??100??: begin grants_o = 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    11'b1_001_?1000??: begin grants_o = 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    11'b1_001_10000??: begin grants_o = 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    11'b1_001_00000?1: begin grants_o = 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    11'b1_001_0000010: begin grants_o = 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    11'b1_010_???1???: begin grants_o = 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    11'b1_010_??10???: begin grants_o = 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    11'b1_010_?100???: begin grants_o = 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    11'b1_010_1000???: begin grants_o = 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    11'b1_010_0000??1: begin grants_o = 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    11'b1_010_0000?10: begin grants_o = 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    11'b1_010_0000100: begin grants_o = 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    11'b1_011_??1????: begin grants_o = 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    11'b1_011_?10????: begin grants_o = 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    11'b1_011_100????: begin grants_o = 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    11'b1_011_000???1: begin grants_o = 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    11'b1_011_000??10: begin grants_o = 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    11'b1_011_000?100: begin grants_o = 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    11'b1_011_0001000: begin grants_o = 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    11'b1_100_?1?????: begin grants_o = 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    11'b1_100_10?????: begin grants_o = 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    11'b1_100_00????1: begin grants_o = 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    11'b1_100_00???10: begin grants_o = 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    11'b1_100_00??100: begin grants_o = 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    11'b1_100_00?1000: begin grants_o = 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    11'b1_100_0010000: begin grants_o = 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    11'b1_101_1??????: begin grants_o = 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    11'b1_101_0?????1: begin grants_o = 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    11'b1_101_0????10: begin grants_o = 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    11'b1_101_0???100: begin grants_o = 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    11'b1_101_0??1000: begin grants_o = 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    11'b1_101_0?10000: begin grants_o = 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    11'b1_101_0100000: begin grants_o = 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    11'b1_110_??????1: begin grants_o = 7'b0000001; tag_o = (lg_inputs_p) ' (0); end
    11'b1_110_?????10: begin grants_o = 7'b0000010; tag_o = (lg_inputs_p) ' (1); end
    11'b1_110_????100: begin grants_o = 7'b0000100; tag_o = (lg_inputs_p) ' (2); end
    11'b1_110_???1000: begin grants_o = 7'b0001000; tag_o = (lg_inputs_p) ' (3); end
    11'b1_110_??10000: begin grants_o = 7'b0010000; tag_o = (lg_inputs_p) ' (4); end
    11'b1_110_?100000: begin grants_o = 7'b0100000; tag_o = (lg_inputs_p) ' (5); end
    11'b1_110_1000000: begin grants_o = 7'b1000000; tag_o = (lg_inputs_p) ' (6); end
    default: begin grants_o = {7{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

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
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_7

if(inputs_p == 8)
begin: inputs_8
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    12'b0_???_????????: begin grants_o = 8'b00000000; tag_o = (lg_inputs_p) ' (0); end // X
    12'b1_???_00000000: begin grants_o = 8'b00000000; tag_o = (lg_inputs_p) ' (0); end // X
    12'b1_000_??????1?: begin grants_o = 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    12'b1_000_?????10?: begin grants_o = 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    12'b1_000_????100?: begin grants_o = 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    12'b1_000_???1000?: begin grants_o = 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    12'b1_000_??10000?: begin grants_o = 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    12'b1_000_?100000?: begin grants_o = 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    12'b1_000_1000000?: begin grants_o = 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    12'b1_000_00000001: begin grants_o = 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    12'b1_001_?????1??: begin grants_o = 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    12'b1_001_????10??: begin grants_o = 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    12'b1_001_???100??: begin grants_o = 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    12'b1_001_??1000??: begin grants_o = 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    12'b1_001_?10000??: begin grants_o = 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    12'b1_001_100000??: begin grants_o = 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    12'b1_001_000000?1: begin grants_o = 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    12'b1_001_00000010: begin grants_o = 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    12'b1_010_????1???: begin grants_o = 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    12'b1_010_???10???: begin grants_o = 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    12'b1_010_??100???: begin grants_o = 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    12'b1_010_?1000???: begin grants_o = 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    12'b1_010_10000???: begin grants_o = 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    12'b1_010_00000??1: begin grants_o = 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    12'b1_010_00000?10: begin grants_o = 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    12'b1_010_00000100: begin grants_o = 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    12'b1_011_???1????: begin grants_o = 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    12'b1_011_??10????: begin grants_o = 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    12'b1_011_?100????: begin grants_o = 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    12'b1_011_1000????: begin grants_o = 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    12'b1_011_0000???1: begin grants_o = 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    12'b1_011_0000??10: begin grants_o = 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    12'b1_011_0000?100: begin grants_o = 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    12'b1_011_00001000: begin grants_o = 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    12'b1_100_??1?????: begin grants_o = 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    12'b1_100_?10?????: begin grants_o = 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    12'b1_100_100?????: begin grants_o = 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    12'b1_100_000????1: begin grants_o = 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    12'b1_100_000???10: begin grants_o = 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    12'b1_100_000??100: begin grants_o = 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    12'b1_100_000?1000: begin grants_o = 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    12'b1_100_00010000: begin grants_o = 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    12'b1_101_?1??????: begin grants_o = 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    12'b1_101_10??????: begin grants_o = 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    12'b1_101_00?????1: begin grants_o = 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    12'b1_101_00????10: begin grants_o = 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    12'b1_101_00???100: begin grants_o = 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    12'b1_101_00??1000: begin grants_o = 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    12'b1_101_00?10000: begin grants_o = 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    12'b1_101_00100000: begin grants_o = 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    12'b1_110_1???????: begin grants_o = 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    12'b1_110_0??????1: begin grants_o = 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    12'b1_110_0?????10: begin grants_o = 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    12'b1_110_0????100: begin grants_o = 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    12'b1_110_0???1000: begin grants_o = 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    12'b1_110_0??10000: begin grants_o = 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    12'b1_110_0?100000: begin grants_o = 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    12'b1_110_01000000: begin grants_o = 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    12'b1_111_???????1: begin grants_o = 8'b00000001; tag_o = (lg_inputs_p) ' (0); end
    12'b1_111_??????10: begin grants_o = 8'b00000010; tag_o = (lg_inputs_p) ' (1); end
    12'b1_111_?????100: begin grants_o = 8'b00000100; tag_o = (lg_inputs_p) ' (2); end
    12'b1_111_????1000: begin grants_o = 8'b00001000; tag_o = (lg_inputs_p) ' (3); end
    12'b1_111_???10000: begin grants_o = 8'b00010000; tag_o = (lg_inputs_p) ' (4); end
    12'b1_111_??100000: begin grants_o = 8'b00100000; tag_o = (lg_inputs_p) ' (5); end
    12'b1_111_?1000000: begin grants_o = 8'b01000000; tag_o = (lg_inputs_p) ' (6); end
    12'b1_111_10000000: begin grants_o = 8'b10000000; tag_o = (lg_inputs_p) ' (7); end
    default: begin grants_o = {8{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

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
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_8

if(inputs_p == 9)
begin: inputs_9
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    14'b0_????_?????????: begin grants_o = 9'b000000000; tag_o = (lg_inputs_p) ' (0); end // X
    14'b1_????_000000000: begin grants_o = 9'b000000000; tag_o = (lg_inputs_p) ' (0); end // X
    14'b1_0000_???????1?: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_0000_??????10?: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_0000_?????100?: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_0000_????1000?: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_0000_???10000?: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_0000_??100000?: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_0000_?1000000?: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_0000_10000000?: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1_0000_000000001: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_0001_??????1??: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_0001_?????10??: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_0001_????100??: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_0001_???1000??: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_0001_??10000??: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_0001_?100000??: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_0001_1000000??: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1_0001_0000000?1: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_0001_000000010: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_0010_?????1???: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_0010_????10???: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_0010_???100???: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_0010_??1000???: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_0010_?10000???: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_0010_100000???: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1_0010_000000??1: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_0010_000000?10: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_0010_000000100: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_0011_????1????: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_0011_???10????: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_0011_??100????: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_0011_?1000????: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_0011_10000????: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1_0011_00000???1: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_0011_00000??10: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_0011_00000?100: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_0011_000001000: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_0100_???1?????: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_0100_??10?????: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_0100_?100?????: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_0100_1000?????: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1_0100_0000????1: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_0100_0000???10: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_0100_0000??100: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_0100_0000?1000: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_0100_000010000: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_0101_??1??????: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_0101_?10??????: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_0101_100??????: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1_0101_000?????1: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_0101_000????10: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_0101_000???100: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_0101_000??1000: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_0101_000?10000: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_0101_000100000: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_0110_?1???????: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_0110_10???????: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1_0110_00??????1: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_0110_00?????10: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_0110_00????100: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_0110_00???1000: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_0110_00??10000: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_0110_00?100000: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_0110_001000000: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_0111_1????????: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    14'b1_0111_0???????1: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_0111_0??????10: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_0111_0?????100: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_0111_0????1000: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_0111_0???10000: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_0111_0??100000: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_0111_0?1000000: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_0111_010000000: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_1000_????????1: begin grants_o = 9'b000000001; tag_o = (lg_inputs_p) ' (0); end
    14'b1_1000_???????10: begin grants_o = 9'b000000010; tag_o = (lg_inputs_p) ' (1); end
    14'b1_1000_??????100: begin grants_o = 9'b000000100; tag_o = (lg_inputs_p) ' (2); end
    14'b1_1000_?????1000: begin grants_o = 9'b000001000; tag_o = (lg_inputs_p) ' (3); end
    14'b1_1000_????10000: begin grants_o = 9'b000010000; tag_o = (lg_inputs_p) ' (4); end
    14'b1_1000_???100000: begin grants_o = 9'b000100000; tag_o = (lg_inputs_p) ' (5); end
    14'b1_1000_??1000000: begin grants_o = 9'b001000000; tag_o = (lg_inputs_p) ' (6); end
    14'b1_1000_?10000000: begin grants_o = 9'b010000000; tag_o = (lg_inputs_p) ' (7); end
    14'b1_1000_100000000: begin grants_o = 9'b100000000; tag_o = (lg_inputs_p) ' (8); end
    default: begin grants_o = {9{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

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
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_9

if(inputs_p == 10)
begin: inputs_10
always_comb
begin
  unique casez({grants_en_i, last_r, reqs_i})
    15'b0_????_??????????: begin grants_o = 10'b0000000000; tag_o = (lg_inputs_p) ' (0); end // X
    15'b1_????_0000000000: begin grants_o = 10'b0000000000; tag_o = (lg_inputs_p) ' (0); end // X
    15'b1_0000_????????1?: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_0000_???????10?: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_0000_??????100?: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_0000_?????1000?: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_0000_????10000?: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_0000_???100000?: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_0000_??1000000?: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_0000_?10000000?: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_0000_100000000?: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_0000_0000000001: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_0001_???????1??: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_0001_??????10??: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_0001_?????100??: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_0001_????1000??: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_0001_???10000??: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_0001_??100000??: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_0001_?1000000??: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_0001_10000000??: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_0001_00000000?1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_0001_0000000010: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_0010_??????1???: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_0010_?????10???: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_0010_????100???: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_0010_???1000???: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_0010_??10000???: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_0010_?100000???: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_0010_1000000???: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_0010_0000000??1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_0010_0000000?10: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_0010_0000000100: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_0011_?????1????: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_0011_????10????: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_0011_???100????: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_0011_??1000????: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_0011_?10000????: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_0011_100000????: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_0011_000000???1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_0011_000000??10: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_0011_000000?100: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_0011_0000001000: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_0100_????1?????: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_0100_???10?????: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_0100_??100?????: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_0100_?1000?????: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_0100_10000?????: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_0100_00000????1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_0100_00000???10: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_0100_00000??100: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_0100_00000?1000: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_0100_0000010000: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_0101_???1??????: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_0101_??10??????: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_0101_?100??????: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_0101_1000??????: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_0101_0000?????1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_0101_0000????10: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_0101_0000???100: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_0101_0000??1000: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_0101_0000?10000: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_0101_0000100000: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_0110_??1???????: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_0110_?10???????: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_0110_100???????: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_0110_000??????1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_0110_000?????10: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_0110_000????100: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_0110_000???1000: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_0110_000??10000: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_0110_000?100000: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_0110_0001000000: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_0111_?1????????: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_0111_10????????: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_0111_00???????1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_0111_00??????10: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_0111_00?????100: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_0111_00????1000: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_0111_00???10000: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_0111_00??100000: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_0111_00?1000000: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_0111_0010000000: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_1000_1?????????: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    15'b1_1000_0????????1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_1000_0???????10: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_1000_0??????100: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_1000_0?????1000: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_1000_0????10000: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_1000_0???100000: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_1000_0??1000000: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_1000_0?10000000: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_1000_0100000000: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_1001_?????????1: begin grants_o = 10'b0000000001; tag_o = (lg_inputs_p) ' (0); end
    15'b1_1001_????????10: begin grants_o = 10'b0000000010; tag_o = (lg_inputs_p) ' (1); end
    15'b1_1001_???????100: begin grants_o = 10'b0000000100; tag_o = (lg_inputs_p) ' (2); end
    15'b1_1001_??????1000: begin grants_o = 10'b0000001000; tag_o = (lg_inputs_p) ' (3); end
    15'b1_1001_?????10000: begin grants_o = 10'b0000010000; tag_o = (lg_inputs_p) ' (4); end
    15'b1_1001_????100000: begin grants_o = 10'b0000100000; tag_o = (lg_inputs_p) ' (5); end
    15'b1_1001_???1000000: begin grants_o = 10'b0001000000; tag_o = (lg_inputs_p) ' (6); end
    15'b1_1001_??10000000: begin grants_o = 10'b0010000000; tag_o = (lg_inputs_p) ' (7); end
    15'b1_1001_?100000000: begin grants_o = 10'b0100000000; tag_o = (lg_inputs_p) ' (8); end
    15'b1_1001_1000000000: begin grants_o = 10'b1000000000; tag_o = (lg_inputs_p) ' (9); end
    default: begin grants_o = {10{1'bx}}; tag_o = (lg_inputs_p) ' (0); end // X 
  endcase
end 

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
    end //end of alwasy_comb

end //end of hold_on_sr_p 

end: inputs_10


assign v_o = (|reqs_i & grants_en_i);

if(inputs_p == 1)
  assign last_r = 1'b0;
else
  begin
    always_comb
      if( hold_on_sr_p ) begin: last_n_gen
        last_n = hold_on_sr ? last_r :
               ( yumi_i     ? tag_o  : last_r );  
      end else
        last_n = (yumi_i ? tag_o:last_r);

    always_ff @(posedge clk_i)
      last_r <= (reset_i) ? (lg_inputs_p)'(0):last_n;
  end

endmodule
