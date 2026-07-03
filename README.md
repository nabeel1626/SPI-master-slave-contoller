# SPI Verilog Demo

This project demonstrates a complete SPI master/slave system implemented in Verilog and validated with Icarus Verilog.

Introduction
------------
This repository contains a parameterizable SPI master and a matching SPI slave designed to illustrate CPOL/CPHA timing, chip-select (`SS`) behavior, and full-duplex data transfers. It is intended for learning, simulation, and small FPGA/ASIC demos.

Files
-----
- `spi_master.v` — parameterized SPI master with `SS`, `CPOL`, and `CPHA` support.
- `spi_slave.v` — SPI slave model that samples `MOSI`, drives `MISO`, and honors `SS`.
- `spi_master_slave_modes_tb.v` — testbench exercising SPI modes 0–3 and verifying transfers.

Usage
-----
1. Compile with Icarus Verilog:

```powershell
iverilog -o sim_master_slave_modes.vvp spi_master.v spi_slave.v spi_master_slave_modes_tb.v
```

2. Run the simulation:

```powershell
vvp sim_master_slave_modes.vvp
```

3. Waveforms (if enabled) are written to `spi_master_slave_modes_tb.vcd` by the testbench.

Large files
-----------
If you need to store large waveform or simulation output files (`*.vcd`, `*.vvp`), use Git LFS or add them to `.gitignore`. This repo includes a `.gitattributes` file with Git LFS patterns; run `git lfs install` locally before pushing LFS-tracked files.

License
-------
Provided as-is for learning and demonstration. Add your preferred license if you intend to reuse or distribute this code.

Enjoy — feel free to open issues or request features.
