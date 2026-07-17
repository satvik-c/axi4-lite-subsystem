class axi_txn;

    rand logic is_write;
    rand logic [11:0] addr;
    rand logic [2:0] prot;
    rand logic [31:0] wdata;
    rand logic [3:0] wstrb;

    logic [31:0] rdata;
    logic [1:0] resp;

    constraint addr_range {
        addr[11:8] dist {
            [4'h0 : 4'h2] :/ 70,
            [4'h3 : 4'hF] :/ 30
        };
        addr[7:2] dist {
            [6'h00 : 6'h05] :/ 70,
            [6'h06 : 6'h3F] :/ 30
        };
        addr[1:0] == 2'b00;
    }

    constraint wstrb_range {
        wstrb dist {
            4'b1111 := 60,
            4'b0001 := 5,
            4'b0010 := 5,
            4'b0100 := 5,
            4'b1000 := 5,
            4'b0011 := 5,
            4'b1100 := 5,
            4'b0000 := 5,
            [4'b0000 : 4'b1111] :/ 5
        };
    }

    constraint wdata_range {
        wdata dist {
            32'h0000_0000 := 10,
            32'hFFFF_FFFF := 10,
            32'h5555_5555 := 5,
            32'hAAAA_AAAA := 5,
            [32'h0000_0001 : 32'hFFFF_FFFE] :/ 70
        };
    }

endclass
