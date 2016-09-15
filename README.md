# Demo Linux GCD Issue

On the Linux / Server side:

    helge@swiftywily:~/dev/Swift/linux-gcd-issue$ .build/debug/sockd
    listening ...

From somewhere else:

    helge@zpro ~ $ telnet swiftywily 1337
    Trying 192.168.88.50...
    Connected to swiftywily.
    Escape character is '^]'.

Server:

    FD: 6

Client:

    Enter Anything, say: Hello World RETURN

Server:

    CHANNEL READ: false Optional(Dispatch.DispatchData(__wrapped: Dispatch.__DispatchData)) 0
    Illegal instruction (core dumped)

## LLDB

    helge@swiftywily:~/dev/Swift/linux-gcd-issue$ lldb .build/debug/sockd
    (lldb) target create ".build/debug/sockd"
    Current executable set to '.build/debug/sockd' (x86_64).
    (lldb) r
    Process 1139 launched: '/home/helge/dev/Swift/linux-gcd-issue/.build/debug/sockd' (x86_64)
    listening ...
      FD: 6
      CHANNEL READ: false Optional(Dispatch.DispatchData(__wrapped: Dispatch.__DispatchData)) 0
    Process 1139 stopped
    * thread #6: tid = 1146, 0x00007ffff7efb503 libdispatch.so`_os_object_release + 35, name = 'sockd', stop reason = signal SIGILL: illegal instruction operand
    frame #0: 0x00007ffff7efb503 libdispatch.so`_os_object_release + 35
    libdispatch.so`_os_object_release:
    ->  0x7ffff7efb503 <+35>: ud2    
        0x7ffff7efb505:       nopw   %cs:(%rax,%rax)
    libdispatch.so`_os_object_retain_weak:
        0x7ffff7efb510 <+0>:  movl   0xc(%rdi), %eax
        0x7ffff7efb513 <+3>:  movb   $0x1, %cl
    (lldb) bt
    * thread #6: tid = 1146, 0x00007ffff7efb503 libdispatch.so`_os_object_release + 35, name = 'sockd', stop reason = signal SIGILL: illegal instruction operand
      * frame #0: 0x00007ffff7efb503 libdispatch.so`_os_object_release + 35
        frame #1: 0x00007ffff7ef46b7 libdispatch.so`_dispatch_call_block_and_release + 7
        frame #2: 0x00007ffff7f00d01 libdispatch.so`_dispatch_queue_serial_drain + 769
        frame #3: 0x00007ffff7f01362 libdispatch.so`_dispatch_queue_invoke + 914
        frame #4: 0x00007ffff7f00c3a libdispatch.so`_dispatch_queue_serial_drain + 570
        frame #5: 0x00007ffff7f01362 libdispatch.so`_dispatch_queue_invoke + 914
        frame #6: 0x00007ffff7f03442 libdispatch.so`_dispatch_root_queue_drain + 306
        frame #7: 0x00007ffff7f2ad17 libdispatch.so`overcommit_worker_main(unused=<unavailable>) + 183 at manager.c:287 [opt]
        frame #8: 0x00007ffff78196aa libpthread.so.0`start_thread + 202
        frame #9: 0x00007ffff68a713d libc.so.6`clone + 109


