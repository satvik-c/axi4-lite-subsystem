class env;

    virtual axi4_lite_if vif_axi;
    virtual spi_if vif_spi;
    virtual i2c_if vif_i2c;
    virtual uart_if vif_uart;
    time clk_period;

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

    mailbox #(uart_rx_txn) test2rx;
    mailbox #(uart_rx_txn) rx2scb;
    mailbox #(uart_rx_txn) rx2cov;

    mailbox #(uart_tx_txn) tx2scb;
    mailbox #(uart_tx_txn) tx2cov;

    axi_driver drv_axi;
    axi_monitor mon_axi;
    spi_slave slv_spi;
    i2c_slave slv_i2c;
    uart_rx_driver drv_rx;
    uart_tx_monitor mon_tx;
    scoreboard scb;
    subsystem_cov cov;

    function new(virtual axi4_lite_if vif_axi, virtual spi_if vif_spi, virtual i2c_if vif_i2c, virtual uart_if vif_uart, time clk_period);
        this.vif_axi = vif_axi;
        this.vif_spi = vif_spi;
        this.vif_i2c = vif_i2c;
        this.vif_uart = vif_uart;
        this.clk_period = clk_period;

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

        test2rx = new();
        rx2scb = new();
        rx2cov = new();

        tx2scb = new();
        tx2cov = new();

        drv_axi = new(vif_axi, test2drv);
        mon_axi = new(vif_axi, mon2scb, mon2scb_rst, mon2cov);
        scb = new(mon2scb, mon2scb_rst, spi2scb, i2c2scb, rx2scb, tx2scb);
        slv_spi = new(vif_spi, scb.reg_model, test2spi, spi2scb, spi2cov);
        slv_i2c = new(vif_i2c, scb.reg_model, test2i2c, i2c2scb, i2c2cov);
        drv_rx = new(vif_uart, scb.reg_model, clk_period, test2rx, rx2scb, rx2cov);
        mon_tx = new(vif_uart, scb.reg_model, clk_period, tx2scb, tx2cov);
        cov = new(mon2cov, spi2cov, i2c2cov, rx2cov, tx2cov);
    endfunction

    task run();
        fork
            drv_axi.run();
            mon_axi.run();
            slv_spi.run();
            slv_i2c.run();
            drv_rx.run();
            mon_tx.run();
            scb.run();
            cov.run();
        join_none
    endtask

endclass
