module spi_regs_sva
    import regs_pkg::*;
(
    input logic       clk,
    input logic       rst_n,
    input logic       rd_commit,
    input logic [5:0] rd_addr,
    input logic       rx_valid_reg
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    // W11: reading RXDATA clears RX_VALID on the next cycle
    W11_spi_rx_valid: assert property ((rd_commit && rd_addr == SPI_RXDATA) |=> !rx_valid_reg);

endmodule

module i2c_regs_sva
    import regs_pkg::*;
(
    input logic       clk,
    input logic       rst_n,
    input logic       rd_commit,
    input logic [5:0] rd_addr,
    input logic       rx_valid_reg
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    // W11: reading RXDATA clears RX_VALID on the next cycle
    W11_i2c_rx_valid: assert property ((rd_commit && rd_addr == I2C_RXDATA) |=> !rx_valid_reg);

endmodule

module uart_regs_sva
    import regs_pkg::*;
(
    input logic       clk,
    input logic       rst_n,
    input logic       rd_commit,
    input logic [5:0] rd_addr,
    input logic       rx_valid_reg,
    input logic       rx_overrun_reg,
    input logic       rx_perr_reg
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    // W11: reading RXDATA clears each RX status flag on the next cycle
    property clear_on_read(signal);
        (rd_commit && rd_addr == UART_RXDATA) |=> !signal;
    endproperty

    W11_uart_rx_valid:   assert property (clear_on_read(rx_valid_reg));
    W11_uart_rx_overrun: assert property (clear_on_read(rx_overrun_reg));
    W11_uart_rx_perr:    assert property (clear_on_read(rx_perr_reg));

endmodule
