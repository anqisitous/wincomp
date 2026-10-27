// main.c
#include "fcontext_win.h"
#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>

static fctx main_ctx;
static fctx *co_ctx;
static int   step = 0;

// コルーチン本体。arg は初回起動時に RCX で渡される。
static void coroutine_entry(uint64_t arg) {
    printf("[co] started, arg=%llu\n", (unsigned long long)arg);

    for (int i = 0; i < 3; i++) {
        printf("[co] step %d, yielding to main\n", i);
        jump_fctx(co_ctx, &main_ctx, 0);   // main に戻る
        printf("[co] resumed\n");
    }

    printf("[co] finished, returning to main\n");
    jump_fctx(co_ctx, &main_ctx, 0);       // 最後も main に戻る
    // ここには戻らない（main 側で終了）
}

int main(void) {
    const size_t STACK_SIZE = 1 << 20;  // 1 MiB

    void *stack = VirtualAlloc(NULL, STACK_SIZE,
                               MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);
    if (stack == MAP_FAILED) {
        fprintf(stderr, "mmap failed: %s\n", strerror(errno));
        return 1;
    }

    void *stack_top = (char *)stack + STACK_SIZE;
    co_ctx = make_fctx(stack_top, STACK_SIZE, coroutine_entry);

    printf("[main] switching to coroutine (arg=42)\n");
    jump_fctx(&main_ctx, co_ctx, 42);

    printf("[main] back from coroutine (step=%d)\n", ++step);

    // コルーチンを再開
    for (int i = 0; i < 4; i++) {
        printf("[main] resuming coroutine\n");
        jump_fctx(&main_ctx, co_ctx, 0);
        printf("[main] back from coroutine (step=%d)\n", ++step);
    }

    printf("[main] done\n");
    munmap(stack, STACK_SIZE);
    return 0;
}