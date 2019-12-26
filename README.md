# oz-rc2014

Playing with operating system ideas for the RC2014 computer.

* No preemptive multitasking (no interrupt via CTC hardware)
* No process model - the function is the unit of execution

Applications are collections of functions, combined with an environment. The environment is a stack, saved registers and some heap. Applications do work by registering callback functions to event queues (producers and consumers). Some event queues are provided by the operating system, some provided by other applications.

There is no concept of process or thread, only different configurations of stack pointer, heap location and functions - chunks of code that are called and return, without intering into any form of event loop. The only event loop is the kernel performing dispatch on the event queues.

## Environment

Each function is called with an environment loaded. The environment is the location of the stack pointer, saved register states that are restored right before the function is executed and saved right after the function returns, and the location of the heap. Functions that execute with an independent stack pointer but a shared heap behave in a similar way to threads. However there is no memory locking required as only one function can execute at a time. In a process or thread orientated operating system each thread will probably have it's own event loop. The operating system will interrupt and share CPU time between the threads meaning they must use some form or locking when accessing heap memory.
