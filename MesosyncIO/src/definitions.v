parameter maxDivisionWidth  = 4;
parameter bit_num           = 5;
parameter log_LA_fifo_depth = 9;
parameter log2_bit_num      = 3;

typedef enum logic [1:0] {
    IDLE = 2'b00,
    ONCE = 2'b01,    
    AUTO = 2'b11
} LA_enque_mode_e;

// configuration bits from config-tag
typedef struct packed
{
    logic [maxDivisionWidth-1:0] output_clk_divider;
    logic [maxDivisionWidth-1:0] input_clk_divider;
    logic [log2_bit_num-1:0]     input_bit_selector;
    logic                        input_mode;
    logic                        LA_enque;
    LA_enque_mode_e              LA_enque_mode;
    logic                        LA_input_selector;
    logic [1:0]                  LA_input_data;
    logic [bit_num-1:0]          clk_edge_selector;
    logic [bit_num-1:0] 
          [maxDivisionWidth-1:0] phase;
    logic [1:0]                  output_mode;
    logic [log2_bit_num-1:0]     output_bit_selector;
} configuration;
