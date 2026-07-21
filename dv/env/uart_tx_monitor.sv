class uart_tx_monitor;

    virtual uart_if.tx_monitor vif;
    time clk_period;

    mailbox #(uart_tx_txn) tx2scb;
    mailbox #(uart_tx_txn) tx2cov;

    function new(virtual uart_if.tx_monitor vif, time clk_period, mailbox #(uart_tx_txn) tx2scb, mailbox #(uart_tx_txn) tx2cov);
        this.vif = vif;
        this.clk_period = clk_period;
        this.tx2scb = tx2scb;
        this.tx2cov = tx2cov;
    endfunction

    task run();
        forever begin
            uart_tx_txn txn = new();
            logic [15:0] baud_div;

            @(negedge vif.tx_out);
            txn.parity_en = uart_dut_state::parity_en;
            txn.parity_mode = uart_dut_state::parity_mode;
            txn.stop_bits = uart_dut_state::stop_bits;
            baud_div = uart_dut_state::baud_div;

            #(baud_div * clk_period);
            #(baud_div * clk_period / 2);

            for (int i = 0; i < 8; i++) begin
                txn.data_sampled[i] = vif.tx_out;
                #(baud_div * clk_period);
            end

            if (txn.parity_en) begin
                txn.parity_sampled = vif.tx_out;
                #(baud_div * clk_period);
            end

            // don't need to sample stop bit(s)

            tx2scb.put(txn);
            tx2cov.put(txn);
        end
    endtask

endclass
