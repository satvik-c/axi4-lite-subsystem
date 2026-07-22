// ========================================================
// Randomizable SPI transaction: driven MISO byte, sampled/expected MOSI
// ========================================================

class spi_txn;

    // Driven MISO byte
    rand logic [7:0] miso;

    // Captured/expected MOSI and the config the slave observes
    logic [7:0] mosi_sampled;
    logic [7:0] mosi_expected;
    logic       cpol;
    logic       cpha;

    // Bias MISO toward corner patterns
    constraint miso_range {
        miso dist {
            8'h00 := 20,
            8'hFF := 20,
            8'h55 := 20,
            8'hAA := 20,
            [8'h01 : 8'hFE] :/ 20
        };
    }

endclass
