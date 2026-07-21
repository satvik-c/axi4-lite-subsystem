import regs_pkg::*;

class test_fifo_stress;

    env e;
    axi_txn txn;
    int counter;
    logic [31:0] wdata;

    localparam int BAUD_DIV = 32; // much higher baud rate for simulation purposes 

    function new(env e);
        this.e = e;
    endfunction

    task run();
        counter = e.scb.count;

        wdata = 32'h0;
        wdata[UART_CFG_BAUDDIV_MSB : UART_CFG_BAUDDIV_LSB] = BAUD_DIV[15:0];
        wdata[UART_CFG_PARITYEN] = 1;
        wdata[UART_CFG_PARITYMODE] = 0;
        wdata[UART_CFG_STOPBITS] = 0;
        txn = new(1, 4'h2, UART_CFG, wdata, 4'hF);
        e.test2drv.put(txn);
        counter++;

        wdata = 32'h0;
        wdata[UART_CTRL_TXEN] = 0;
        txn = new(1, 4'h2, UART_CTRL, wdata, 4'hF);
        e.test2drv.put(txn);
        counter++;

        repeat (64) begin
            wdata = 32'h0;
            wdata[7:0] = 8'h55;
            txn = new(1, 4'h2, UART_TXDATA, wdata, 4'hF);
            e.test2drv.put(txn);
            counter++;
        end

        txn = new(0, 4'h2, UART_STATUS);
        e.test2drv.put(txn);
        counter++;
        wait (txn.done.triggered);
        assert (txn.rdata[UART_STATUS_TXREADY] == 0);

        repeat (5) begin
            wdata = 32'h0;
            wdata[7:0] = 8'h55;
            txn = new(1, 4'h2, UART_TXDATA, wdata, 4'hF);
            e.test2drv.put(txn);
            counter++;
        end

        wdata = 32'h0;
        wdata[UART_CTRL_TXEN] = 1;
        txn = new(1, 4'h2, UART_CTRL, wdata, 4'hF);
        e.test2drv.put(txn);
        counter++;

        while (1) begin
            #(10 * BAUD_DIV * e.clk_period);  // ~one byte period (8 data + parity + stop)

            txn = new(0, 4'h2, UART_STATUS);
            e.test2drv.put(txn);
            counter++;
            wait (txn.done.triggered);
            if (txn.rdata[UART_STATUS_TXEMPTY]) break;
        end

        counter += 64; // 64 TX byte transactions from tx_monitor to scoreboard
        wait (e.scb.count == counter);

    endtask

endclass
