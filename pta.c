#include <stdio.h>
#include <signal.h>
#include <stdint.h>
#include <string.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <fcntl.h>
#include <unistd.h>

#define ALPHABET "abcdefghijklmnopqrstuvwxyz"

#define PASSWORD_MAX_LEN 16

typedef struct {
    int length;
    char password[PASSWORD_MAX_LEN + 1];
    int state[PASSWORD_MAX_LEN];

    int alphabet_length;
    char * alphabet;
} password_iterator_t;

void pw_init(password_iterator_t * pw, char * alphabet) {
    memset(pw, 0, sizeof(password_iterator_t));
    pw->alphabet = alphabet;
    pw->alphabet_length = strlen(alphabet);
}

char * pw_iterate(password_iterator_t * pw) {
    int i, j;
    for (i = 0; i < pw->length; i++) {
        pw->state[i]++;
        if (pw->state[i] == pw->alphabet_length) {
            pw->state[i] = 0;
        } else {
            break;
        }
    }

    if (i == pw->length) {
        pw->length++;
    }

    for (j = 0; j < pw->length; j++) {
        pw->password[j] = pw->alphabet[pw->state[j]];
    }

    return pw->password;
}

void rc4_init(uint8_t state[], const uint8_t key[], int len) {
    int i, j;
    uint8_t t;

    for (i = 0; i < 256; ++i)
        state[i] = i;
    for (i = 0, j = 0; i < 256; ++i) {
        j = (j + state[i] + key[i % len]) % 256;
        t = state[i];
        state[i] = state[j];
        state[j] = t;
    }
}

void rc4_stream(uint8_t state[], uint8_t out[], size_t len) {
    int i, j;
    size_t idx;
    uint8_t t;

    for (idx = 0, i = 0, j = 0; idx < len; ++idx)  {
        i = (i + 1) % 256;
        j = (j + state[i]) % 256;
        t = state[i];
        state[i] = state[j];
        state[j] = t;
        out[idx] = state[(state[i] + state[j]) % 256];
    }
}

int test_password(char * password, uint8_t * plain, uint8_t * cipher) {
    int i;
    uint8_t state[256], buffer[56];
    rc4_init(state, (uint8_t*)password, strlen(password));
    rc4_stream(state, buffer, 56);
    for (i = 0; i < 56; i++) {
        if ((cipher[i] ^ buffer[i]) != plain[i]) {
            return 0;
        }
    }
    return 1;
}

int print_password = 0;
int count = 0;

void handle_alarm(int s) {
    print_password = 1;
}

uint8_t plain[] =
"\x41\x6e\x6f\x74\x68\x65\x72\x20\x6f\x6e\x65\x20\x67\x6f\x74\x20"
"\x63\x61\x75\x67\x68\x74\x20\x74\x6f\x64\x61\x79\x2c\x20\x69\x74"
"\x27\x73\x20\x61\x6c\x6c\x20\x6f\x76\x65\x72\x20\x74\x68\x65\x20"
"\x70\x61\x70\x65\x72\x73\x2e\x0a";
uint8_t cipher[] =
"\x72\x16\xfa\x85\x4c\x3c\xd0\xe4\x59\x05\x79\x54\xd2\x03\xeb\x95"
"\x16\x01\xe7\x3b\x6d\xc8\x64\x2f\x74\x2f\x54\x19\xaa\xbe\xea\x31"
"\x93\x06\xc9\xe1\xfa\x65\x83\x0f\x51\x18\xa7\x27\x94\xff\x96\x34"
"\x5a\xf7\x4c\x29\x85\xde\x87\x14";

int main(int argc, char *argv[]) {
    struct itimerval timer = {
        .it_interval = {
            .tv_usec = 200000,
        },
        .it_value = {
            .tv_sec = 1,
        }
    };
    password_iterator_t ite;

    pw_init(&ite, ALPHABET);
    signal(SIGALRM, handle_alarm);
    setitimer(ITIMER_REAL, &timer, NULL);
    while (pw_iterate(&ite)) {
        count++;
        if (print_password) {
            print_password = 0;
            printf("\r%d  %s", count, ite.password);
            fflush(stdout);
            count = 0;
        }
        if (test_password(ite.password, plain, cipher)) {
            printf("\rPassword: %s\n", ite.password);
            break;
        }
    }

    return 0;
}
