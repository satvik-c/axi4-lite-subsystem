module decoder_sva (
    input logic [11:0]  addr,
    input logic         spi_sel,
    input logic         i2c_sel,
    input logic         uart_sel,
    input logic         page_dcerr
);

    always_comb begin
        if (!$isunknown(addr)) begin
            W9: assert ($countones({spi_sel, i2c_sel, uart_sel, page_dcerr}) == 1);
            W10: assert (page_dcerr == !(addr[11:8] inside {4'h0, 4'h1, 4'h2}));
        end
    end

endmodule
