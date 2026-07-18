class env;

    virtual axi4_lite_if vif_axi;
    virtual spi_if vif_spi;

    mailbox #(axi_txn) test2drv;
    mailbox #(axi_txn) mon2scb;
    mailbox mon2scb_rst;
    mailbox #(axi_txn) mon2cov;

    mailbox #(spi_txn) test2slv;
    mailbox #(spi_txn) slv2scb;
    mailbox #(spi_txn) slv2cov;

    axi_driver drv_axi;
    axi_monitor mon_axi;
    spi_slave slv_spi;
    scoreboard scb;
    subsystem_cov cov;

    function new(virtual axi4_lite_if vif_axi, virtual spi_if vif_spi);
        this.vif_axi = vif_axi;
        this.vif_spi = vif_spi;
        
        test2drv = new();
        mon2scb = new();
        mon2scb_rst = new();
        mon2cov = new();

        test2slv = new();
        slv2scb = new();
        slv2cov = new();
        
        drv_axi = new(vif_axi, test2drv);
        mon_axi = new(vif_axi, mon2scb, mon2scb_rst, mon2cov);
        scb = new(mon2scb, mon2scb_rst, slv2scb);
        slv_spi = new(vif_spi, scb.reg_model, test2slv, slv2scb, slv2cov);
        cov = new(mon2cov, slv2cov);
    endfunction

    task run();
        fork
            drv_axi.run();
            mon_axi.run();
            slv_spi.run();
            scb.run();
            cov.run();
        join_none
    endtask

endclass
