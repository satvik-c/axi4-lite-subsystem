class test_arrival_order;

    env e;
    axi_txn txn;
    int counter;

    function new(env e);
        this.e = e;
    endfunction

    task run();
        counter = e.scb.count;

        txn = new(1, 4'h0, 6'h0, 32'hAAAA_AAAA, 4'b1111);
        e.test2drv.put(txn);
        counter++;

        txn = new(1, 4'h0, 6'h0, 32'hAAAA_AAAA, 4'b1111, .wvalid_delay(3));
        e.test2drv.put(txn);
        counter++;

        txn = new(1, 4'h0, 6'h0, 32'hAAAA_AAAA, 4'b1111, .awvalid_delay(3));
        e.test2drv.put(txn);
        counter++;

        wait (e.scb.count == counter);

    endtask

endclass
