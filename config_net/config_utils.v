`ifndef CONFIG_UTILS_V

`define CONFIG_UTILS_V

`include "config_defs.v"

// WARNING: All items here are created specially for the GreenDroid chip.
// When the config_node design is used in other projects, they must be revised.

// An element of this enum type will be used as the config_id_gen macro's
// `type` parapeter. Types should be defined so that each of them can be used
// to calculate a unique id by config_id_gen macro.
typedef enum {tGF28_RAM_PINS} eConfigTypes;

// An id_type is to distinguish config_nodes in the same (tile_x, tile_y) tile.
// This struct can be extended to provide more fields of identification.
// Do not forget to modify the config_id_gen function accordingly.
//
// Function $clog2(integer) returns the ceiling result (IEEE Std 1800-2005).
// $clog2(0) = 0
// $clog2(1) = 0
// $clog2(2) = 1
// $clog2(3) = 2
// $clog2(4) = 2
// $clog2(5) = 3
localparam tile_x_bits_lp  = (`TILE_MAX_X < 2) ? 1 : $clog2(`TILE_MAX_X);
localparam tile_y_bits_lp  = (`TILE_MAX_Y < 2) ? 1 : $clog2(`TILE_MAX_Y);
localparam id_type_bits_lp = id_width_lp - tile_x_bits_lp - tile_y_bits_lp;
typedef struct packed {
  logic [id_type_bits_lp - 1 : 0] id_type;
  logic [tile_y_bits_lp - 1 : 0]  tile_y;
  logic [tile_x_bits_lp - 1 : 0]  tile_x;
} config_id_s;

// Tasks and functions without the optional keyword `automatic` are static,
// with all declared items being statically allocated. These items shall be
// shared across all uses of the task and functions executing concurrently.
// Task and functions with the optional keyword `automatic` are dynamic tasks
// and functions. All items declared inside automatic tasks and functions are
// allocated dynamically for each invocation. Automatic task items and
// function items cannot be accessed by hierarchical references. To make tasks
// and functions synthesizable they must be declared as `automatic`, and
// cannot contain static variables.

// Function for calculating unique ID parameters for config_nodes
function automatic integer config_id_gen;
  input integer xpos, ypos;
  input eConfigTypes ctype;

  config_id_s  config_id;

  // Attention: SystemVerilog assertions only work in simulations but not during elaboration and synthesis.
  // ==> Need for a way to throw exception here during synthesis.
  assert (xpos  < `TILE_MAX_X)              else $error("Error: xpos (%0d) is not less than TILE_MAX_X (%0d)!",  xpos,  `TILE_MAX_X);
  assert (ypos  < `TILE_MAX_Y)              else $error("Error: ypos (%0d) is not less than TILE_MAX_Y (%0d)!",  ypos,  `TILE_MAX_Y);
  assert (ctype < $pow(2, id_type_bits_lp)) else $error("Error: ctype (%0d) does not fit in id_type_bits (%0d)!", ctype, id_type_bits_lp);

  config_id = '{ctype, ypos, xpos};

  config_id_gen = config_id; // config_id_gen is casted into 32-bit integer

endfunction

typedef struct packed {
  logic [2 : 0] ema;       // add extra delay to sram output
  logic [1 : 0] emaw;      // ema writes
  logic         emas;      // ema for reads
  logic         dftrambyp; // test mode (0 is normal operation)
  logic         ret1n;     // retention mode (1 is normal operation)
} gf28_ram_cfg_s;

`endif
