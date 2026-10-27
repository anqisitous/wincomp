// main_posix.c
#include "fcontext_win.h"
#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

static fctx main_ctx;
static fctx *co_ctx;
static int   step = 0;

static void coroutine_entry(uint64_t arg) {
    printf("[co] started, arg=%llu\n", (unsigned long long)arg);

    for (int i = 0; i < 3; i++) {
        printf("[co] step %d, yielding to main\n", i);
        jump_fctx(co_ctx, &main_ctx, 0);
        printf("[co] resumed\n");
    }

    printf("[co] finished, returning to main\n");
    jump_fctx(co_ctx, &main_ctx, 0);
}

int main(void) {
    const size_t STACK_SIZE = 1 << 20;

    void *stack = mmap(NULL, STACK_SIZE, PROT_READ | PROT_WRITE,
                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (stack == MAP_FAILED) {
        fprintf(stderr, "mmap failed: %s\n", strerror(errno));
        return 1;
    }

    void *stack_top = (char *)stack + STACK_SIZE;
    co_ctx = make_fctx(stack_top, STACK_SIZE, coroutine_entry);

    printf("[main] switching to coroutine (arg=42)\n");
    jump_fctx(&main_ctx, co_ctx, 42);

    printf("[main] back from coroutine (step=%d)\n", ++step);

    for (int i = 0; i < 3; i++) {
        printf("[main] resuming coroutine\n");
        jump_fctx(&main_ctx, co_ctx, 0);
        printf("[main] back from coroutine (step=%d)\n", ++step);
    }

    printf("[main] done\n");
    exit(0);
    return 0;
}
