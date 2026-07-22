class i2c_txn;

    // Randomized slave response: ACK/NACK and read data
    rand logic       nack;
    rand logic [7:0] rxdata;

    // Expected transaction fields (from DUT config)
    logic [6:0] addr_expected;
    logic       rw_n_expected;
    logic [7:0] txdata_expected;

    // Sampled transaction fields (observed on the bus)
    logic [6:0] addr_sampled;
    logic       rw_n_sampled;
    logic [7:0] txdata_sampled;

    // Bias RX data toward corner patterns
    constraint rxdata_range {
        rxdata dist {
            8'h00 := 20,
            8'hFF := 20,
            8'h55 := 20,
            8'hAA := 20,
            [8'h01 : 8'hFE] :/ 20
        };
    }

endclass
