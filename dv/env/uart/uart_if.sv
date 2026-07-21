interface uart_if;

    logic tx_out;
    logic rx_in;

    modport rx_driver (
        output rx_in
    );

    modport tx_monitor (
        input tx_out
    );

endinterface
