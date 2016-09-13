`define WIDTH_P ?   // unused for now...

module test_bsg;

  // Enable VPD dump file
  //
  initial
    begin
      $vcdpluson;
      $vcdplusmemon;
    end

   logic TCK;

   localparam debug_lp = 0;

   localparam bsg_tag_els_lp = 4;
   genvar                    i;

   bsg_nonsynth_clock_gen #(100) cfg_clk_gen (TCK);

   localparam bsg_strobe_width_lp=8;

   logic [32-1:0]   cycle_count_r, cycle_count_last_r;

   logic                    bsg_strobe_reset_r, bsg_strobe_reset_n;
   logic [bsg_strobe_width_lp-1:0] bsg_strobe_init_val_r, bsg_strobe_init_val_n, bsg_strobe_init_val_r_r, bsg_strobe_in_r;

   logic                           bsg_strobe_r;

   bsg_strobe #(.width_p(bsg_strobe_width_lp))
    cnt_bsg_strobe (.clk_i(TCK)
             ,.reset_r_i   (bsg_strobe_reset_r   )
             ,.init_val_r_i(bsg_strobe_init_val_r)
             ,.strobe_r_o  (bsg_strobe_r         )
             );

   always_ff @(posedge TCK)
     begin
        bsg_strobe_reset_r      <= bsg_strobe_reset_n;
        bsg_strobe_init_val_r   <= bsg_strobe_init_val_n;
        bsg_strobe_init_val_r_r <= bsg_strobe_init_val_r;
     end

   always @(negedge TCK)
     begin
        if (bsg_strobe_r)
          begin
             if ((bsg_strobe_r !== 'X) && (cycle_count_last_r != -1))
	       begin
		  assert ((cycle_count_r - cycle_count_last_r) == (bsg_strobe_in_r+1))
                    else
                      begin
			 $error("## FAILURE: mismatch in strobe interval %d and input value %d"
				, cycle_count_r - cycle_count_last_r
				, bsg_strobe_in_r
				);
			 $finish();
                      end
		  $write(".");
	       end

             if (debug_lp)
               $display("## strobe %d cycles; val = %d"
                        , cycle_count_r - cycle_count_last_r
                        , bsg_strobe_in_r);

             bsg_strobe_in_r <= bsg_strobe_init_val_r_r;
          end
     end

   always_ff @(posedge TCK)
     cycle_count_r <= bsg_strobe_reset_n ? 0 : cycle_count_r + 1;

   always_ff @(posedge TCK)
     if (bsg_strobe_reset_r)
       cycle_count_last_r <= -1;
     else
       if (bsg_strobe_r)
         cycle_count_last_r <= cycle_count_r;

   initial
     begin
        $display("## sim start, testing 2^%-d strobe values",bsg_strobe_width_lp);

        @(negedge TCK);
        bsg_strobe_init_val_n = 0;
        bsg_strobe_reset_n    = 1;

        @(negedge TCK);
        bsg_strobe_reset_n    = 0;

        for (integer i = 0; i < (1<<bsg_strobe_width_lp); i=i+1)
          begin
             bsg_strobe_init_val_n=i;
             for (integer j = 0; j < ((i+1)<< 3); j=j+1)
               @(posedge TCK);
          end

        @(negedge TCK);
        $display("## DONE sim finished checking strobe values");

        $finish;
     end
endmodule
