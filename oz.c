struct queue {
    uint16_t location;
    uint8_t producer_id;
    uint8_t consumer_id;
};

struct function {
    uint16_t address;
    uint16_t sp;
    //uint8_t page; // pageable heap
};

uint8_t CURR_QS[256];

struct queue CURR_Q[256];

struct function FUNC[256];

uint8_t queue_id = 0;
uint8_t status = 0;
struct queue* current_q;

uint8_t function_id;
struct function* func;
uint16_t address;

k_main_loop:
    status = CURR_QS[queue_id];
    if (status == 0) {
        goto k_next_q;
    }
    current_q = &CURR_Q[queue_id];

    function_id = current_q->producer_id;
    func = &FUNC[function_id];
    address = function->address;
    // wipe registers
    // load function sp into cpu sp
    // push k_consumer_block onto sp
    goto address;

k_consumer_block:
    function_id = current_q->consumer_id;
    func = &FUNC[function_id];
    address = function->address;
    // wipe registers
    // load function sp into cpu sp
    // push k_next_q onto sp
    goto address;

k_next_q:
    queue_id++;
    goto k_main_loop;
}

void k_write_queue(uint16_t buff, uint8_t size) {
}

uint8_t k_read_queue(uint16_t buff, uint8_t size) {
}


