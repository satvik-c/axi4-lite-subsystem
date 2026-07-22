interface i2c_if(input logic rst_n);

    // ========================================================
    // INTERFACE SIGNALS
    // ========================================================

    logic scl;
    wire  sda;
    logic sda_oe = 1'b0;

    assign sda = sda_oe ? 1'b0 : 1'bz;

    // ========================================================
    // MODPORTS
    // ========================================================

    modport master (
        output scl,
        inout  sda,
        output sda_oe
    );

    modport slave (
        input  rst_n,
        input  scl,
        inout  sda,
        output sda_oe
    );

endinterface
