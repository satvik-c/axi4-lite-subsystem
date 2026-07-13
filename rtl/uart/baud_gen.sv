module baud_gen (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic [15:0] div,
    output logic        baud_tick
);

    logic [15:0] baud_counter;

    assign baud_tick = (baud_counter == div - 1'b1);

    always_ff @(posedge clk) begin
        if (!rst_n) baud_counter <= '0;
        else begin
            if (baud_tick || !enable) baud_counter <= '0;
            else baud_counter <= baud_counter + 1'b1;
        end
    end

endmodule
