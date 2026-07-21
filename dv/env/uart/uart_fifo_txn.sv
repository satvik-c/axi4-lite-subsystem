typedef enum {
    PUSH,
    POP,
    DROP
} event_e;

class uart_fifo_txn;

    event_e event_t;
    int concurrent;
    logic [7:0] data;
    int occupancy;

endclass
