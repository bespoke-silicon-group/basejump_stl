module config_net_tb;

  localparam len_width_lp      =  8;
  localparam id_width_lp       =  8;
  localparam frame_bit_size_lp =  1;
  localparam data_frame_len_lp =  8;

  localparam reset_len         = frame_bit_size_lp * 3 + id_width_lp + len_width_lp; //==>

  localparam id1_lp            =  5; 
  localparam default1_lp       = 10; 
  localparam data1_bits_lp     = 16;
  localparam data1_rx_len_lp   = (data1_bits_lp + (data1_bits_lp / data_frame_len_lp) + frame_bit_size_lp);

  localparam id2_lp            =  7; 
  localparam default2_lp       = 10; 
  localparam data2_bits_lp     = 21;
  localparam data2_rx_len_lp   = (data2_bits_lp + (data2_bits_lp / data_frame_len_lp) + frame_bit_size_lp);

  localparam id3_lp            = 127; 
  localparam default3_lp       =  10; 
  localparam data3_bits_lp     =   8;
  localparam data3_rx_len_lp   = (data3_bits_lp + (data3_bits_lp / data_frame_len_lp) + frame_bit_size_lp);

  typedef struct packed {
    logic [data1_rx_len_lp - 1 : 0]      rx;
    logic                                f1;
    logic [id_width_lp - 1 : 0]          id;
    logic [frame_bit_size_lp - 1 : 0]    f0;
    logic [len_width_lp - 1 : 0]        len;
    logic                             valid;
  } node1_packet_s;

  typedef struct packed {
    logic [data2_rx_len_lp - 1 : 0]      rx;
    logic                                f1;
    logic [id_width_lp - 1 : 0]          id;
    logic [frame_bit_size_lp - 1 : 0]    f0;
    logic [len_width_lp - 1 : 0]        len;
    logic                             valid;
  } node2_packet_s;

  typedef struct packed {
    logic [data3_rx_len_lp - 1 : 0]      rx;
    logic                                f1;
    logic [id_width_lp - 1 : 0]          id;
    logic [frame_bit_size_lp - 1 : 0]    f0;
    logic [len_width_lp - 1 : 0]        len;
    logic                             valid;
  } node3_packet_s;

  typedef struct packed {
    node3_packet_s node3;
    node2_packet_s node2;
    node1_packet_s node1;
    logic [reset_len - 1 : 0] reset;
  } config_packet_s;

  config_packet_s config_packet;

  logic                              clk_i;
  logic                              bit_i;
  logic                              bit1_o;
  logic                              bit2_o;
  logic                              bit3_o;
  logic [data1_bits_lp - 1 : 0]      data1_o;
  logic [data2_bits_lp - 1 : 0]      data2_o;
  logic [data3_bits_lp - 1 : 0]      data3_o;

  config_node      #(.id_p(id1_lp),
                     .data_bits_p(data1_bits_lp),
                     .default_p(default1_lp) )
    config_node1_dut(.clk_i(clk_i),
                     .bit_i(bit_i),
                     .data_o(data1_o),
                     .bit_o(bit1_o) );

  config_node      #(.id_p(id2_lp),
                     .data_bits_p(data2_bits_lp),
                     .default_p(default2_lp) )
    config_node2_dut(.clk_i(clk_i),
                     .bit_i(bit1_o),
                     .data_o(data2_o),
                     .bit_o(bit2_o) );

  config_node      #(.id_p(id3_lp),
                     .data_bits_p(data3_bits_lp),
                     .default_p(default3_lp) )
    config_node3_dut(.clk_i(clk_i),
                     .bit_i(bit2_o),
                     .data_o(data3_o),
                     .bit_o(bit3_o) );
  initial begin
    clk_i = 1;
    config_packet.reset       = 19'b111_11111111_11111111;

    config_packet.node3.rx    = 10'b0_0_11111111;
    config_packet.node3.f1    = 1'b0;
    config_packet.node3.id    = 8'd127;
    config_packet.node3.f0    = 1'b0;
    config_packet.node3.len   = 8'd29;
    config_packet.node3.valid = 1'b0;

    config_packet.node2.rx    = 24'b0_10001_0_01100011_0_10101000;
    config_packet.node2.f1    = 1'b0;
    config_packet.node2.id    = 8'd7;
    config_packet.node2.f0    = 1'b0;
    config_packet.node2.len   = 8'd43;
    config_packet.node2.valid = 1'b0;

    config_packet.node1.rx    = 19'b0_0_11111111_0_11101101;
    config_packet.node1.f1    = 1'b0;
    config_packet.node1.id    = 8'd5;
    config_packet.node1.f0    = 1'b0;
    config_packet.node1.len   = 8'd38;
    config_packet.node1.valid = 1'b0;

    bit_i = config_packet[0];
  end

  always #5 begin
    clk_i = ~clk_i; // flip clock every 5 ns, period 10 ns
  end

  always @ (posedge clk_i) begin
    config_packet = {1'b0, config_packet[$bits(config_packet_s) - 1 : 1]};
    bit_i = config_packet[0];
  end

  initial begin
    $dumpfile( "config_net_tb.vcd" );
    $dumpvars;
  end

  initial begin
    #3500 $finish; // simulation ends
  end

  initial begin
    $display("\t\t\t\ttime, \tclk_i, \tbit_i, \tdata1_o, \tdata2_o, \tdata3_o");
    $monitor("%d,   \t %b, \t  %b, \t %b,   \t  %b,  \t  %b",
             $time, clk_i, bit_i,  data1_o, data2_o, data3_o);
  end

endmodule
