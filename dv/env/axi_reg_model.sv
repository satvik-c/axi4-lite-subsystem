import regs_pkg::*;

typedef enum logic [1:0] {
    RESP_OKAY   = 2'b00,
    RESP_SLVERR = 2'b10,
    RESP_DECERR = 2'b11
} axi_resp_e;

// Built from docs/MAS.md §6-8 only (address page decode, register map,
// side-effect rules) — deliberately not derived from the regs RTL, so it
// stays an independent check rather than a restatement of the DUT.
//
// Only bus-deterministic fields are tracked: write-strobe masking,
// read-only write protection, and decode errors. Core/queue-timed status
// (BUSY, the *setting* of RX_VALID/NACK/RX_OVERRUN/RX_PERR, and the
// content of any *_STATUS/*_RXDATA register) is out of scope per MAS §8 —
// those are checked by a separate white-box status-forwarding compare in
// the scoreboard, not predicted here. UART_TXDATA's FIFO push/drop
// behavior belongs to the separate UART Transmit Queue Model.
class axi_reg_model;

    // SPI page (MAS §7.1)
    logic        spi_en;
    logic [7:0]  spi_txdata;
    logic        spi_cpol, spi_cpha;
    logic [15:0] spi_clkdiv;

    // I2C page (MAS §7.2)
    logic        i2c_en;
    logic        i2c_rw_n;
    logic [6:0]  i2c_addr;
    logic [7:0]  i2c_txdata;
    logic [15:0] i2c_clkdiv;

    // UART page (MAS §7.3)
    logic        uart_tx_en, uart_rx_en;
    logic [15:0] uart_baud_div;
    logic        uart_parity_en, uart_parity_mode, uart_stop_bits;

    function new();
        reset();
    endfunction

    // MAS §2: reset reverts configuration registers to their defaults.
    // Called on every ARESETn assertion, not just at construction time.
    function void reset();
        spi_en = 0; spi_txdata = 0; spi_cpol = 0; spi_cpha = 0; spi_clkdiv = 0;
        i2c_en = 0; i2c_rw_n = 0; i2c_addr = 0; i2c_txdata = 0; i2c_clkdiv = 0;
        uart_tx_en = 0; uart_rx_en = 0; uart_baud_div = 0;
        uart_parity_en = 0; uart_parity_mode = 0; uart_stop_bits = 0;
    endfunction

    // ==================== WRITE ====================

    function axi_resp_e write(logic [11:0] addr, logic [31:0] wdata, logic [3:0] wstrb);
        case (addr[11:8])                        // MAS §6 page select
            4'h0:    return write_spi(addr[7:2], wdata, wstrb);
            4'h1:    return write_i2c(addr[7:2], wdata, wstrb);
            4'h2:    return write_uart(addr[7:2], wdata, wstrb);
            default: return RESP_DECERR;          // MAS §6 "Others: Reserved"
        endcase
    endfunction

    local function axi_resp_e write_spi(logic [5:0] off, logic [31:0] wdata, logic [3:0] wstrb);
        case (off)
            SPI_CTRL: begin
                if (wstrb[0]) spi_en = wdata[SPI_CTRL_EN];
                // START (bit 1) self-clears (MAS §7.1/§8) — no persistent state.
                return RESP_OKAY;
            end
            SPI_TXDATA: begin
                if (wstrb[0]) spi_txdata = wdata[7:0];
                return RESP_OKAY;
            end
            SPI_CFG: begin
                if (wstrb[0]) begin
                    spi_cpol = wdata[SPI_CFG_CPOL];
                    spi_cpha = wdata[SPI_CFG_CPHA];
                end
                if (wstrb[2]) spi_clkdiv[7:0]  = wdata[SPI_CFG_CLKDIV_LSB +: 8];
                if (wstrb[3]) spi_clkdiv[15:8] = wdata[SPI_CFG_CLKDIV_MSB -: 8];
                return RESP_OKAY;
            end
            SPI_STATUS, SPI_RXDATA:
                return RESP_SLVERR;               // MAS §8 write protection
            default:
                return RESP_DECERR;                // unmapped offset in page
        endcase
    endfunction

    local function axi_resp_e write_i2c(logic [5:0] off, logic [31:0] wdata, logic [3:0] wstrb);
        case (off)
            I2C_CTRL: begin
                if (wstrb[0]) begin
                    i2c_en   = wdata[I2C_CTRL_EN];
                    i2c_rw_n = wdata[I2C_CTRL_RW_N];
                end
                // START (bit 1) self-clears. NACK's clear-on-next-START (MAS
                // §7.2) isn't checked here since NACK itself isn't modeled.
                return RESP_OKAY;
            end
            I2C_ADDR: begin
                if (wstrb[0]) i2c_addr = wdata[6:0];
                return RESP_OKAY;
            end
            I2C_TXDATA: begin
                if (wstrb[0]) i2c_txdata = wdata[7:0];
                return RESP_OKAY;
            end
            I2C_CFG: begin
                if (wstrb[0]) i2c_clkdiv[7:0]  = wdata[7:0];
                if (wstrb[1]) i2c_clkdiv[15:8] = wdata[15:8];
                return RESP_OKAY;
            end
            I2C_STATUS, I2C_RXDATA:
                return RESP_SLVERR;
            default:
                return RESP_DECERR;
        endcase
    endfunction

    local function axi_resp_e write_uart(logic [5:0] off, logic [31:0] wdata, logic [3:0] wstrb);
        case (off)
            UART_CTRL: begin
                if (wstrb[0]) begin
                    uart_tx_en = wdata[UART_CTRL_TXEN];
                    uart_rx_en = wdata[UART_CTRL_RXEN];
                end
                return RESP_OKAY;
            end
            UART_TXDATA:
                // FIFO push/drop is modeled by the separate UART Transmit
                // Queue Model — MAS §8 guarantees the bus always sees OKAY.
                return RESP_OKAY;
            UART_CFG: begin
                if (wstrb[0]) uart_baud_div[7:0]  = wdata[7:0];
                if (wstrb[1]) uart_baud_div[15:8] = wdata[15:8];
                if (wstrb[2]) begin
                    uart_parity_en   = wdata[UART_CFG_PARITYEN];
                    uart_parity_mode = wdata[UART_CFG_PARITYMODE];
                    uart_stop_bits   = wdata[UART_CFG_STOPBITS];
                end
                return RESP_OKAY;
            end
            UART_STATUS, UART_RXDATA:
                return RESP_SLVERR;
            default:
                return RESP_DECERR;
        endcase
    endfunction

    // ==================== READ ====================

    function axi_resp_e read(logic [11:0] addr, output logic [31:0] rdata);
        case (addr[11:8])
            4'h0:    return read_spi(addr[7:2], rdata);
            4'h1:    return read_i2c(addr[7:2], rdata);
            4'h2:    return read_uart(addr[7:2], rdata);
            default: begin rdata = '0; return RESP_DECERR; end
        endcase
    endfunction

    local function axi_resp_e read_spi(logic [5:0] off, output logic [31:0] rdata);
        case (off)
            SPI_CTRL:   begin rdata = {30'b0, 1'b0, spi_en}; return RESP_OKAY; end
            SPI_TXDATA: begin rdata = {24'b0, spi_txdata};   return RESP_OKAY; end
            SPI_CFG:    begin rdata = {spi_clkdiv, 14'b0, spi_cpha, spi_cpol}; return RESP_OKAY; end
            SPI_STATUS, SPI_RXDATA: begin
                rdata = 'x;   // core-timed — scoreboard must skip this compare
                return RESP_OKAY;
            end
            default: begin rdata = '0; return RESP_DECERR; end
        endcase
    endfunction

    local function axi_resp_e read_i2c(logic [5:0] off, output logic [31:0] rdata);
        case (off)
            I2C_CTRL:   begin rdata = {29'b0, i2c_rw_n, 1'b0, i2c_en}; return RESP_OKAY; end
            I2C_ADDR:   begin rdata = {25'b0, i2c_addr};               return RESP_OKAY; end
            I2C_TXDATA: begin rdata = {24'b0, i2c_txdata};             return RESP_OKAY; end
            I2C_CFG:    begin rdata = {16'b0, i2c_clkdiv};             return RESP_OKAY; end
            I2C_STATUS, I2C_RXDATA: begin
                rdata = 'x;
                return RESP_OKAY;
            end
            default: begin rdata = '0; return RESP_DECERR; end
        endcase
    endfunction

    local function axi_resp_e read_uart(logic [5:0] off, output logic [31:0] rdata);
        case (off)
            UART_CTRL: begin
                rdata = {30'b0, uart_rx_en, uart_tx_en};
                return RESP_OKAY;
            end
            UART_CFG: begin
                rdata = {13'b0, uart_stop_bits, uart_parity_mode, uart_parity_en, uart_baud_div};
                return RESP_OKAY;
            end
            UART_STATUS, UART_TXDATA, UART_RXDATA: begin
                // TXDATA has no persistent readback value (FIFO push, MAS §4);
                // STATUS/RXDATA are core/queue-timed. All three skipped here.
                rdata = 'x;
                return RESP_OKAY;
            end
            default: begin rdata = '0; return RESP_DECERR; end
        endcase
    endfunction

endclass
