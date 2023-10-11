// This module takes data from a Lutag config-node, and sends
// it to the raw network. Input data has some extra bits for 
// getting synced at first not to send noise data. Moreover,
// for avoiding dropping data due to no handshake, it has a 
// FIFO of 2 elements inside, and valid-credit protocol in
// connection to raw network, with 4 credits. 

`include "bsg_defines.v"

module cfgtaggw #(parameter packet_ID_width_p = 4)
                     (input  clk
                     ,input  reset
                          
                     ,input [packet_ID_width_p+31:0] cfgtag_data_i
                     
                     // To raw network
                     ,input  credit_i
                     ,output valid_o
                     ,output logic [31:0] data_o
                     );

// Signals
// expected ID
logic [packet_ID_width_p-1:0] exp_ID_r,exp_ID_n;
logic [packet_ID_width_p-1:0] next_ID,input_ID;
logic valid;
logic [1:0] sync_r, sync_n; //0:reset, 1:synced, 2:unsynced 
logic [2:0]  fifo_count;

wire credit_avail = (fifo_count < 3'b100);

// Keeps count of how many elements are in the FIFO of receiver.
fifo_counter #(3) crdit_cnt (.up_count(valid_o),   // validIn
		  .down_count(credit_i),  // thanksIn
		  .num_entries(fifo_count),
		  .reset(reset),
		  .clk(clk));

assign data_o   = cfgtag_data_i[31:0];
assign valid_o  = valid & credit_avail;
assign input_ID = cfgtag_data_i[31+packet_ID_width_p:32];
assign next_ID  = exp_ID_r + 1;
assign valid    = (input_ID==next_ID) & (sync_r==2'b01); 
// If there is no fifo entry availabel expected ID would
// not change and no data is sent to FIFO. If the input changes
// it gets out of sync and hence no wrong data would be sent.
assign exp_ID_n       = valid_o ? next_ID : exp_ID_r;

// After reset it gets synced to exp_ID_r
// and does not send any packet to FIFO. For 
// next inputs it remains synced because of
// valid signal. If it gets out of sync it 
// cannot be synced unless the device is reset
always_comb
begin
  sync_n = sync_r;
  unique case (sync_r)
    2'b00:
      if (input_ID==exp_ID_r)
        sync_n = 2'b01;
    2'b01:
      if (!((input_ID==exp_ID_r)|valid))
        sync_n = 2'b10;
    default:begin
    end
  endcase
end 

always_ff @ (posedge clk)
  if (reset) begin
    exp_ID_r <= {packet_ID_width_p{1'b1}};
    sync_r   <= 2'b0;
  end
  else begin
    exp_ID_r <= exp_ID_n;
    sync_r   <= sync_n;
  end

endmodule
