
all:
	python bsg_mem_generator.py memgen.json 1rw  0 > bsg_mem_1rw_sync.sv
	python bsg_mem_generator.py memgen.json 1rw  1 > bsg_mem_1rw_sync_mask_write_bit.sv
	python bsg_mem_generator.py memgen.json 1rw  8 > bsg_mem_1rw_sync_mask_write_byte.sv
	python bsg_mem_generator.py memgen.json 2rw  0 > bsg_mem_2rw_sync.sv
	python bsg_mem_generator.py memgen.json 2rw  1 > bsg_mem_2rw_sync_mask_write_bit.sv
	python bsg_mem_generator.py memgen.json 2rw  8 > bsg_mem_2rw_sync_mask_write_byte.sv
	python bsg_mem_generator.py memgen.json 1r1w 0 > bsg_mem_1r1w_sync.sv
	python bsg_mem_generator.py memgen.json 1r1w 1 > bsg_mem_1r1w_sync_mask_write_bit.sv
	python bsg_mem_generator.py memgen.json 1r1w 8 > bsg_mem_1r1w_sync_mask_write_byte.sv
	python bsg_mem_generator.py memgen.json 2r1w 0 > bsg_mem_2r1w_sync.sv
	python bsg_mem_generator.py memgen.json 3r1w 0 > bsg_mem_3r1w_sync.sv

clean:
	rm *.v

