// ========================================================
// Bound assertions checking the UART FIFO's occupancy bounds and the wrapper's pop-gating
// ========================================================

module uart_fifo_sva
#(
    parameter DEPTH = 64,
    localparam ADDR_W = $clog2(DEPTH)
)(
    input logic            clk,
    input logic            rst_n,
    input logic            wr_en,
    input logic [7:0]      wr_data,
    input logic            rd_en,
    input logic [7:0]      rd_data,
    input logic            full,
    input logic            empty,
    input logic [ADDR_W:0] wr_ptr,
    input logic [ADDR_W:0] rd_ptr
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    logic [ADDR_W:0] occupancy;
    assign occupancy = wr_ptr - rd_ptr;

    // W3: pointer-derived occupancy stays within [0, DEPTH]
    W3: assert property (occupancy >= 0 && occupancy <= DEPTH);

    // W4: flags agree with occupancy at the extremes
    W4_full:  assert property (full |-> occupancy == DEPTH);
    W4_empty: assert property (empty |-> occupancy == 0);

    // W5: concurrent push+pop while full leaves occupancy unchanged
    W5: assert property ((wr_en && full && rd_en) |=> $stable(occupancy));

    // W6: pop while empty with a concurrent push forwards the pushed byte
    W6: assert property ((rd_en && empty && wr_en) |=> ($stable(occupancy) && rd_data == $past(wr_data)));

    // W8: read data changes only after an accepted pop
    W8: assert property ($changed(rd_data) |-> $past(rd_en && (!empty || wr_en)));

endmodule


module uart_wrapper_sva
(
    input logic clk,
    input logic rst_n,
    input logic tx_en,
    input logic rd_en
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (!rst_n);

    // W7: a FIFO pop only occurs while TX is enabled
    W7: assert property (rd_en |-> tx_en);

endmodule
