Project Description
This Verilog project demonstrates a complete SPI master/slave system with configurable timing and mode support. It is designed for learning and verifying SPI communication in hardware simulation using Icarus Verilog.

What it includes
- spi_master.v: a parameterized SPI master that supports chip-select (`SS`), `CPOL`, and `CPHA`.
- spi_slave.v: a matching SPI slave that responds on `MISO`, samples `MOSI`, and honors `SS`.
- spi_master_slave_modes_tb.v: a testbench that exercises all SPI modes 0–3 and verifies full-duplex data transfer.

Uses
- learning SPI protocol timing and mode behavior
- verifying Verilog SPI master/slave interaction
- testing master and slave logic with a simulator
- creating a small FPGA/ASIC SPI demo project
