
all:
	python bsg_mem_1r1w_sync_generator.py memgen.json > bsg_mem_1r1w_sync.v
	python bsg_mem_1r1w_sync_mask_write_byte_generator.py memgen.json > bsg_mem_1r1w_sync_mask_write_byte.v
	python bsg_mem_1r1w_sync_mask_write_bit_generator.py memgen.json > bsg_mem_1r1w_sync_mask_write_bit.v
	python bsg_mem_1rw_sync_generator.py memgen.json > bsg_mem_1rw_sync.v
	python bsg_mem_1rw_sync_mask_write_byte_generator.py memgen.json > bsg_mem_1rw_sync_mask_write_byte.v
	python bsg_mem_1rw_sync_mask_write_bit_generator.py memgen.json > bsg_mem_1rw_sync_mask_write_bit.v
	python bsg_mem_2r1w_sync_generator.py memgen.json > bsg_mem_2r1w_sync.v
	python bsg_mem_3r1w_sync_generator.py memgen.json > bsg_mem_3r1w_sync.v

clean:
	rm *.v

