`define WIDTH_P ?   // unused for now...

module test_bsg;

   import bsg_tag_pkg::bsg_tag_s;

  // Enable VPD dump file
  //
  initial
    begin
      $vcdpluson;
      $vcdplusmemon;
    end

   logic TCK,TDI,TMS;

   localparam bsg_tag_els_lp = 4;

   wire [bsg_tag_els_lp-1:0] bsg_recv_clocks;
   genvar                    i;

   for (i = 0; i < bsg_tag_els_lp; i=i+1)
     begin: rof
        bsg_nonsynth_clock_gen #(i+2) recv_clock(bsg_recv_clocks[i]);
     end

   // Config net configuration clock. We run it continuously
   // but this is not necessary.

   bsg_nonsynth_clock_gen #(100) cfg_clk_gen (TCK);

   bsg_tag_s [bsg_tag_els_lp-1:0] clients_lo;
   logic [bsg_tag_els_lp-1:0] clients_reset;
   wire [bsg_tag_els_lp-1:0] clients_new;
   wire [bsg_tag_els_lp-1:0][bsg_tag_els_lp*8+5-1:0] clients_data;

   localparam payload_bits_lp = 7;
   localparam max_payload_lp = (1 << payload_bits_lp)-1;

   `declare_bsg_tag_header_s(bsg_tag_els_lp,payload_bits_lp)

   // one master tag to connect to the clients
   bsg_tag_master #(.els_p(bsg_tag_els_lp), .lg_width_p(payload_bits_lp)) btm
   (.clk_i      (TCK)
    ,.data_i    (TDI)
    ,.en_i      (TMS)
    ,.clients_r_o(clients_lo)
    );

   // stamp out a bunch of client tags
   for (i = 0; i < bsg_tag_els_lp; i=i+1)
     begin: rof2

        bsg_tag_client #(.width_p(5+i*8)
                         ,.default_p(i)
                         ) btc
            (.bsg_tag_i     (clients_lo      [i])
             ,.recv_clk_i   (bsg_recv_clocks [i])
             ,.recv_reset_i (clients_reset   [i])
             ,.recv_new_r_o (clients_new     [i])
             ,.recv_data_r_o(clients_data    [i][0+:5+i*8])
             );

        always @(clients_data[i])
          begin
             $display("## client %d data = %b new = %b",i,clients_data[i],clients_new[i]);
          end
     end

   bsg_tag_header_s send_me;

   wire [5+3*8-1:0] val = 29'b0_1111_1001_0110_0011_1100_1010_0101;

   initial
     begin
        $display("## sim start");

        send_me.nodeID         = 3;
        send_me.data_not_reset = 0;
        send_me.len            = max_payload_lp;

        @(negedge TCK);
        TDI    = 1'b0;
	TMS    = 1'b1;
	
        @(negedge TCK);

        clients_reset[0] = 1;

        // clear reset counter going
        @(negedge TCK);
        TDI = 1'b1;
        clients_reset[0] = 0;

        // start reset counter going
        @(negedge TCK);
        TDI = 1'b0;

        // trigger bsg_tag_master reset
        for (integer i = 0; i <  `bsg_tag_reset_len(bsg_tag_els_lp,payload_bits_lp); i++)
             @(posedge TCK);

        // packet bit
        @(negedge TCK);
        TDI = 1'b1;

        // transmit header
        for (integer i = 0; i < $bits(send_me); i=i+1)
          begin
             @(negedge TCK);
             TDI = send_me[i];
          end

        send_me.data_not_reset = 1;
        send_me.len = 29;

        // transmit reset payload
        for (integer i = 0; i < max_payload_lp; i=i+1)
          begin
             @(negedge TCK);
             TDI = 1'b1;
          end

        // packet bit
        @(negedge TCK);
        TDI = 1'b1;

        // transmit header
        for (integer i = 0; i < $bits(send_me); i=i+1)
          begin
             @(negedge TCK);
             TDI = send_me[i];
          end

        // transmit payload
        for (integer i = 0; i < 29; i=i+1)
          begin
             @(negedge TCK);
             TDI = val[i];
          end

        // packet bit
        @(negedge TCK);
        TDI = 1'b1;


        // transmit header
        for (integer i = 0; i < $bits(send_me); i=i+1)
          begin
             @(negedge TCK);
             TDI = send_me[i];
          end

        // transmit payload
        for (integer i = 0; i < 29; i=i+1)
          begin
             @(negedge TCK);
             TDI = val[i];
          end

        // packet bit
        @(negedge TCK);
        TDI = 1'b1;

        send_me.nodeID = 1;


        // transmit header
        for (integer i = 0; i < $bits(send_me); i=i+1)
          begin
             @(negedge TCK);
             TDI = send_me[i];
          end

        // transmit payload
        for (integer i = 0; i < 29; i=i+1)
          begin
             @(negedge TCK);
             TDI = val[i];
          end

        @(negedge TCK);
        TDI = 1'b0;

        @(negedge TCK);
        TDI = 1'b0;

        @(negedge TCK);
        TDI = 1'b0;


        @(negedge TCK);
        TDI = 1'b0;

        @(negedge TCK);
        TDI = 1'b0;

        $finish;
     end
endmodule
