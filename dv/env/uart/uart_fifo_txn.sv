typedef enum {
    PUSH,
    POP,
    DROP
} event_e;

class uart_fifo_txn;

    // One modeled FIFO event: type, concurrency flag, data, resulting depth
    event_e     event_t;
    int         concurrent;
    logic [7:0] data;
    int         occupancy;

endclass
