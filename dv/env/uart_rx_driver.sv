class uart_rx_driver;

    virtual uart_if.rx_driver vif;
    axi_reg_model reg_model;
    time clk_period;

    mailbox #(uart_rx_txn) test2rx;
    mailbox #(uart_rx_txn) rx2cov;

    function new(virtual uart_if.rx_driver vif, axi_reg_model reg_model, time clk_period, mailbox #(uart_rx_txn) test2rx, mailbox #(uart_rx_txn) rx2cov);
        this.vif = vif;
        this.reg_model = reg_model;
        this.clk_period = clk_period;
        this.test2rx = test2rx;
        this.rx2cov = rx2cov;
    endfunction

    task run();
        forever begin
            uart_rx_txn txn;
            logic [15:0] baud_div;

            vif.rx_in = 1;

            test2rx.get(txn);
            txn.parity_en = reg_model.uart_parity_en;
            txn.parity_mode = reg_model.uart_parity_mode;
            txn.stop_bits = reg_model.uart_stop_bits;
            baud_div = reg_model.uart_baud_div;

            vif.rx_in = 0;
            #(baud_div * clk_period);

            for (int i = 0; i < 8; i++) begin
                vif.rx_in = txn.data[i];
                #(baud_div * clk_period);
            end

            if (txn.parity_en) begin
                logic parity = (!txn.parity_mode) ? ^txn.data : ~^txn.data;
                vif.rx_in = (txn.inject_perr) ? ~parity : parity;
                #(baud_div * clk_period);
            end

            vif.rx_in = 1;
            #(baud_div * clk_period);
            if (txn.stop_bits) begin
                #(baud_div * clk_period);
            end
            
            rx2cov.put(txn);
        end
    endtask

endclass
