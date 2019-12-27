# Kernel

There are no processes in the OS, only event handler functions and the "environment" those functions are executed in. The environment is defined by the saved state of all registers, and some allocated area of memory (ideally paged in and out if supported by hardware). Starting a program means setting up an environment, creating the required event queues and attaching producer functions, consumer functions or both to the queues.

The main loop of the OS spends its time looping over these queues. For each queue, first the producer function is called. The queue is then checked if there is unread data available for reading and if so the consumer function is called. The producer and consumer functions may have different environments, meaning the environment may be swapped between the producer and consumer function calls.

    foreach queue in queues:
        call queue.producer
        if queue has unread data:
            call queue.consumer

The kernel may set up some default queues at boot time. For example two queues for stdin and stdout of a serial device. The producer function for the stdin queue could be a polling function checking for new characters from the serial device. The consumer function for the stdout queue is a function to write bytes to the serial device. The consumer function for the stdin queue could be a shell environment waiting for user input. Likewise the producer function for the stdout queue could be the same shell environment echoing those characters back to the serial device.

## Kernel structures

### Queue status table

A list of bytes, where zero is an unused queue and any other value is the status of the queue (empty, full etc). The main loop of the OS is over this table to determine if a queue needs to be acted on.

    uint8_t queue_status[256];

Code needed:

* Find the next active status in the table
* Set a given status in the table

### Queue table

A list of queue table structures. An entry holds the id of the producer function, id of the consumer function and the location and size of the queue.

    struct queue {
        uint8_t producer_id;
        uint8_t consumer_id;
        uint16_t location;
    };

Size: 4 bytes

### Function table

This table holds entries for each registered function. An entry has the location of the function in memory (call address) and an environment id. The environment id refers to an environment that must be set up before calling the function.

    struct function {
        uint8_t environment_id;
        uint16_t address;
        uint8_t padding;
    };

Size: 4 bytes

#### Calling a consumer function

* Push the return address onto the stack
* Push the id of the queue
* Jump to the consumer function

The consumer function then pops off the id argument and calls a read function in the kernel with the location of a buffer to copy the data into.

#### Calling a producer function

* Push the return address onto the stack
* Push the id of the queue
* Jump to the producer function

### Environment table

Each entry in the environment table stores the stack pointer and the saved registers for this function. Before a function is called the environment is set up according to this table.

    struct environment {
        uint16_t sp;
        uint16_t af;
        uint16_t bc;
        uint16_t de;
        uint16_t hl;
        uint16_t ix;
        uint16_t iy;
        uint8_t page;
        uint8_t padding;
    };

Size: 32 bytes

## Operation

### Cycle through the queue status table until an active queue is found

    uint8_t k_q_get_status(uint8_t status) {
        uint8_t queue_id = CURR_QS_ID;
        for (uint8_t count = 0; count < 64; count++) {
            queue_id++;
            if (queue_id >= 64) {
                queue_id = 0;
            }
            if (CURR_QS[queue_id] == status) {
                return queue_id;
            }
        }
        return 0;
    }

### Lookup the producer function for this queue

    struct queue active_q = CURR_Q[queue_id];
    uint8_t producer_id = active_q.producer_id;

* Look up the environment for this function and enable it
* Call the producer function
* Check if the queue is not empty
* If not look up the consumer function environment and enable it
* Call the consumer function

