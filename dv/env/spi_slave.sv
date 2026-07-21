class spi_slave;

    virtual spi_if.slave vif;
    axi_reg_model reg_model;

    mailbox #(spi_txn) test2spi;
    mailbox #(spi_txn) spi2scb;
    mailbox #(spi_txn) spi2cov;

    function new (
        virtual spi_if.slave vif,
        axi_reg_model reg_model,
        mailbox #(spi_txn) test2spi,
        mailbox #(spi_txn) spi2scb,
        mailbox #(spi_txn) spi2cov
    );
        this.vif = vif;
        this.reg_model = reg_model;
        this.test2spi = test2spi;
        this.spi2scb = spi2scb;
        this.spi2cov = spi2cov;
    endfunction

    task run();
        forever begin
            spi_txn txn;
            logic drive_sclk_val;
            logic sample_sclk_val;

            test2spi.get(txn);
            
            @(negedge vif.cs_n);
            txn.cpol = reg_model.spi_cpol;
            txn.cpha = reg_model.spi_cpha;
            txn.mosi_expected = reg_model.spi_txdata;

            drive_sclk_val = txn.cpol ^ txn.cpha;
            sample_sclk_val = ~(txn.cpol ^ txn.cpha);

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

            spi2scb.put(txn);
            spi2cov.put(txn);
        end
    endtask;

endclass
