class env;

    virtual axi4_lite_if vif;

    mailbox #(axi_txn) test2drv;
    mailbox #(axi_txn) mon2scb;
    mailbox mon2scb_rst;
    mailbox #(axi_txn) mon2cov;

    axi_driver drv_axi;
    axi_monitor mon_axi;
    scoreboard scb;
    subsystem_cov cov;

    function new(virtual axi4_lite_if vif);
        this.vif = vif;
        
        test2drv = new();
        mon2scb = new();
        mon2scb_rst = new();
        mon2cov = new();
        
        drv_axi = new(vif, test2drv);
        mon_axi = new(vif, mon2scb, mon2scb_rst, mon2cov);
        scb = new(mon2scb, mon2scb_rst);
        cov = new(mon2cov);
    endfunction

    task run();
        fork
            drv_axi.run();
            mon_axi.run();
            scb.run();
            cov.run();
        join_none
    endtask

endclass
