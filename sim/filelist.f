# Packages / interfaces
rtl/common/regs_pkg.sv
rtl/common/axi4_lite_if.sv

# Leaf primitives
rtl/axi/skid_buffer.sv
rtl/axi/address_decoder.sv

# Peripheral cores
rtl/spi/spi_master.sv
rtl/i2c/i2c_master.sv
rtl/uart/baud_gen.sv
rtl/uart/uart_fifo.sv
rtl/uart/uart_tx.sv
rtl/uart/uart_rx.sv
rtl/uart/uart_wrapper.sv

# Register files
rtl/spi/spi_regs.sv
rtl/i2c/i2c_regs.sv
rtl/uart/uart_regs.sv

# AXI layer
rtl/axi/read_handler.sv
rtl/axi/write_handler.sv
rtl/axi/top_regs.sv
rtl/axi4_lite_subsystem.sv

# SPI slave
dv/env/spi_if.sv
dv/env/spi_txn.sv

# DV components
dv/env/axi_txn.sv
dv/env/axi_reg_model.sv
dv/env/axi_driver.sv
dv/env/axi_monitor.sv
dv/env/scoreboard.sv

dv/env/spi_slave.sv

# DV coverage
dv/cov/subsystem_cov.sv

# DV env
dv/env/env.sv

# DV assertions
dv/sva/protocol_sva.sv
dv/sva/skid_buffer_sva.sv
dv/sva/uart_fifo_sva.sv
dv/sva/decoder_sva.sv
dv/sva/regs_sva.sv

# DV tests
dv/tests/test_smoke.sv
