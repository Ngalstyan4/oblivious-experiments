#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>

int main(int argc, char** argv) {
    const char* argument = "rdma://1,192.168.0.12:9400";
    long rv = syscall(326, argument);
    if (rv != 0) {
        perror("is_session_create");
    }
    return 0;
}
