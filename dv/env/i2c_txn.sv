class i2c_txn;

    rand logic nack;
    rand logic [7:0] rxdata;

    logic [6:0] addr_expected;
    logic rw_n_expected;
    logic [7:0] txdata_expected;

    logic [6:0] addr_sampled;
    logic rw_n_sampled;
    logic [7:0] txdata_sampled;

endclass
