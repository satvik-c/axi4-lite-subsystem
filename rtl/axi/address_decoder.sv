// ========================================================
// Decodes the AXI address into a peripheral page select or a decode error
// ========================================================

module address_decoder
(
    // ========================================================
    // PORTS
    // ========================================================

    // Input Address
    input  logic [11:0]                addr,

    // Decode Selects
    output logic                       spi_sel,
    output logic                       i2c_sel,
    output logic                       uart_sel,
    output logic                       page_dcerr
);


    // ========================================================
    // ADDRESS DECODE LOGIC
    // ========================================================

    // Decode input address to select peripheral
    always_comb begin
        spi_sel    = 1'b0;
        i2c_sel    = 1'b0;
        uart_sel   = 1'b0;
        page_dcerr = 1'b0;

        case (addr[11:8])
            4'h0:    spi_sel    = 1'b1;
            4'h1:    i2c_sel    = 1'b1;
            4'h2:    uart_sel   = 1'b1;
            default: page_dcerr = 1'b1;
        endcase
    end

endmodule
