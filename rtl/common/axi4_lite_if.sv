// ========================================================
// AXI4-Lite bus signals, clocking blocks, and modports shared by the DUT and testbench
// ========================================================

interface axi4_lite_if
(
    // ========================================================
    // PORTS
    // ========================================================

    // System
    input  logic                    ACLK,
    input  logic                    ARESETn
);


    // ========================================================
    // INTERFACE SIGNALS
    // ========================================================

    // Write Address Channel
    logic [11:0] AWADDR;
    logic [2:0]  AWPROT;
    logic        AWREADY;
    logic        AWVALID;

    // Write Data Channel
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WREADY;
    logic        WVALID;

    // Write Response Channel
    logic [1:0] BRESP;
    logic       BVALID;
    logic       BREADY;

    // Read Address Channel
    logic [11:0] ARADDR;
    logic [2:0]  ARPROT;
    logic        ARREADY;
    logic        ARVALID;

    // Read Data Channel
    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RREADY;


    // ========================================================
    // CLOCKING BLOCKS
    // ========================================================

    // Driver Block
    clocking drv @(posedge ACLK);
        default input #1step output #1ns;

        output AWADDR, AWPROT, AWVALID;
        output WDATA, WSTRB, WVALID;
        output BREADY;
        output ARADDR, ARPROT, ARVALID;
        output RREADY;

        input  AWREADY;
        input  WREADY;
        input  BRESP, BVALID;
        input  ARREADY;
        input  RDATA, RRESP, RVALID;
    endclocking

    // Monitor Block
    clocking mon @(posedge ACLK);
        default input #1step;

        input AWADDR, AWPROT, AWVALID, AWREADY;
        input WDATA, WSTRB, WVALID, WREADY;
        input BRESP, BVALID, BREADY;
        input ARADDR, ARPROT, ARVALID, ARREADY;
        input RDATA, RRESP, RVALID, RREADY;
    endclocking


    // ========================================================
    // MODPORTS
    // ========================================================

    // Driver and Monitor Modports
    modport tb_driver  (clocking drv, input ARESETn);
    modport tb_monitor (clocking mon, input ARESETn);

    // Master Modport
    modport master (
        input  ACLK,
        input  ARESETn,
        output AWADDR,
        output AWPROT,
        output AWVALID,
        input  AWREADY,
        output WDATA,
        output WSTRB,
        output WVALID,
        input  WREADY,
        input  BRESP,
        input  BVALID,
        output BREADY,
        output ARADDR,
        output ARPROT,
        output ARVALID,
        input  ARREADY,
        input  RDATA,
        input  RRESP,
        input  RVALID,
        output RREADY
    );

    // Slave Modport
    modport slave (
        input  ACLK,
        input  ARESETn,
        input  AWADDR,
        input  AWPROT,
        input  AWVALID,
        output AWREADY,
        input  WDATA,
        input  WSTRB,
        input  WVALID,
        output WREADY,
        output BRESP,
        output BVALID,
        input  BREADY,
        input  ARADDR,
        input  ARPROT,
        input  ARVALID,
        output ARREADY,
        output RDATA,
        output RRESP,
        output RVALID,
        input  RREADY
    );

endinterface
