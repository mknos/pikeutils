#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

void usage() {
    werror("usage: unlink filename\n");
    exit(1);
}

int main(int argc, array(string) argv) {
    if (argc > 2) {
        werror("extra argument: '%s'\n", argv[2]);
        usage();
    }
    if (argc < 2)
        usage();
    Stdio.Stat st = file_stat(argv[1]);
    if (!st) {
        werror("unlink: '%s': %s\n", argv[1], strerror(errno()));
        return 1;
    }
    if (st->isdir) {
        werror("unlink: directory argument\n");
        return 1;
    }
    if (!rm(argv[1])) {
        werror("unlink: '%s': %s\n", argv[1], strerror(errno()));
        return 1;
    }
    return 0;
}
