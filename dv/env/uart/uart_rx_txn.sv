class uart_rx_txn;

    // Randomized payload and parity-error injection
    rand logic [7:0] data;
    rand logic       inject_perr;

    // Frame config the DUT is using, captured at drive time
    logic parity_en;
    logic parity_mode;
    logic stop_bits;

    // Bias data toward corner patterns
    constraint data_range {
        data dist {
            8'h00 := 20,
            8'hFF := 20,
            8'h55 := 20,
            8'hAA := 20,
            [8'h01 : 8'hFE] :/ 20
        };
    }

endclass
