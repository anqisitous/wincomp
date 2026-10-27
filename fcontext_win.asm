; fcontext_win.asm
; MASM (ml64.exe) / Intel 構文 / Windows x64 ABI
;
; オフセットは fcontext_win.h の fctx と一致させること:
;   rbx=+0, rbp=+8, rdi=+16, rsi=+24, r12=+32, r13=+40, r14=+48, r15=+56
;   rsp=+64, rip=+72, mxcsr=+80, xmm=+88

.code

; ---------------------------------------------------------------------------
; void jump_fctx(fctx *from, fctx *to, uint64_t arg)
;   RCX = from, RDX = to, R8 = arg
; ---------------------------------------------------------------------------
public jump_fctx
jump_fctx PROC FRAME
    ; ---- from 側の状態を保存 ----
    mov     [rcx + 0],  rbx
    mov     [rcx + 8],  rbp
    mov     [rcx + 16], rdi
    mov     [rcx + 24], rsi
    mov     [rcx + 32], r12
    mov     [rcx + 40], r13
    mov     [rcx + 48], r14
    mov     [rcx + 56], r15

    ; RSP は「ret で戻れる位置」を保存する。
    ; 現在の RSP は戻りアドレスを指しているので、
    ; そのまま保存すれば ret で正しく戻れる。
    mov     [rcx + 64], rsp
    ; 戻りアドレス（呼び出し元の RIP）を保存
    mov     rax, [rsp]
    mov     [rcx + 72], rax

    stmxcsr [rcx + 80]

    movaps  [rcx + 88  + 0*16], xmm6
    movaps  [rcx + 88  + 1*16], xmm7
    movaps  [rcx + 88  + 2*16], xmm8
    movaps  [rcx + 88  + 3*16], xmm9
    movaps  [rcx + 88  + 4*16], xmm10
    movaps  [rcx + 88  + 5*16], xmm11
    movaps  [rcx + 88  + 6*16], xmm12
    movaps  [rcx + 88  + 7*16], xmm13
    movaps  [rcx + 88  + 8*16], xmm14
    movaps  [rcx + 88  + 9*16], xmm15

    ; ---- to 側の状態を復元 ----
    mov     rax, [rdx + 72]     ; to->rip
    test    rax, rax
    jnz     .first_entry

    ; --- 通常の再開パス ---
    mov     rbx, [rdx + 0]
    mov     rbp, [rdx + 8]
    mov     rdi, [rdx + 16]
    mov     rsi, [rdx + 24]
    mov     r12, [rdx + 32]
    mov     r13, [rdx + 40]
    mov     r14, [rdx + 48]
    mov     r15, [rdx + 56]

    ldmxcsr [rdx + 80]
    movaps  xmm6,  [rdx + 88  + 0*16]
    movaps  xmm7,  [rdx + 88  + 1*16]
    movaps  xmm8,  [rdx + 88  + 2*16]
    movaps  xmm9,  [rdx + 88  + 3*16]
    movaps  xmm10, [rdx + 88  + 4*16]
    movaps  xmm11, [rdx + 88  + 5*16]
    movaps  xmm12, [rdx + 88  + 6*16]
    movaps  xmm13, [rdx + 88  + 7*16]
    movaps  xmm14, [rdx + 88  + 8*16]
    movaps  xmm15, [rdx + 88  + 9*16]

    mov     rsp, [rdx + 64]     ; SP 復元（[rsp] に戻りアドレスがある）
    ret

.first_entry:
    ; --- 初回起動パス ---
    ; make_fctx がスタック上に偽フレームを作ってある。
    ; ここではレジスタを復元して rip へ jmp する。
    mov     rbx, [rdx + 0]
    mov     rbp, [rdx + 8]
    mov     rdi, [rdx + 16]
    mov     rsi, [rdx + 24]
    mov     r12, [rdx + 32]
    mov     r13, [rdx + 40]
    mov     r14, [rdx + 48]
    mov     r15, [rdx + 56]

    ldmxcsr [rdx + 80]
    movaps  xmm6,  [rdx + 88  + 0*16]
    movaps  xmm7,  [rdx + 88  + 1*16]
    movaps  xmm8,  [rdx + 88  + 2*16]
    movaps  xmm9,  [rdx + 88  + 3*16]
    movaps  xmm10, [rdx + 88  + 4*16]
    movaps  xmm11, [rdx + 88  + 5*16]
    movaps  xmm12, [rdx + 88  + 6*16]
    movaps  xmm13, [rdx + 88  + 7*16]
    movaps  xmm14, [rdx + 88  + 8*16]
    movaps  xmm15, [rdx + 88  + 9*16]

    mov     rsp, [rdx + 64]
    mov     rcx, r8              ; 第1引数 = arg（Windows ABI）
    jmp     rax                  ; entry へ
jump_fctx ENDP

; ---------------------------------------------------------------------------
; fctx *make_fctx(void *stack_top, size_t size, void (*entry)(uint64_t))
;   RCX = stack_top, RDX = size, R8 = entry
; 戻り値: RAX = fctx*
; ---------------------------------------------------------------------------
public make_fctx
make_fctx PROC FRAME
    ; fctx を stack_top の直下に確保（16バイトアライメント）
    mov     rax, rcx            ; stack_top
    sub     rax, 256            ; sizeof(fctx) = 256
    and     rax, -16            ; 16バイト境界に落とす
    ; rax = fctx 先頭

    ; ゼロクリア（32 qword = 256 byte）
    xor     r9, r9
    mov     r10, rax
    mov     r11, 32
.clear_loop:
    mov     [r10], r9
    add     r10, 8
    dec     r11
    jnz     .clear_loop

    ; rip = entry
    mov     [rax + 72], r8

    ; rsp: fctx の下に「戻りアドレス用のダミー + シャドウスペース」を確保
    ;  Windows x64: 関数入口で RSP % 16 == 8。
    ;  jump_fctx の初回パスは jmp で entry に入るので、
    ;  entry から見て「jump_fctx から call された直後」と同じ形にする。
    ;  → RSP は 8 mod 16 に置き、[rsp] にダミー戻りアドレスを置く。
    lea     r10, [rax - 40]     ; 32(shadow) + 8(ret addr)
    and     r10, -16
    add     r10, 8              ; RSP % 16 == 8 にする
    mov     [rax + 64], r10
    mov     qword ptr [r10], 0  ; ダミー戻りアドレス

    ; MXCSR 既定値
    mov     dword ptr [rax + 80], 1F80h

    ret
make_fctx ENDP

END