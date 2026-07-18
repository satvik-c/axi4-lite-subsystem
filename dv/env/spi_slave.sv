class spi_slave;

    virtual spi_if.slave vif;
    axi_reg_model reg_model;

    mailbox #(spi_txn) test2slv;
    mailbox #(spi_txn) slv2scb;
    mailbox #(spi_txn) slv2cov;

    function new (
        virtual spi_if.slave vif,
        axi_reg_model reg_model,
        mailbox #(spi_txn) test2slv,
        mailbox #(spi_txn) slv2scb,
        mailbox #(spi_txn) slv2cov
    );
        this.vif = vif;
        this.reg_model = reg_model;
        this.test2slv = test2slv;
        this.slv2scb = slv2scb;
        this.slv2cov = slv2cov;
    endfunction

    task run();
        forever begin
            spi_txn txn;
            logic drive_sclk_val, sample_sclk_val;
            test2slv.get(txn);
            txn.cpol = reg_model.spi_cpol;
            txn.cpha = reg_model.spi_cpha;
            txn.mosi_expected = reg_model.spi_txdata;

            drive_sclk_val = txn.cpol ^ txn.cpha;
            sample_sclk_val = ~(txn.cpol ^ txn.cpha);

            @(negedge vif.cs_n);

            fork
                begin
                    if (txn.cpha == 0) vif.miso = txn.miso[7];
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
                begin
                    logic [7:0] sampled_mosi;
                    for (int i = 7; i >= 0; i--) begin
                        @(vif.sclk iff vif.sclk == sample_sclk_val);
                        sampled_mosi[i] = vif.mosi;
                    end
                    txn.mosi_sampled = sampled_mosi;
                end
            join

            slv2scb.put(txn);
            slv2cov.put(txn);
        end
    endtask;

endclass
