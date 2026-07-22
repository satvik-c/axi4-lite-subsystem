// ========================================================
// SPI pin bundle shared between the DUT and the slave BFM
// ========================================================

interface spi_if(input logic rst_n);


    // ========================================================
    // INTERFACE SIGNALS
    // ========================================================

    logic cs_n;
    logic sclk;
    logic mosi;
    logic miso;


    // ========================================================
    // MODPORTS
    // ========================================================

    modport master (
        input  miso,
        output cs_n,
        output sclk,
        output mosi
    );

    modport slave (
        input  rst_n,
        input  cs_n,
        input  sclk,
        input  mosi,
        output miso
    );

endinterface
