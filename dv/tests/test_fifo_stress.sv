// ========================================================
// Directed test that fills the UART TX FIFO to full and drains it empty
// ========================================================

class test_fifo_stress;

    import regs_pkg::*;

    env          e;
    axi_txn      txn;
    int          counter;
    logic [31:0] wdata;

    localparam int BAUD_DIV = 32; // high baud rate to keep simulation fast

    function new(env e);
        this.e = e;
    endfunction

    task run();
        counter = e.scb.count;

        // Configure UART framing with parity enabled
        wdata = 32'h0;
        wdata[UART_CFG_BAUDDIV_MSB : UART_CFG_BAUDDIV_LSB] = BAUD_DIV[15:0];
        wdata[UART_CFG_PARITYEN] = 1;
        wdata[UART_CFG_PARITYMODE] = 0;
        wdata[UART_CFG_STOPBITS] = 0;
        txn = new(1, 4'h2, UART_CFG, wdata, 4'hF);
        e.test2drv.put(txn);
        counter++;

        // TX disabled so pushed bytes queue without draining
        wdata = 32'h0;
        wdata[UART_CTRL_TXEN] = 0;
        txn = new(1, 4'h2, UART_CTRL, wdata, 4'hF);
        e.test2drv.put(txn);
        counter++;

        // Push a full FIFO depth of bytes
        repeat (64) begin
            wdata = 32'h0;
            wdata[7:0] = 8'h55;
            txn = new(1, 4'h2, UART_TXDATA, wdata, 4'hF);
            e.test2drv.put(txn);
            counter++;
        end

        // Full FIFO reads back as not-ready
        txn = new(0, 4'h2, UART_STATUS);
        e.test2drv.put(txn);
        counter++;
        wait (txn.done.triggered);
        assert (txn.rdata[UART_STATUS_TXREADY] == 0);

        // Extra pushes while full are dropped
        repeat (5) begin
            wdata = 32'h0;
            wdata[7:0] = 8'h55;
            txn = new(1, 4'h2, UART_TXDATA, wdata, 4'hF);
            e.test2drv.put(txn);
            counter++;
        end

        // Enable TX to start draining the queue
        wdata = 32'h0;
        wdata[UART_CTRL_TXEN] = 1;
        txn = new(1, 4'h2, UART_CTRL, wdata, 4'hF);
        e.test2drv.put(txn);
        counter++;

        // Poll until the queue empties
        while (1) begin
            #(10 * BAUD_DIV * e.clk_period);  // ~one byte period (8 data + parity + stop)

            txn = new(0, 4'h2, UART_STATUS);
            e.test2drv.put(txn);
            counter++;
            wait (txn.done.triggered);
            if (txn.rdata[UART_STATUS_TXEMPTY]) break;
        end

        counter += 64; // 64 TX bytes drain out on the wire
        wait (e.scb.count == counter);
    endtask

endclass
