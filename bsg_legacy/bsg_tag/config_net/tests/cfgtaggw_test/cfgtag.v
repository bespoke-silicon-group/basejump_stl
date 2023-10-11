`include "bsg_defines.v"

`include "config_defs.v"

module cfgtag #(parameter packet_ID_width_p = 4
               ,parameter RELAY_NUM = 5)
               (input clk   // destination side clock from pins
               ,input reset // destination side reset from pins
               ,input cfg_clk_i // from IO pads 
               ,input cfg_bit_i // from IO pads 
                     
               // To raw network
               ,input  credit_i
               ,output valid_o
               ,output logic [31:0] data_o
               );

logic [32+packet_ID_width_p-1:0] data;
config_s config_in;
config_s [RELAY_NUM-1:0] relay_output; 
assign config_in.cfg_clk = cfg_clk_i;
assign config_in.cfg_bit = cfg_bit_i;


relay_node relay_0 (.config_i(config_in),
                   .config_o(relay_output[0])
                   );

genvar inst;

generate
  for (inst = 1; inst < RELAY_NUM; inst = inst + 1) begin: gen_block 
    relay_node relay(.config_i(relay_output[inst-1]),
                     .config_o(relay_output[inst]));
  end
endgenerate  


config_node#(.id_p(1)     
            ,.data_bits_p(36)
            ,.default_p(36'd52) 
            ) cfg_node_1
            (.clk(clk)
            ,.reset(reset) 
            ,.config_i(relay_output[RELAY_NUM-1])

            ,.data_o(data)
            );

cfgtaggw     #(.packet_ID_width_p(packet_ID_width_p)) cfgtagGW
              (.clk(clk)
              ,.reset(reset)
              
              ,.cfgtag_data_i(data)
             
              // To raw network
              ,.credit_i(credit_i)
              ,.valid_o(valid_o)
              ,.data_o(data_o)
              );

endmodule
