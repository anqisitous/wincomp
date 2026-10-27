// fcontext_win.h
#pragma once
#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct fctx {
    // --- 整数レジスタ（callee-saved + 制御用） ---
    uint64_t rbx;         // +0
    uint64_t rbp;         // +8
    uint64_t rdi;         // +16
    uint64_t rsi;         // +24
    uint64_t r12;         // +32
    uint64_t r13;         // +40
    uint64_t r14;         // +48
    uint64_t r15;         // +56
    uint64_t rsp;         // +64
    uint64_t rip;         // +72
    // --- MXCSR ---
    uint32_t mxcsr;       // +80
    uint32_t _pad;        // +84
    // --- XMM6〜XMM15（Windows では callee-saved） ---
    uint8_t  xmm[10][16]; // +88 .. +247
} fctx;

// ---- アセンブリ側のオフセットと一致することをコンパイル時に検証 ----
_Static_assert(offsetof(fctx, rbx)   ==   0, "rbx offset");
_Static_assert(offsetof(fctx, rbp)   ==   8, "rbp offset");
_Static_assert(offsetof(fctx, rdi)   ==  16, "rdi offset");
_Static_assert(offsetof(fctx, rsi)   ==  24, "rsi offset");
_Static_assert(offsetof(fctx, r12)   ==  32, "r12 offset");
_Static_assert(offsetof(fctx, r13)   ==  40, "r13 offset");
_Static_assert(offsetof(fctx, r14)   ==  48, "r14 offset");
_Static_assert(offsetof(fctx, r15)   ==  56, "r15 offset");
_Static_assert(offsetof(fctx, rsp)   ==  64, "rsp offset");
_Static_assert(offsetof(fctx, rip)   ==  72, "rip offset");
_Static_assert(offsetof(fctx, mxcsr) ==  80, "mxcsr offset");
_Static_assert(offsetof(fctx, xmm)   ==  88, "xmm offset");

// アセンブリ関数プロトタイプ
// jump_fctx: from に現在の状態を保存し、to の状態を復元して切り替える
//            to が初回起動（to->rip != 0）なら entry(arg) に飛ぶ
void  jump_fctx(fctx *from, fctx *to, uint64_t arg);

// make_fctx: stack_top 以下の領域に fctx を初期化して返す
fctx *make_fctx(void *stack_top, size_t size, void (*entry)(uint64_t));

#ifdef __cplusplus
}
#endif