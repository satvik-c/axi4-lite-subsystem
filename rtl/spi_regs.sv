module spi_regs
    import regs_pkg::*;
(
    input logic clk,
    input logic rst_n,

    input logic wr_commit,
    input logic [5:0] wr_addr,
    input logic [31:0] wdata,
    input logic [3:0] wstrb,
    output logic slverr,
    output logic wr_dcerr,

    input logic rd_commit,
    input logic [5:0] rd_addr,
    output logic [31:0] rdata,
    output logic rd_dcerr,

    output logic spi_en,
    output logic spi_start,
    input logic spi_busy,
    input logic spi_valid,
    output logic [7:0] spi_txdata,
    input logic [7:0] spi_rxdata,
    output logic spi_cpol,
    output logic spi_cpha,
    output logic [15:0] spi_clkdiv
);

    logic rx_valid_reg;
    logic [7:0] rx_data_reg;

    always_comb begin
        slverr = (wr_addr == SPI_STATUS || wr_addr == SPI_RXDATA);
        wr_dcerr = !(wr_addr inside {SPI_CTRL, SPI_STATUS, SPI_TXDATA, SPI_RXDATA, SPI_CFG});
        rd_dcerr = !(rd_addr inside {SPI_CTRL, SPI_STATUS, SPI_TXDATA, SPI_RXDATA, SPI_CFG});
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            spi_en <= 0;
            spi_start <= 0;
            spi_txdata <= '0;
            spi_cpol <= 0;
            spi_cpha <= 0;
            spi_clkdiv <= '0;
        end
        else begin
            if (wr_commit && wr_addr == SPI_CTRL && wstrb[0] && wdata[SPI_CTRL_START])
                spi_start <= 1'b1;
            else
                spi_start <= 1'b0;

            if (wr_commit) begin
                case (wr_addr)
                    SPI_CTRL: if (wstrb[0]) begin
                        spi_en <= wdata[SPI_CTRL_EN];
                    end
                    SPI_TXDATA: if (wstrb[0]) begin
                        spi_txdata <= wdata[7:0];
                    end
                    SPI_CFG: begin
                        if (wstrb[0]) begin
                            spi_cpol <= wdata[SPI_CFG_CPOL];
                            spi_cpha <= wdata[SPI_CFG_CPHA];
                        end
                        if (wstrb[2]) spi_clkdiv[7:0]  <= wdata[SPI_CFG_CLKDIV_LSB +: 8];
                        if (wstrb[3]) spi_clkdiv[15:8] <= wdata[SPI_CFG_CLKDIV_MSB -: 8];
                    end
                    default: ;
                endcase
            end
        end
    end

    always_comb begin
        case (rd_addr)
            SPI_CTRL: rdata = {30'b0, 1'b0, spi_en};
            SPI_STATUS: rdata = {30'b0, rx_valid_reg, spi_busy};
            SPI_TXDATA: rdata = {24'b0, spi_txdata};
            SPI_RXDATA: rdata = {24'b0, rx_data_reg};
            SPI_CFG: rdata = {spi_clkdiv, 14'b0, spi_cpha, spi_cpol};
            default: rdata = 32'b0;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_valid_reg <= 0;
            rx_data_reg <= '0;
        end
        else begin
            if (spi_valid) begin
                rx_valid_reg <= 1'b1;
                rx_data_reg <= spi_rxdata;
            end
            else if (rd_commit && rd_addr == SPI_RXDATA) rx_valid_reg <= 1'b0;
        end
    end

endmodule
