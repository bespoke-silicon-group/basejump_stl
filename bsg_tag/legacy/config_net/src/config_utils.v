`include "bsg_defines.v"

`ifndef CONFIG_UTILS_V

`define CONFIG_UTILS_V

`include "config_defs.v"

// WARNING: All items here are created specially for the GreenDroid chip.
// When the config_node design is used in other projects, they must be revised.

// An element of this enum type will be used as the config_id_gen function's
// `idtype` parapeter. Types should be defined so that each of them can be used
// to calculate a unique id by config_id_gen macro.
typedef enum {tCFG_DMEM, tCFG_IMEM, tCFG_TMEM, tCFG_STMEM, tCFG_MAIN_IMEM} eConfigIDTypes;

// An idtype is to distinguish config_nodes in the same (tile_x, tile_y) tile.
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
// There is no bits for `tile_x` in the config_node `id` field when
// TILE_MAX_X = 1, meaning all config_nodes are on the same X tile.
// Same rule applies to Y.
localparam tile_x_bits_lp = $clog2(`TILE_MAX_X);
localparam tile_y_bits_lp = $clog2(`TILE_MAX_Y);
localparam idtype_bits_lp = id_width_lp - tile_x_bits_lp - tile_y_bits_lp;

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
  // Data type 'enum of type int' is not supported in constant function.
  // However, 'enum of type int' can still be passed to this function as a parameter and enum will be converted into int.
  input integer idtype;

  // Assertions are not supported in constant functions; need for a way to throw exception here.
  //assert (xpos   < `TILE_MAX_X)             else $error("Error: xpos (%0d) is not less than TILE_MAX_X (%0d)!", xpos, `TILE_MAX_X);
  //assert (ypos   < `TILE_MAX_Y)             else $error("Error: ypos (%0d) is not less than TILE_MAX_Y (%0d)!", ypos, `TILE_MAX_Y);
  //assert (idtype < $pow(2, idtype_bits_lp)) else $error("Error: idtype (%0d) does not fit in idtype_bits (%0d)!", idtype, idtype_bits_lp);

  config_id_gen = (idtype << (tile_y_bits_lp + tile_x_bits_lp))
                | ( ypos  << (                 tile_x_bits_lp))
                | ( xpos );

endfunction

typedef struct packed {
  logic [2 : 0] ema;       // add extra delay to sram output
  logic [1 : 0] emaw;      // ema writes
  logic         emas;      // ema for reads
  logic         dftrambyp; // test mode (0 is normal operation)
  logic         ret1n;     // retention mode (1 is normal operation)
} gf28_ram_cfg_s;

`endif
