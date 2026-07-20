class uart_rx_txn;

    rand logic [7:0] data;
    rand logic inject_perr;

    logic parity_en;
    logic parity_mode;
    logic stop_bits;

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
