class env;

    virtual axi4_lite_if vif_axi;
    virtual spi_if vif_spi;
    virtual i2c_if vif_i2c;

    mailbox #(axi_txn) test2drv;
    mailbox #(axi_txn) mon2scb;
    mailbox mon2scb_rst;
    mailbox #(axi_txn) mon2cov;

    mailbox #(spi_txn) test2spi;
    mailbox #(spi_txn) spi2scb;
    mailbox #(spi_txn) spi2cov;

    mailbox #(i2c_txn) test2i2c;
    mailbox #(i2c_txn) i2c2scb;
    mailbox #(i2c_txn) i2c2cov;

    axi_driver drv_axi;
    axi_monitor mon_axi;
    spi_slave slv_spi;
    i2c_slave slv_i2c;
    scoreboard scb;
    subsystem_cov cov;

    function new(virtual axi4_lite_if vif_axi, virtual spi_if vif_spi, virtual i2c_if vif_i2c);
        this.vif_axi = vif_axi;
        this.vif_spi = vif_spi;
        this.vif_i2c = vif_i2c;
        
        test2drv = new();
        mon2scb = new();
        mon2scb_rst = new();
        mon2cov = new();

        test2spi = new();
        spi2scb = new();
        spi2cov = new();

        test2i2c = new();
        i2c2scb = new();
        i2c2cov = new();
        
        drv_axi = new(vif_axi, test2drv);
        mon_axi = new(vif_axi, mon2scb, mon2scb_rst, mon2cov);
        scb = new(mon2scb, mon2scb_rst, spi2scb, i2c2scb);
        slv_spi = new(vif_spi, scb.reg_model, test2spi, spi2scb, spi2cov);
        slv_i2c = new(vif_i2c, scb.reg_model, test2i2c, i2c2scb, i2c2cov);
        cov = new(mon2cov, spi2cov, i2c2cov);
    endfunction

    task run();
        fork
            drv_axi.run();
            mon_axi.run();
            slv_spi.run();
            slv_i2c.run();
            scb.run();
            cov.run();
        join_none
    endtask

endclass
