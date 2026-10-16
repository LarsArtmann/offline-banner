#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <unistd.h>

static const char *FAKE;

static void init(void) {
    FAKE = getenv("FAKE_RUN");
    if (!FAKE) FAKE = "./fakerun";
}

static char *rewrite(const char *path) {
    if (!path) return NULL;
    if (strncmp(path, "/run/", 5) == 0) {
        static char buf[4096];
        snprintf(buf, sizeof buf, "%s/%s", FAKE, path + 5);
        return buf;
    }
    if (strcmp(path, "/run") == 0) return (char *)FAKE;
    return NULL;
}

int mkdir(const char *path, mode_t mode) {
    static int (*real)(const char *, mode_t);
    if (!real) real = dlsym(RTLD_NEXT, "mkdir");
    if (!FAKE) init();
    const char *r = rewrite(path);
    if (!r) return real(path, mode);
    char tmp[4096];
    snprintf(tmp, sizeof tmp, "%s", r);
    for (char *p = tmp + 1; *p; p++)
        if (*p == '/') { *p = 0; mkdir(tmp, 0755); *p = '/'; }
    int rc = mkdir(tmp, mode);
    if (rc < 0 && errno == EEXIST) rc = 0;
    return rc;
}

int open(const char *path, int flags, ...) {
    static int (*real)(const char *, int, ...);
    if (!real) real = dlsym(RTLD_NEXT, "open");
    if (!FAKE) init();
    mode_t mode = 0;
    if (flags & (O_CREAT | O_TMPFILE)) {
        va_list ap; va_start(ap, flags); mode = va_arg(ap, int); va_end(ap);
    }
    const char *r = rewrite(path);
    if (!r) return real(path, flags, mode);
    return real(r, flags, mode);
}

FILE *fopen(const char *path, const char *m) {
    static FILE *(*real)(const char *, const char *);
    if (!real) real = dlsym(RTLD_NEXT, "fopen");
    if (!FAKE) init();
    const char *r = rewrite(path);
    return r ? real(r, m) : real(path, m);
}
