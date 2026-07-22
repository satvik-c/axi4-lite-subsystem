interface uart_if;

    // ========================================================
    // INTERFACE SIGNALS
    // ========================================================

    logic tx_out;
    logic rx_in;

    // ========================================================
    // MODPORTS
    // ========================================================

    modport rx_driver (
        output rx_in
    );

    modport tx_monitor (
        input tx_out
    );

endinterface
