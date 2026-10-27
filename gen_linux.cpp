#include <fstream>
#include <iostream>
#include <filesystem>
#include <string>
namespace fs = std::filesystem;
int main(int argc, char** argv) {
    fs::path src = argc > 1 ? argv[1] : ".";
    fs::path out = src / "linux_port";
    fs::create_directories(out);
    // main.c -> main_linux.c
    std::ifstream in(src / "main.c");
    std::string m((std::istreambuf_iterator<char>(in)), {});
    auto rep = [&](const std::string& a, const std::string& b){ size_t p=0; while((p=m.find(a,p))!=std::string::npos){m.replace(p,a.size(),b);p+=b.size();} };
    rep("#include <windows.h>\n", "#include <sys/mman.h>\n#include <unistd.h>\n");
    rep("#include <stdio.h>", "#include <stdio.h>\n#include <errno.h>\n#include <string.h>");
    rep("VirtualAlloc(NULL, STACK_SIZE,\n                                MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE)",
        "mmap(NULL, STACK_SIZE, PROT_READ | PROT_WRITE,\n               MAP_PRIVATE | MAP_ANONYMOUS, -1, 0)");
    rep("if (!stack) {\n        fprintf(stderr, \"VirtualAlloc failed: %lu\\n\", GetLastError());",
        "if (stack == MAP_FAILED) {\n        fprintf(stderr, \"mmap failed: %s\\n\", strerror(errno));");
    rep("VirtualFree(stack, 0, MEM_RELEASE);", "munmap(stack, STACK_SIZE);");
    std::ofstream(out/"main_linux.c") << m;
    // asm placeholder
    std::ifstream a(src/"fcontext_win.asm");
    std::string asm_((std::istreambuf_iterator<char>(a)), {});
    std::ofstream(out/"fcontext_linux.s") << "; TODO: port to System V AMD64 ABI\n" << asm_;
    std::cout << "generated: " << out << "\n";
}
