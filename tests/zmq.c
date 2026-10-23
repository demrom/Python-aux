#include <assert.h>
#include <dirent.h>
#include <stdio.h>
#include <string.h>
#include <zmq.h>

static int descriptor_count(void) {
    DIR *directory = opendir("/dev/fd");
    if (!directory) return -1;
    int count = 0;
    while (readdir(directory)) count++;
    closedir(directory);
    return count;
}

int main(void) {
    int baseline = descriptor_count();
    assert(baseline >= 0);
    for (int run = 0; run < 2; run++) {
        void *context = zmq_ctx_new();
        assert(context);
        void *sender = zmq_socket(context, ZMQ_PAIR);
        void *receiver = zmq_socket(context, ZMQ_PAIR);
        assert(sender && receiver);
        int timeout = 1000, linger = 0;
        assert(zmq_setsockopt(sender, ZMQ_SNDTIMEO, &timeout, sizeof(timeout)) == 0);
        assert(zmq_setsockopt(receiver, ZMQ_RCVTIMEO, &timeout, sizeof(timeout)) == 0);
        assert(zmq_setsockopt(sender, ZMQ_LINGER, &linger, sizeof(linger)) == 0);
        assert(zmq_setsockopt(receiver, ZMQ_LINGER, &linger, sizeof(linger)) == 0);
        assert(zmq_bind(sender, "inproc://framework-consumer") == 0);
        assert(zmq_connect(receiver, "inproc://framework-consumer") == 0);
        const char message[] = "ZMQ Unicode \xe4\xb8\x96\xe7\x95\x8c";
        char received[64];
        assert(zmq_send(sender, message, sizeof(message), 0) == sizeof(message));
        assert(zmq_recv(receiver, received, sizeof(received), 0) == sizeof(message));
        assert(memcmp(received, message, sizeof(message)) == 0);
        assert(zmq_close(sender) == 0 && zmq_close(receiver) == 0);
        assert(zmq_ctx_term(context) == 0);
        int after = descriptor_count();
        if (after != baseline) {
            fprintf(stderr, "ZeroMQ run %d descriptors: %d -> %d\n", run + 1, baseline, after);
            return 1;
        }
        printf("ZeroMQ socket round trip %d PASS\n", run + 1);
    }
    return 0;
}
