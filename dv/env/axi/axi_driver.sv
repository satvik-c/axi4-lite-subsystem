class axi_driver;

    // ========================================================
    // HANDLES
    // ========================================================

    virtual axi4_lite_if.tb_driver vif;
    mailbox #(axi_txn) test2drv;

    // ========================================================
    // CONSTRUCTION
    // ========================================================

    function new(virtual axi4_lite_if.tb_driver vif, mailbox #(axi_txn) test2drv);
        this.vif      = vif;
        this.test2drv = test2drv;
    endfunction

    // ========================================================
    // RESET
    // ========================================================

    // Drive all master-side outputs to their idle state
    function void reset();
        vif.drv.AWADDR  <= 0;
        vif.drv.AWPROT  <= 0;
        vif.drv.AWVALID <= 0;
        vif.drv.WDATA   <= 0;
        vif.drv.WSTRB   <= 0;
        vif.drv.WVALID  <= 0;
        vif.drv.BREADY  <= 0;
        vif.drv.ARADDR  <= 0;
        vif.drv.ARPROT  <= 0;
        vif.drv.ARVALID <= 0;
        vif.drv.RREADY  <= 0;
    endfunction

    // ========================================================
    // WRITE SEQUENCE
    // ========================================================

    // Drive AW and W channels in parallel, then accept the B response
    task drive_write(axi_txn txn);
        @(vif.drv);

        fork
            begin
                repeat (txn.awvalid_delay) @(vif.drv);
                vif.drv.AWADDR  <= txn.addr;
                vif.drv.AWPROT  <= txn.prot;
                vif.drv.AWVALID <= 1;

                do begin
                    @(vif.drv);
                end while (!vif.drv.AWREADY);
                vif.drv.AWVALID <= 0;
            end
            begin
                repeat (txn.wvalid_delay) @(vif.drv);
                vif.drv.WDATA  <= txn.wdata;
                vif.drv.WSTRB  <= txn.wstrb;
                vif.drv.WVALID <= 1;

                do begin
                    @(vif.drv);
                end while (!vif.drv.WREADY);
                vif.drv.WVALID <= 0;
            end
        join

        repeat (txn.bready_delay) @(vif.drv);
        vif.drv.BREADY <= 1;

        do begin
            @(vif.drv);
        end while (!vif.drv.BVALID);
        vif.drv.BREADY <= 0;
        txn.resp = vif.drv.BRESP;
        ->txn.done;
    endtask

    // ========================================================
    // READ SEQUENCE
    // ========================================================

    // Drive the AR channel, then accept the R response
    task drive_read(axi_txn txn);
        @(vif.drv);

        repeat (txn.arvalid_delay) @(vif.drv);
        vif.drv.ARADDR  <= txn.addr;
        vif.drv.ARPROT  <= txn.prot;
        vif.drv.ARVALID <= 1;

        do begin
            @(vif.drv);
        end while (!vif.drv.ARREADY);
        vif.drv.ARVALID <= 0;

        repeat (txn.rready_delay) @(vif.drv);
        vif.drv.RREADY <= 1;

        do begin
            @(vif.drv);
        end while (!vif.drv.RVALID);
        vif.drv.RREADY <= 0;
        txn.rdata = vif.drv.RDATA;
        txn.resp  = vif.drv.RRESP;
        ->txn.done;
    endtask

    // ========================================================
    // MAIN LOOP
    // ========================================================

    // Pull transactions and drive them; restart cleanly on reset
    task run();
        reset();

        fork
            forever begin
                wait (vif.ARESETn === 1);

                fork : tx_process
                    begin
                        axi_txn txn;
                        test2drv.get(txn);

                        if (txn.is_write) drive_write(txn);
                        else              drive_read(txn);

                        repeat (txn.gap_delay) @(vif.drv);
                    end
                join
            end

            forever begin
                @(negedge vif.ARESETn);

                disable tx_process;
                reset();
            end
        join
    endtask

endclass
