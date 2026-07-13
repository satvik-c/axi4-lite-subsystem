module spi_regs
    import regs_pkg::*;
(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    clk,
    input  logic                    rst_n,

    // Write Interface
    input  logic                    wr_commit,
    input  logic [5:0]              wr_addr,
    input  logic [31:0]             wdata,
    input  logic [3:0]              wstrb,
    output logic                    slverr,
    output logic                    wr_dcerr,

    // Read Interface
    input  logic                    rd_commit,
    input  logic [5:0]              rd_addr,
    output logic [31:0]             rdata,
    output logic                    rd_dcerr,

    // SPI Control Interface
    output logic                    spi_en,
    output logic                    spi_start,
    input  logic                    spi_busy,
    input  logic                    spi_valid,
    output logic [7:0]              spi_txdata,
    input  logic [7:0]              spi_rxdata,
    output logic                    spi_cpol,
    output logic                    spi_cpha,
    output logic [15:0]             spi_clkdiv
);

    // ========================================================
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // Internal Status Registers
    logic       rx_valid_reg;
    logic [7:0] rx_data_reg;


    // ========================================================
    // DECODE LOGIC
    // ========================================================

    // Decode write and read address errors
    always_comb begin
        slverr   = (wr_addr == SPI_STATUS) || (wr_addr == SPI_RXDATA);
        wr_dcerr = !(wr_addr inside {SPI_CTRL, SPI_STATUS, SPI_TXDATA, SPI_RXDATA, SPI_CFG});
        rd_dcerr = !(rd_addr inside {SPI_CTRL, SPI_STATUS, SPI_TXDATA, SPI_RXDATA, SPI_CFG});
    end


    // ========================================================
    // REGISTER WRITE PATH
    // ========================================================

    // Register write operations
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            spi_en     <= 1'b0;
            spi_start  <= 1'b0;
            spi_txdata <= '0;
            spi_cpol   <= 1'b0;
            spi_cpha   <= 1'b0;
            spi_clkdiv <= '0;
        end else begin
            if (wr_commit && (wr_addr == SPI_CTRL) && wstrb[0] && wdata[SPI_CTRL_START]) begin
                spi_start <= 1'b1;
            end else begin
                spi_start <= 1'b0;
            end

            if (wr_commit) begin
                case (wr_addr)
                    SPI_CTRL: begin
                        if (wstrb[0]) begin
                            spi_en <= wdata[SPI_CTRL_EN];
                        end
                    end

                    SPI_TXDATA: begin
                        if (wstrb[0]) begin
                            spi_txdata <= wdata[7:0];
                        end
                    end

                    SPI_CFG: begin
                        if (wstrb[0]) begin
                            spi_cpol <= wdata[SPI_CFG_CPOL];
                            spi_cpha <= wdata[SPI_CFG_CPHA];
                        end
                        if (wstrb[2]) begin
                            spi_clkdiv[7:0]  <= wdata[SPI_CFG_CLKDIV_LSB +: 8];
                        end
                        if (wstrb[3]) begin
                            spi_clkdiv[15:8] <= wdata[SPI_CFG_CLKDIV_MSB -: 8];
                        end
                    end

                    default: ;
                endcase
            end
        end
    end


    // ========================================================
    // REGISTER READ PATH
    // ========================================================

    // Register read operations
    always_comb begin
        case (rd_addr)
            SPI_CTRL:   rdata = {30'b0, 1'b0, spi_en};
            SPI_STATUS: rdata = {30'b0, rx_valid_reg, spi_busy};
            SPI_TXDATA: rdata = {24'b0, spi_txdata};
            SPI_RXDATA: rdata = {24'b0, rx_data_reg};
            SPI_CFG:    rdata = {spi_clkdiv, 14'b0, spi_cpha, spi_cpol};
            default:     rdata = 32'b0;
        endcase
    end


    // ========================================================
    // INTERNAL REGISTERS UPDATES
    // ========================================================

    // Hardware updates for status and receive registers
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            rx_valid_reg <= 1'b0;
            rx_data_reg  <= '0;
        end else begin
            if (spi_valid) begin
                rx_valid_reg <= 1'b1;
                rx_data_reg  <= spi_rxdata;
            end else if (rd_commit && (rd_addr == SPI_RXDATA)) begin
                rx_valid_reg <= 1'b0;
            end
        end
    end

endmodule
