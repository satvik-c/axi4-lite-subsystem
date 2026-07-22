// ========================================================
// Reference model of the UART TX FIFO's contents, mirrored from tapped DUT activity
// ========================================================

class uart_fifo_model;


    // ========================================================
    // STATE
    // ========================================================

    // Mirror of the DUT FIFO, plus bytes popped but not yet seen on the wire
    static logic [7:0] fifo [$];
    static logic [7:0] unconfirmed [$];

    static mailbox #(uart_fifo_txn) fifo2cov = new();


    // ========================================================
    // MODEL EVENTS
    // ========================================================

    // Record an accepted write
    static task push(logic [7:0] wdata, logic rd_en);
        uart_fifo_txn txn = new();

        fifo.push_back(wdata);

        txn.event_t = PUSH;
        txn.concurrent = rd_en;
        txn.data = wdata;
        txn.occupancy = fifo.size();
        fifo2cov.put(txn);
    endtask

    // Record an accepted read; the byte awaits scoreboard confirmation
    static task pop(logic wr_en);
        uart_fifo_txn txn = new();

        logic [7:0] pop_data = fifo.pop_front();
        unconfirmed.push_back(pop_data);

        txn.event_t = POP;
        txn.concurrent = wr_en;
        txn.data = pop_data;
        txn.occupancy = fifo.size();
        fifo2cov.put(txn);
    endtask

    // Record a write dropped because the FIFO was full
    static task drop();
        uart_fifo_txn txn = new();
        txn.event_t = DROP;
        txn.data = 8'h00;
        txn.occupancy = fifo.size();
        fifo2cov.put(txn);
    endtask


    // ========================================================
    // QUERIES
    // ========================================================

    static function logic unconfirmed_pending();
        return (unconfirmed.size() != 0);
    endfunction

    static function logic [7:0] get_next_unconfirmed();
        return unconfirmed.pop_front();
    endfunction

endclass
