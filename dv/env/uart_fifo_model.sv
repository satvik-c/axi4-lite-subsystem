class uart_fifo_model;

    static logic [7:0] fifo [$];
    static logic [7:0] unconfirmed [$];

    static mailbox #(uart_fifo_txn) fifo2cov = new();

    static task push(logic [7:0] wdata, logic rd_en);
        uart_fifo_txn txn = new();

        fifo.push_back(wdata);

        txn.event_t = PUSH;
        txn.concurrent = rd_en;
        txn.data = wdata;
        txn.occupancy = fifo.size();
        fifo2cov.put(txn);
    endtask

    static task pop(logic [7:0] rdata, logic wr_en);
        uart_fifo_txn txn = new();
        
        logic [7:0] pop_data = fifo.pop_front();
        assert (pop_data == rdata);
        unconfirmed.push_back(pop_data);

        txn.event_t = POP;
        txn.concurrent = wr_en;
        txn.data = pop_data;
        txn.occupancy = fifo.size();
        fifo2cov.put(txn);
    endtask

    static task drop();
        uart_fifo_txn txn = new();
        txn.event_t = DROP;
        txn.data = 8'h00;
        txn.occupancy = fifo.size();
        fifo2cov.put(txn);
    endtask

    static function logic unconfirmed_pending();
        return (unconfirmed.size() != 0);
    endfunction

    static function logic [7:0] get_next_unconfirmed();
        return unconfirmed.pop_front();
    endfunction

endclass
