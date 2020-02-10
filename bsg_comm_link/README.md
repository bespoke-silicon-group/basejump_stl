The bsg_comm_link is the first generation of high-speed communication logic for BaseJump STL chips, and used up
until our August 2019 tapeouts. 

bsg_link has replaced this functionality with a simpler but equally performant (and more FPGA friendly)
version and should be used for new designs. 

   - Unlike bsg_link supports unidirectional communication, allowing for asymmetrical communication between chips.
   - It removes the calibration mode which was never used.
   - It removes the FSB as an integrated module, instead you would use one of the NOCs.
   - It removes the assembler, which was a cool self-healing chip feature, but was not necessary given modern yields.
