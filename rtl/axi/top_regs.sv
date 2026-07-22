// ========================================================
// Instantiates the address decoders and peripheral register files, muxing their responses
// ========================================================

module top_regs
(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    clk,
    input  logic                    rst_n,

    // Write Interface
    input  logic                    wr_commit,
    input  logic [11:0]             wr_addr_long,
    input  logic [31:0]             wdata,
    input  logic [3:0]              wstrb,
    output logic                    slverr,
    output logic                    wr_dcerr,

    // Read Interface
    input  logic                    rd_commit,
    input  logic [11:0]             rd_addr_long,
    output logic [31:0]             rdata,
    output logic                    rd_dcerr,

    // SPI ports
    input  logic                    miso,
    output logic                    mosi,
    output logic                    sclk,
    output logic                    cs_n,

    // I2C ports
    output logic                    scl,
    inout  wire                     sda,

    // UART ports
    output logic                    tx_out,
    input  logic                    rx_in
);


    // ========================================================
    // WRITE PATH ADDRESS DECODE
    // ========================================================

    // Write Decode Selects
    logic wr_spi_sel;
    logic wr_i2c_sel;
    logic wr_uart_sel;
    logic wr_page_dcerr;

    // Write Commit Signals
    logic wr_spi_commit;
    logic wr_i2c_commit;
    logic wr_uart_commit;

    // Gate peripheral write commits with the decoded page select
    assign wr_spi_commit  = wr_commit & wr_spi_sel;
    assign wr_i2c_commit  = wr_commit & wr_i2c_sel;
    assign wr_uart_commit = wr_commit & wr_uart_sel;

    address_decoder wr_decoder (
        .addr(wr_addr_long),
        .spi_sel(wr_spi_sel),
        .i2c_sel(wr_i2c_sel),
        .uart_sel(wr_uart_sel),
        .page_dcerr(wr_page_dcerr)
    );


    // ========================================================
    // READ PATH ADDRESS DECODE
    // ========================================================

    // Read Decode Selects
    logic rd_spi_sel;
    logic rd_i2c_sel;
    logic rd_uart_sel;
    logic rd_page_dcerr;

    // Read Commit Signals
    logic rd_spi_commit;
    logic rd_i2c_commit;
    logic rd_uart_commit;

    // Gate peripheral read commits with the decoded page select
    assign rd_spi_commit  = rd_commit & rd_spi_sel;
    assign rd_i2c_commit  = rd_commit & rd_i2c_sel;
    assign rd_uart_commit = rd_commit & rd_uart_sel;

    address_decoder rd_decoder (
        .addr(rd_addr_long),
        .spi_sel(rd_spi_sel),
        .i2c_sel(rd_i2c_sel),
        .uart_sel(rd_uart_sel),
        .page_dcerr(rd_page_dcerr)
    );


    // ========================================================
    // SPI PERIPHERAL
    // ========================================================

    // SPI Register Interface
    logic [31:0] spi_rdata;
    logic        spi_slverr;
    logic        spi_wr_dcerr;
    logic        spi_rd_dcerr;

    // SPI Control Interface
    logic        spi_en;
    logic        spi_start;
    logic        spi_busy;
    logic        spi_valid;
    logic [7:0]  spi_txdata;
    logic [7:0]  spi_rxdata;
    logic        spi_cpol;
    logic        spi_cpha;
    logic [15:0] spi_clkdiv;

    spi_regs u_spi_regs (
        .clk(clk),
        .rst_n(rst_n),
        .wr_commit(wr_spi_commit),
        .wr_addr(wr_addr_long[7:2]),
        .wdata(wdata),
        .wstrb(wstrb),
        .slverr(spi_slverr),
        .wr_dcerr(spi_wr_dcerr),
        .rd_commit(rd_spi_commit),
        .rd_addr(rd_addr_long[7:2]),
        .rdata(spi_rdata),
        .rd_dcerr(spi_rd_dcerr),
        .spi_en(spi_en),
        .spi_start(spi_start),
        .spi_busy(spi_busy),
        .spi_valid(spi_valid),
        .spi_txdata(spi_txdata),
        .spi_rxdata(spi_rxdata),
        .spi_cpol(spi_cpol),
        .spi_cpha(spi_cpha),
        .spi_clkdiv(spi_clkdiv)
    );

    spi_master #(
        .DATA_WIDTH(8),
        .CS_SETUP_CYCLES(0),
        .CS_HOLD_CYCLES(0)
    ) u_spi_master (
        .clk(clk),
        .rst_n(rst_n),
        .cpol(spi_cpol),
        .cpha(spi_cpha),
        .clk_div(spi_clkdiv),
        .en(spi_en),
        .start(spi_start),
        .tx_data(spi_txdata),
        .rx_data(spi_rxdata),
        .rx_valid(spi_valid),
        .busy(spi_busy),
        .miso(miso),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n)
    );


    // ========================================================
    // I2C PERIPHERAL
    // ========================================================

    // I2C Register Interface
    logic [31:0] i2c_rdata;
    logic        i2c_slverr;
    logic        i2c_wr_dcerr;
    logic        i2c_rd_dcerr;

    // I2C Control Interface
    logic        i2c_en;
    logic        i2c_start;
    logic        i2c_rw_n;
    logic        i2c_busy;
    logic        i2c_rxvalid;
    logic        i2c_nack;
    logic        i2c_valid;
    logic [6:0]  i2c_addr;
    logic [7:0]  i2c_txdata;
    logic [7:0]  i2c_rxdata;
    logic [15:0] i2c_clkdiv;

    i2c_regs u_i2c_regs (
        .clk(clk),
        .rst_n(rst_n),
        .wr_commit(wr_i2c_commit),
        .wr_addr(wr_addr_long[7:2]),
        .wdata(wdata),
        .wstrb(wstrb),
        .slverr(i2c_slverr),
        .wr_dcerr(i2c_wr_dcerr),
        .rd_commit(rd_i2c_commit),
        .rd_addr(rd_addr_long[7:2]),
        .rdata(i2c_rdata),
        .rd_dcerr(i2c_rd_dcerr),
        .i2c_en(i2c_en),
        .i2c_start(i2c_start),
        .i2c_rw_n(i2c_rw_n),
        .i2c_busy(i2c_busy),
        .i2c_rxvalid(i2c_rxvalid),
        .i2c_nack(i2c_nack),
        .i2c_valid(i2c_valid),
        .i2c_addr(i2c_addr),
        .i2c_txdata(i2c_txdata),
        .i2c_rxdata(i2c_rxdata),
        .i2c_clkdiv(i2c_clkdiv)
    );

    i2c_master u_i2c_master (
        .clk(clk),
        .rst_n(rst_n),
        .clk_div(i2c_clkdiv),
        .en(i2c_en),
        .start(i2c_start),
        .addr(i2c_addr),
        .rw_n(i2c_rw_n),
        .tx_data(i2c_txdata),
        .busy(i2c_busy),
        .valid(i2c_valid),
        .nack(i2c_nack),
        .rx_data(i2c_rxdata),
        .rx_valid(i2c_rxvalid),
        .scl(scl),
        .sda(sda)
    );


    // ========================================================
    // UART PERIPHERAL
    // ========================================================

    // UART Register Interface
    logic [31:0] uart_rdata;
    logic        uart_slverr;
    logic        uart_wr_dcerr;
    logic        uart_rd_dcerr;

    // UART Control Interface
    logic        uart_tx_en;
    logic        uart_rx_en;
    logic        uart_tx_ready;
    logic        uart_tx_empty;
    logic [7:0]  uart_tx_data;
    logic        uart_tx_push;
    logic [7:0]  uart_rx_data;
    logic        uart_rx_valid;
    logic        uart_rx_perr;
    logic [15:0] uart_baud_div;
    logic        uart_parity_en;
    logic        uart_parity_mode;
    logic        uart_stop_bits;

    uart_regs u_uart_regs (
        .clk(clk),
        .rst_n(rst_n),
        .wr_commit(wr_uart_commit),
        .wr_addr(wr_addr_long[7:2]),
        .wdata(wdata),
        .wstrb(wstrb),
        .slverr(uart_slverr),
        .wr_dcerr(uart_wr_dcerr),
        .rd_commit(rd_uart_commit),
        .rd_addr(rd_addr_long[7:2]),
        .rdata(uart_rdata),
        .rd_dcerr(uart_rd_dcerr),
        .uart_tx_en(uart_tx_en),
        .uart_rx_en(uart_rx_en),
        .uart_tx_ready(uart_tx_ready),
        .uart_tx_empty(uart_tx_empty),
        .uart_tx_data(uart_tx_data),
        .uart_tx_push(uart_tx_push),
        .uart_rx_data(uart_rx_data),
        .uart_rx_valid(uart_rx_valid),
        .uart_rx_perr(uart_rx_perr),
        .uart_baud_div(uart_baud_div),
        .uart_parity_en(uart_parity_en),
        .uart_parity_mode(uart_parity_mode),
        .uart_stop_bits(uart_stop_bits)
    );

    uart_wrapper u_uart_wrapper (
        .clk(clk),
        .rst_n(rst_n),
        .tx_en(uart_tx_en),
        .rx_en(uart_rx_en),
        .tx_ready(uart_tx_ready),
        .tx_empty(uart_tx_empty),
        .tx_data(uart_tx_data),
        .tx_push(uart_tx_push),
        .rx_data(uart_rx_data),
        .rx_valid(uart_rx_valid),
        .rx_perr(uart_rx_perr),
        .baud_div(uart_baud_div),
        .parity_en(uart_parity_en),
        .parity_mode(uart_parity_mode),
        .stop_bits(uart_stop_bits),
        .tx_out(tx_out),
        .rx_in(rx_in)
    );


    // ========================================================
    // READ / WRITE RESPONSE MUX
    // ========================================================

    // Mux read data and error responses by decoded page select
    assign rdata = rd_spi_sel  ? spi_rdata  :
                   rd_i2c_sel  ? i2c_rdata  :
                   rd_uart_sel ? uart_rdata : 32'b0;

    assign slverr = wr_spi_sel  ? spi_slverr  :
                    wr_i2c_sel  ? i2c_slverr  :
                    wr_uart_sel ? uart_slverr : 1'b0;

    assign rd_dcerr = rd_spi_sel  ? spi_rd_dcerr  :
                      rd_i2c_sel  ? i2c_rd_dcerr  :
                      rd_uart_sel ? uart_rd_dcerr : rd_page_dcerr;

    assign wr_dcerr = wr_spi_sel  ? spi_wr_dcerr  :
                      wr_i2c_sel  ? i2c_wr_dcerr  :
                      wr_uart_sel ? uart_wr_dcerr : wr_page_dcerr;

endmodule
