# BSG Hardened SRAM Wrapper Generator
The portability layer for BaseJump STL relies on 1:1 swapping of RTL modules for their hardened
equivalents. 

There are 3 components for implementing hardened SRAMs:
- The SRAM macro headers. These are header files which define the mapping of a generic bsg\_mem port list to a foundry-specific SRAM macro. We assume a naming convention of <node>\_d<depth>\_w<width>\_<tag>\_<type>, although this is not necessary as long as the scheme is consistent. BaseJump STL users who wish to use this portability layer must first create a set of SRAM macro headers corresponding to their specific memory compilers. For an example set of SRAM macro headers, see https://github.com/bespoke-silicon-group/basejump_stl/tree/master/hard/gf_14/bsg_mem.
- The SRAM wrapper, which is auto-generated with our script. This is a module which is pin identical to the synthesizable RTL implementation of the memory. For instance, bsg\_mem/bsg\_mem\_1rw\_sync.v contains only a synthesizable 1-port RAM HDL implementation found in bsg\_mem/bsg\_mem\_1rw\_sync\_synth.v. Our goal is to maintain this behavior for SRAMs which are too small or inconvenient to be hardened, while swapping out the definition for a hardened SRAM macro for specific implementations. This is accomplished by generating a wrapper which contains macros choosing which RAM widths and depths should be substituted. For instance,

            `bsg_mem_1rw_sync_macro(512, 64, 2) else

      will result in a 512x64 (mux 2) RAM taking the place of any instantiated 512x64 RAMs in the chip. The fallthrough default case is to synthesize the RAM.

- The actual hardened SRAM macro. This is generate by the user using the memory generator, ideally with a script. These should be named as per the scheme in the bsg\_mem\_\*.vh macro headers and their .lib / .v views should be accessible to the CAD tools as needed. We provide an example script, generate_memory_files.py, but this is likely not compatible with your memory generator and is just an example.

Because the SRAMs generated depends on each project's requirements, it is most convenient if this wrapper is generated as well. We provide a generic generator script in this directory which can be used to generate a set of these SRAM wrappers which is process agnostic (The process information is included based on the .vh macro headers). The input to this generator script (bsg\_mem\_generator.py) is a json file. We have a sample memgen.json in this directory. This same memgen.json can be used for feeding the SRAM generator itself, which is useful for keeping front-end and back-end in sync. An example line from the memgen.json is:

        {"ports": "1rw" , "width":  128, "depth": 1024, "mux": 2, "type": "1rf", mask: 1, "adbanks": 2, "awbanks": 2},

## Sample Usage
        python bsg_mem_generator.py <memgen.json> <ports> <mask>
	    python bsg_mem_generator.py memgen.json 1rw  0 > bsg_mem_1rw_sync.sv

