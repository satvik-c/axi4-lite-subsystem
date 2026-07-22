// Directed: sweep the register map with every strobe pattern, plus decode boundaries
class test_register_access;

    env     e;
    axi_txn txn;
    int     counter;

    logic [3:0] wstrb_arr [8] = '{
        4'b1111,
        4'b0000,
        4'b0001,
        4'b0010,
        4'b0100,
        4'b1000,
        4'b0011,
        4'b1100
    };

    function new(env e);
        this.e = e;
    endfunction

    task run();
        counter = e.scb.count;

        // Every mapped page/offset: all write-strobe patterns, then a read
        for (logic [3:0] i = 0; i <= 4'h2; i++) begin
            for (logic [5:0] j = 0; j <= 6'h05; j++) begin
                if (j == 6'h05 && i != 4'h1) continue;

                for (int k = 0; k < 8; k++) begin
                    txn = new(1, i, j, 32'hAAAA_AAAA, wstrb_arr[k]);
                    e.test2drv.put(txn);
                    counter++;
                end

                txn = new(0, i, j);
                e.test2drv.put(txn);
                counter++;
            end
        end

        // Reserved pages 0x3-0xF: one write and one read each
        for (int i = 4'h3; i <= 4'hF; i++) begin
            txn = new(1, i[3:0], 6'h0, 32'hAAAA_AAAA);
            e.test2drv.put(txn);
            counter++;

            txn = new(0, i[3:0], 6'h0);
            e.test2drv.put(txn);
            counter++;
        end

        // Per page: first-unmapped offset and the top offset
        for (logic [3:0] i = 0; i <= 4'h2; i++) begin
            logic [5:0] boundary_off = (i == 4'h1) ? 6'h6 : 6'h5;

            txn = new(1, i, boundary_off, 32'hAAAA_AAAA);
            e.test2drv.put(txn);
            counter++;

            txn = new(0, i, boundary_off);
            e.test2drv.put(txn);
            counter++;

            txn = new(1, i, 6'h3F, 32'hAAAA_AAAA);
            e.test2drv.put(txn);
            counter++;

            txn = new(0, i, 6'h3F);
            e.test2drv.put(txn);
            counter++;
        end

        wait (e.scb.count == counter);
    endtask

endclass
