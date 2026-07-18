interface spi_if;
    
    logic cs_n;
    logic sclk;
    logic mosi;
    logic miso;

    modport master (
        input miso,
        output cs_n,
        output sclk,
        output mosi
    );

    modport slave (
        input cs_n,
        input sclk,
        input mosi,
        output miso
    );    

endinterface
