let
  flake = builtins.getFlake (toString /home/lars/projects/offline-banner);
  pkgs = flake.inputs.nixpkgs.legacyPackages.x86_64-linux;
  lib = flake.inputs.nixpkgs.lib;
  m = import /home/lars/projects/offline-banner/module.nix;
  unitText =
    (lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ m { services.offline-banner.enable = true; } ];
    }).config.systemd.user.units."offline-banner.service".text;
in
pkgs.runCommand "uv-spike5"
  {
    nativeBuildInputs = [ pkgs.stdenv.cc pkgs.systemd ];
    unitText = unitText;
    passAsFile = [ "unitText" ];
  }
  ''
    cp "$unitTextPath" ./u.service
    cat > fakerun.c <<'CSHIM'
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>

static const char *FAKE;

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
    if (!FAKE) { const char *e = getenv("FAKE_RUN"); FAKE = e ? e : "./fakerun"; }
    const char *r = rewrite(path);
    if (!r) return real(path, mode);
    char tmp[4096];
    snprintf(tmp, sizeof tmp, "%s", r);
    for (char *p = tmp + 1; *p; p++)
        if (*p == '/') { *p = 0; real(tmp, 0755); *p = '/'; }
    int rc = real(tmp, mode);
    if (rc < 0 && errno == EEXIST) rc = 0;
    return rc;
}
CSHIM
    cc -shared -fPIC -o fakerun.so fakerun.c -ldl
    export FAKE_RUN="$PWD/fakerun"
    export LD_PRELOAD="$PWD/fakerun.so"
    systemd-analyze verify --man=no ./u.service >verify.log 2>&1
    echo "verify_exit=$?" >> verify.log
    unset LD_PRELOAD
    cp verify.log "$out"
  ''
