parameter maxDivisionWidth  = 4;

// modes of Logic Analyzer Enqueue
typedef enum logic [1:0] {
    IDLE = 2'b00,
    ONCE = 2'b01,    
    AUTO = 2'b11
} LA_enque_mode_e;

// Output modes for BSG Mesosync IO
typedef enum logic [1:0] {
    STOP  = 2'b00,
    CALIB = 2'b01,    
    NORM  = 2'b11
} output_mode_e;

// values for clk dividers
typedef struct packed
{
    logic [maxDivisionWidth-1:0] output_clk_divider;
    logic [maxDivisionWidth-1:0] input_clk_divider;
} clk_divider_s;

// configuration for each bit for the input side
typedef struct packed
{   
    logic clk_edge_selector;
    logic [maxDivisionWidth-1:0] phase;
} bit_cfg_s;

// configuration bits from config-tag
typedef struct packed
{
    logic                        input_mode;
    logic                        LA_enque;
    LA_enque_mode_e              LA_enque_mode;
    logic                        LA_input_selector;
    logic [1:0]                  LA_input_data;
    output_mode_e                output_mode;
} mode_cfg_s;
