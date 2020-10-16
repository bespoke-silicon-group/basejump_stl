  module explicit_trace_rom #( parameter width_p = "inv"
                             , parameter addr_width_p = 6
                             )
    ( input        [addr_width_p-1:0] addr_i
    , output logic [width_p-1:0]      data_o
    );

    always_comb 
      case(addr_i)
        // send data format:      000 + 1-bit unlock_i + 4-bit requests
        // received data format:  000 + 1-bit lock_o   + 4-bit grants
        0: data_o = width_p ' (12'b0001__0000_1111); // Lock the highest channel
        1: data_o = width_p ' (12'b0010__0000_1000);

        2: data_o = width_p ' (12'b0001__0000_0111); 
        3: data_o = width_p ' (12'b0010__0001_0000); 

        4: data_o = width_p ' (12'b0001__0000_1111);
        5: data_o = width_p ' (12'b0010__0001_1000); 

        6: data_o = width_p ' (12'b0001__0001_1111); // Unclock the highest channel with grant
        7: data_o = width_p ' (12'b0010__0001_1000);

        8: data_o = width_p ' (12'b0001__0000_0111); //Lock the 2nd highest channel
        9: data_o = width_p ' (12'b0010__0000_0100);

        10: data_o = width_p ' (12'b0001__0000_0011); 
        11: data_o = width_p ' (12'b0010__0001_0000); // Locked, recv nothing

        12: data_o = width_p ' (12'b0001__0000_1011);
        13: data_o = width_p ' (12'b0010__0001_0000); // Locked, recv nothing

        14: data_o = width_p ' (12'b0001__0000_0111); 
        15: data_o = width_p ' (12'b0010__0001_0100);

        16: data_o = width_p ' (12'b0001__0001_0011);  // Unlock 
        17: data_o = width_p ' (12'b0010__0001_0000);

        18: data_o = width_p ' (12'b0001__0000_0011); // Lock the 3rd highest channel
        19: data_o = width_p ' (12'b0010__0000_0010); 

        20: data_o = width_p ' (12'b0001__0000_0001);
        21: data_o = width_p ' (12'b0010__0001_0000); // Locked, recv nothing

        22: data_o = width_p ' (12'b0001__0000_1001); 
        23: data_o = width_p ' (12'b0010__0001_0000); // Locked, recv nothing

        24: data_o = width_p ' (12'b0001__0000_0101); 
        25: data_o = width_p ' (12'b0010__0001_0000); // Locked, recv nothing

        26: data_o = width_p ' (12'b0001__0000_0011); 
        27: data_o = width_p ' (12'b0010__0001_0010); 

        28: data_o = width_p ' (12'b0001__0001_0011);
        29: data_o = width_p ' (12'b0010__0001_0010); // Unlock 

        30: data_o = width_p ' (12'b0001__0000_0001); // Lock the last channel
        31: data_o = width_p ' (12'b0010__0000_0001);

        32: data_o = width_p ' (12'b0001__0000_1000);
        33: data_o = width_p ' (12'b0010__0001_0000); // Locked, recv nothing

        34: data_o = width_p ' (12'b0001__0000_0100); 
        35: data_o = width_p ' (12'b0010__0001_0000); // Locked, recv nothing

        36: data_o = width_p ' (12'b0001__0000_0010); 
        37: data_o = width_p ' (12'b0010__0001_0000); // Locked, recv nothing

        38: data_o = width_p ' (12'b0001__0000_0001); 
        39: data_o = width_p ' (12'b0010__0001_0001); 

        40: data_o = width_p ' (12'b0001__0001_0000);
        41: data_o = width_p ' (12'b0010__0001_0000); // Unlock 

        42: data_o = width_p ' (12'b0100__0000_0000); //Finish simulation

        default: data_o = 'X;
      endcase
  endmodule