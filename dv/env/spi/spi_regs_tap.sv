class spi_dut_state;
    static logic       cpol;
    static logic       cpha;
    static logic [7:0] txdata;
endclass

module spi_regs_tap
(
    input logic       spi_cpol,
    input logic       spi_cpha,
    input logic [7:0] spi_txdata
);

    always_comb begin
        spi_dut_state::cpol   = spi_cpol;
        spi_dut_state::cpha   = spi_cpha;
        spi_dut_state::txdata = spi_txdata;
    end

endmodule
