cmake_minimum_required(VERSION 3.16)
project(fcontext_demo C ASM)

if(WIN32)
  set(ASM_SRC fcontext_win.asm)
  enable_language(ASM_MASM)
  set(CMAKE_ASM_MASM_COMPILER ml64)
else()
  # Linux/macOS: provide a POSIX port (fcontext_posix.s) + mmap-based main
  set(ASM_SRC fcontext_posix.s)
  set(MAIN_SRC main_posix.c)
endif()

if(WIN32)
  add_executable(test main.c ${ASM_SRC})
else()
  add_executable(test ${MAIN_SRC} ${ASM_SRC})
endif()

set_target_properties(test PROPERTIES C_STANDARD 11)
