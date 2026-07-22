class spi_slave;

    // ========================================================
    // HANDLES
    // ========================================================

    virtual spi_if.slave vif;

    mailbox #(spi_txn) test2spi;
    mailbox #(spi_txn) spi2scb;
    mailbox #(spi_txn) spi2cov;

    // ========================================================
    // CONSTRUCTION
    // ========================================================

    function new(
        virtual spi_if.slave vif,
        mailbox #(spi_txn) test2spi,
        mailbox #(spi_txn) spi2scb,
        mailbox #(spi_txn) spi2cov
    );
        this.vif      = vif;
        this.test2spi = test2spi;
        this.spi2scb  = spi2scb;
        this.spi2cov  = spi2cov;
    endfunction

    // ========================================================
    // MAIN LOOP
    // ========================================================

    // Per transaction: shift MISO out and sample MOSI across the SCLK burst
    task run();
        forever begin
            spi_txn txn;
            logic drive_sclk_val;
            logic sample_sclk_val;

            wait (vif.rst_n === 1);
            test2spi.get(txn);

            @(negedge vif.cs_n);
            txn.cpol = spi_dut_state::cpol;
            txn.cpha = spi_dut_state::cpha;
            txn.mosi_expected = spi_dut_state::txdata;

            drive_sclk_val = txn.cpol ^ txn.cpha;
            sample_sclk_val = ~(txn.cpol ^ txn.cpha);

            fork
                // Drive MISO MSB-first, phase-aligned to CPHA
                begin
                    if (txn.cpha == 0) begin
                        vif.miso = txn.miso[7];
                    end
                    else begin
                        @(vif.sclk iff vif.sclk == drive_sclk_val);
                        vif.miso = txn.miso[7];
                    end

                    for (int i = 6; i >= 0; i--) begin
                        @(vif.sclk iff vif.sclk == drive_sclk_val);
                        vif.miso = txn.miso[i];
                    end

                    @(posedge vif.cs_n);
                    vif.miso = 1'bz;
                end
                // Sample MOSI MSB-first on the opposite edge
                begin
                    logic [7:0] sampled_mosi;
                    for (int i = 7; i >= 0; i--) begin
                        @(vif.sclk iff vif.sclk == sample_sclk_val);
                        sampled_mosi[i] = vif.mosi;
                    end
                    txn.mosi_sampled = sampled_mosi;
                end
            join

            spi2scb.put(txn);
            spi2cov.put(txn);
        end
    endtask

endclass
