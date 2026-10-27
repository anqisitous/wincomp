# fcontext_posix.s - System V AMD64 ABI port
    .text
    .globl _jump_fctx
    .globl _make_fctx

# void jump_fctx(fctx *from (rdi), fctx *to (rsi), uint64_t arg (rdx))
_jump_fctx:
    # save from
    movq    %rbx, 0(%rdi)
    movq    %rbp, 8(%rdi)
    movq    %r12, 32(%rdi)
    movq    %r13, 40(%rdi)
    movq    %r14, 48(%rdi)
    movq    %r15, 56(%rdi)

    movq    %rsp, 64(%rdi)
    movq    (%rsp), %rax
    movq    %rax, 72(%rdi)

    stmxcsr 80(%rdi)

    movaps  %xmm6,  88(%rdi)
    movaps  %xmm7,  104(%rdi)
    movaps  %xmm8,  120(%rdi)
    movaps  %xmm9,  136(%rdi)
    movaps  %xmm10, 152(%rdi)
    movaps  %xmm11, 168(%rdi)
    movaps  %xmm12, 184(%rdi)
    movaps  %xmm13, 200(%rdi)
    movaps  %xmm14, 216(%rdi)
    movaps  %xmm15, 232(%rdi)

    # restore to
    movq    72(%rsi), %rax
    testq   %rax, %rax
    jnz     .first_entry

    movq    0(%rsi), %rbx
    movq    8(%rsi), %rbp
    movq    32(%rsi), %r12
    movq    40(%rsi), %r13
    movq    48(%rsi), %r14
    movq    56(%rsi), %r15

    ldmxcsr 80(%rsi)
    movaps  88(%rsi), %xmm6
    movaps  104(%rsi), %xmm7
    movaps  120(%rsi), %xmm8
    movaps  136(%rsi), %xmm9
    movaps  152(%rsi), %xmm10
    movaps  168(%rsi), %xmm11
    movaps  184(%rsi), %xmm12
    movaps  200(%rsi), %xmm13
    movaps  216(%rsi), %xmm14
    movaps  232(%rsi), %xmm15

    movq    64(%rsi), %rsp
    ret

.first_entry:
    movq    0(%rsi), %rbx
    movq    8(%rsi), %rbp
    movq    32(%rsi), %r12
    movq    40(%rsi), %r13
    movq    48(%rsi), %r14
    movq    56(%rsi), %r15

    ldmxcsr 80(%rsi)
    movaps  88(%rsi), %xmm6
    movaps  104(%rsi), %xmm7
    movaps  120(%rsi), %xmm8
    movaps  136(%rsi), %xmm9
    movaps  152(%rsi), %xmm10
    movaps  168(%rsi), %xmm11
    movaps  184(%rsi), %xmm12
    movaps  200(%rsi), %xmm13
    movaps  216(%rsi), %xmm14
    movaps  232(%rsi), %xmm15

    movq    64(%rsi), %rsp
    movq    %rdx, %rdi
    jmp     *%rax

# fctx *make_fctx(void *stack_top (rdi), size_t size (rsi), void (*entry)(uint64_t) (rdx))
_make_fctx:
    movq    %rdi, %rax
    subq    $256, %rax
    andq    $-16, %rax

    # zero clear 256 bytes
    xorq    %r9, %r9
    movq    %rax, %r10
    movq    $32, %r11
.clear_loop:
    movq    %r9, (%r10)
    addq    $8, %r10
    decq    %r11
    jnz     .clear_loop

    movq    %rdx, 72(%rax)

    leaq    -40(%rax), %r10
    andq    $-16, %r10
    addq    $8, %r10
    movq    %r10, 64(%rax)
    movq    $0, (%r10)

    movl    $0x1F80, 80(%rax)

    ret
