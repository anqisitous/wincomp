#!/usr/bin/env python3
"""Generate Linux port files from the Windows project without modifying originals."""
import re, pathlib, sys

src = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else ".")
out = src / "linux_port"
out.mkdir(exist_ok=True)

# main.c -> main_linux.c
main = (src / "main.c").read_text()
m = main
m = m.replace('#include <windows.h>\n', '#include <sys/mman.h>\n#include <unistd.h>\n')
m = m.replace('VirtualAlloc(NULL, STACK_SIZE,\n                                MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE)',
              'mmap(NULL, STACK_SIZE, PROT_READ | PROT_WRITE,\n               MAP_PRIVATE | MAP_ANONYMOUS, -1, 0)')
m = m.replace('if (!stack) {\n        fprintf(stderr, "VirtualAlloc failed: %lu\\n", GetLastError());',
              'if (stack == MAP_FAILED) {\n        fprintf(stderr, "mmap failed: %s\\n", strerror(errno));')
m = m.replace('VirtualFree(stack, 0, MEM_RELEASE);', 'munmap(stack, STACK_SIZE);')
# add errno include
m = m.replace('#include <stdio.h>', '#include <stdio.h>\n#include <errno.h>\n#include <string.h>')
(out / "main_linux.c").write_text(m)

# asm: copy with header note (ABI differs; manual port required)
asm = (src / "fcontext_win.asm").read_text()
(out / "fcontext_linux.s").write_text("; TODO: port to System V AMD64 ABI\n" + asm)

print("generated:", out)
