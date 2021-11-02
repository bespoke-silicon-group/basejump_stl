# BSG Hardened SRAM Wrapper Generator
    The portability layer for BaseJump STL relies on 1:1 swapping of RTL modules for their hardened
equivalents. We support this for SRAMs by having a list of macros which instantiate the different SRAM options, dependent on macro headers in a process-specific header. Because the SRAMs generated depends on each project's requirements, it is most convenient if this wrapper is generated as well.

    The input to this generator script (bsg_mem_generator.py) is a json file. We have a sample memgen.json in this directory. This same memgen.json can be used for feeding the SRAM generator itself, which is useful for keeping front-end and back-end in sync. An example line from the memgen.json is:

        {"ports": "1rw" , "width":  128, "depth": 1024, "mux": 2, "type": "1rf", mask: 1, "adbanks": 2, "awbanks": 2},


## Sample Usage
        python bsg_mem_generator.py <memgen.json> <ports> <mask>
	    python bsg_mem_generator.py memgen.json 1rw  0 > bsg_mem_1rw_sync.v

