parameter maxDivisionWidth_p  = 4;

// Input modes for BSG Mesosync IO
typedef enum logic {
    LA_STOP = 1'b0,
    NORMAL  = 1'b1
} input_mode_e;


// Output modes for BSG Mesosync IO
typedef enum logic [2:0] {
    STOP  = 3'b000,
    PAT   = 3'b001,
    SYNC1 = 3'b010,    
    SYNC2 = 3'b011,    
    LA    = 3'b100,
    NORM  = 3'b101
} output_mode_e;

// configuration for each bit for the input side
typedef struct packed
{   
    logic clk_edge_selector;
    logic [maxDivisionWidth_p-1:0] phase;
} bit_cfg_s;

// configuration bits from config-tag
typedef struct packed
{
    input_mode_e                 input_mode;
    logic                        LA_enque;
    output_mode_e                output_mode;
} mode_cfg_s;
