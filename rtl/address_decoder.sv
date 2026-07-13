module address_decoder
(
    input logic [11:0] addr,
    output logic spi_sel,
    output logic i2c_sel,
    output logic uart_sel,
    output logic dcerr
);

    always_comb begin
        spi_sel = 0;
        i2c_sel = 0;
        uart_sel = 0;
        dcerr = 0;

        case (addr[11:8])
            4'h0: spi_sel = 1;
            4'h1: i2c_sel = 1;
            4'h2: uart_sel = 1;
            default: dcerr = 1;
        endcase
    end

endmodule
