module axi4_lite_subsystem
(
    // ========================================================
    // PORTS
    // ========================================================

    // AXI4-Lite Interface
    axi4_lite_if.slave s_axi,

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
    // INTERNAL SIGNALS & REGISTERS
    // ========================================================

    // Write Path Signals
    logic        wr_commit;
    logic [11:0] wr_addr_long;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        slverr;
    logic        wr_dcerr;

    // Read Path Signals
    logic        rd_commit;
    logic [11:0] rd_addr_long;
    logic [31:0] rdata;
    logic        rd_dcerr;


    // ========================================================
    // WRITE HANDLER INSTANTIATION
    // ========================================================

    write_handler u_write_handler (
        .clk(s_axi.ACLK),
        .rst_n(s_axi.ARESETn),
        .AWADDR(s_axi.AWADDR),
        .AWPROT(s_axi.AWPROT),
        .AWREADY(s_axi.AWREADY),
        .AWVALID(s_axi.AWVALID),
        .WDATA(s_axi.WDATA),
        .WSTRB(s_axi.WSTRB),
        .WREADY(s_axi.WREADY),
        .WVALID(s_axi.WVALID),
        .BRESP(s_axi.BRESP),
        .BVALID(s_axi.BVALID),
        .BREADY(s_axi.BREADY),
        .wr_commit(wr_commit),
        .wr_addr_long(wr_addr_long),
        .wdata(wdata),
        .wstrb(wstrb),
        .slverr(slverr),
        .wr_dcerr(wr_dcerr)
    );


    // ========================================================
    // READ HANDLER INSTANTIATION
    // ========================================================

    read_handler u_read_handler (
        .clk(s_axi.ACLK),
        .rst_n(s_axi.ARESETn),
        .ARADDR(s_axi.ARADDR),
        .ARPROT(s_axi.ARPROT),
        .ARVALID(s_axi.ARVALID),
        .ARREADY(s_axi.ARREADY),
        .RDATA(s_axi.RDATA),
        .RRESP(s_axi.RRESP),
        .RVALID(s_axi.RVALID),
        .RREADY(s_axi.RREADY),
        .rd_commit(rd_commit),
        .rd_addr_long(rd_addr_long),
        .rdata(rdata),
        .rd_dcerr(rd_dcerr)
    );


    // ========================================================
    // REGISTER FILE INSTANTIATION
    // ========================================================

    top_regs u_top_regs (
        .clk(s_axi.ACLK),
        .rst_n(s_axi.ARESETn),
        .wr_commit(wr_commit),
        .wr_addr_long(wr_addr_long),
        .wdata(wdata),
        .wstrb(wstrb),
        .slverr(slverr),
        .wr_dcerr(wr_dcerr),
        .rd_commit(rd_commit),
        .rd_addr_long(rd_addr_long),
        .rdata(rdata),
        .rd_dcerr(rd_dcerr),
        .miso(miso),
        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),
        .scl(scl),
        .sda(sda),
        .tx_out(tx_out),
        .rx_in(rx_in)
    );

endmodule
