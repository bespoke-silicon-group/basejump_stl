`define PORTS_P        3
`define BANKS_P        3
`define BANK_SIZE_P    1024
`define DATA_WIDTH_P   32   // multiple of 8
`define RR_LO_HI_P     0

/*************************** TEST RATIONALE **********************************

  The instantiated multi-port banked memory is completely written by data in the
  format {<data_width/8>{<src port number>, <dest bank number>}. The written data
  is read and tallied. Then this module tries to fill the memory completely with 1s
  by setting mask_i to 111...1 to test the masking capability of UUT.

******************************************************************************/


module test_bsg
#(
  parameter data_width_p      = `DATA_WIDTH_P,
  parameter bank_size_p       = `BANK_SIZE_P,
  parameter ports_p           = `PORTS_P,
  parameter banks_p           = `BANKS_P,
  parameter rr_lo_hi_p        = `RR_LO_HI_P,
  parameter lg_banks_p        = `BSG_SAFE_CLOG2(banks_p),
  parameter bank_addr_width_p = `BSG_SAFE_CLOG2(bank_size_p),
  parameter addr_width_p      = ((banks_p == 1) ? 0 : lg_banks_p)
                                  + bank_addr_width_p,
  parameter cycle_time_p = 20,
  parameter reset_cycles_lo_p=1,
  parameter reset_cycles_hi_p=5
);

  // clock and reset generation
  wire clk;
  wire reset;

  bsg_nonsynth_clock_gen #(  .cycle_time_p(cycle_time_p)
                          )  clock_gen
                          (  .o(clk)
                          );

  bsg_nonsynth_reset_gen #(  .num_clocks_p     (1)
                           , .reset_cycles_lo_p(reset_cycles_lo_p)
                           , .reset_cycles_hi_p(reset_cycles_hi_p)
                          )  reset_gen
                          (  .clk_i        (clk) 
                           , .async_reset_o(reset)
                          );



  /* TEST SIGNALS */

  // input
  logic [ports_p-1:0][0:0]                    test_input_v, test_input_w;
  logic [ports_p-1:0][addr_width_p-1:0]      test_input_addr, test_input_addr_r;
  logic [ports_p-1:0][data_width_p-1:0]      test_input_data;
  logic [ports_p-1:0][(data_width_p>>3)-1:0] test_input_mask;
  // output
  logic [ports_p-1:0][0:0]                    test_output_yumi, test_output_v;
  logic [ports_p-1:0][data_width_p-1:0]      test_output_data;

  /*always_ff @(negedge clk)
    $strobe("v_i:%0p w_i:%0p addr_i:%b data_i:%b mask_i:%b\n"
             , test_input_v, test_input_w, test_input_addr
             , test_input_data, test_input_mask
             , "v_o:%0p yumi_o:%0p data_o:%b\n"
             , test_output_v, test_output_yumi, test_output_data
            );*/



  initial
  begin
    $display("\n");
    $display("===========================================================");
    $display("testing bsg_mem_banked_crossbar with ...");
    $display("DATA_WIDTH  : %0d", data_width_p);
    $display("ADDR_WIDTH  : %0d", addr_width_p);
    $display("BANKS       : %0d", banks_p);
    $display("PORTS       : %0d", ports_p);
    $display("RR_LO_HI    : %0d", rr_lo_hi_p);
    $display("BANK_SIZE   : %0d\n", bank_size_p);
  end



  /* TEST STIMULI */

  logic [ports_p-1:0] finish_main_r, finish_mask_r;

  logic [ports_p-1:0][lg_banks_p-1:0]        bank_num, bank_num_r;
  logic [ports_p-1:0][bank_addr_width_p-1:0] bank_addr;

  genvar i;

  for(i=0; i<ports_p; i=i+1)
  begin
    // address and control
    assign test_input_addr[i] = (banks_p == 1) ?
                                 bank_addr[i]
                                 : {bank_num[i], bank_addr[i]};

    always_ff @(posedge clk)
    begin
      if(reset)
        begin
          bank_num[i]        <= 0;
          bank_addr[i]       <= i;
          test_input_v[i]    <= 1'b1;
          test_input_w[i]    <= 1'b1;
          test_input_mask[i] <= {(data_width_p>>3){1'b1}}; // MBT
        end
      else
        begin
          if(test_output_yumi[i])
            begin
              if((bank_addr[i]+ports_p) < bank_size_p)
                bank_addr[i] <= bank_addr[i] + ports_p;
              else
                begin
                  bank_addr[i] <= i;
                  bank_num[i]  <= bank_num[i] + 1;
                end

              if((bank_num[i]==banks_p-1) & (bank_addr[i]+ports_p >= bank_size_p))
                begin
                  test_input_v[i] <= test_input_w[i];
                  test_input_w[i] <= 1'b0;
                  bank_num[i]     <= 0;
                  bank_addr[i]    <= i;
                end
            end

          if(~test_input_v[i] & ~finish_mask_r[i])
            begin
              test_input_v[i]    <= 1'b1;
              test_input_w[i]    <= 1'b1;
               test_input_mask[i] <= 0; // MBT

            end
        end
    end

    // data
    assign test_input_data[i] = (test_input_mask[i])?
                                {(data_width_p/8){4'(i), 4'(bank_num[i])}}
                                :{data_width_p{1'b1}};
   
  end



  /* UUT */

  bsg_mem_banked_crossbar #( .bank_size_p  (bank_size_p)
                            ,.num_ports_p  (ports_p)
                            ,.num_banks_p  (banks_p)
                            ,.data_width_p (data_width_p)
                            ,.rr_lo_hi_p   (rr_lo_hi_p)
                           ) UUT
                           ( .clk_i   (clk)
                            ,.reset_i (reset)
                            ,.reverse_pr_i(1'b0)
                            ,.v_i     (test_input_v)
                            ,.w_i     (test_input_w)
                            ,.addr_i  (test_input_addr)
                            ,.data_i  (test_input_data)
                            ,.mask_i  (test_input_mask)
                            ,.yumi_o  (test_output_yumi)
                            ,.v_o     (test_output_v)
                            ,.data_o  (test_output_data)
                           );



  /* Verification */

  always_ff @(posedge clk)
    if(|test_input_v)
      assert(|test_output_yumi)
        else $error("Error at time: %d, no transaction in a cycle", $time);

  for(i=0; i<ports_p; i=i+1)
  begin
    always_ff @(posedge clk)
    begin
      bank_num_r[i]        <= bank_num[i];
      test_input_addr_r[i] <= test_input_addr[i];

      if(test_output_v[i] & ~reset)
        assert(test_output_data[i] == {(data_width_p/8){4'(i), 4'(bank_num_r[i])}})
          else $error("Error while accessing %b from port: %0d, data was %b", test_input_addr_r[i], i, test_output_data[i]);
    end
  end



  /* FINISH */

  for(i=0; i<ports_p; i=i+1)
    always_ff @(posedge clk)
    begin
      if(reset)
        begin
          finish_main_r[i] <= 1'b0;
          finish_mask_r[i] <= 1'b0;
        end
      else
        begin
          if(~test_input_v[i])
            finish_main_r[i] <= 1'b1;

          if(finish_main_r[i] & (~test_input_v[i]))
            finish_mask_r[i] <= 1'b1;
        end
    end

  always_ff @(posedge clk)
    if((&finish_main_r) & (&finish_mask_r))
      begin
        $display("============================================================");
        $finish;
      end


endmodule
