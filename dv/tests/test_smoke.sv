class test_smoke;

    env e;

    function new(virtual axi4_lite_if vif);
        e = new(vif);
    endfunction

    task run();
        axi_txn wr, rd;

        e.run();

        wr = new();
        wr.is_write = 1;
        wr.addr     = 12'h008;   // SPI_TXDATA
        wr.prot     = 3'b000;
        wr.wdata    = 32'h0000_0093;
        wr.wstrb    = 4'b0001;
        e.test2drv.put(wr);

        rd = new();
        rd.is_write = 0;
        rd.addr     = 12'h008;
        rd.prot     = 3'b000;
        e.test2drv.put(rd);

        wait (e.scb.count == 2);
    endtask

endclass
