#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

void usage() {
    werror("usage: unlink filename\n");
    exit(1);
}

int main(int argc, array(string) argv) {
    Stdio.Stat st;
    string filename;
    int in_opt = 1;

    foreach (argv[1..], string a) {
        if (strlen(a) == 0) {
            werror("unlink: invalid argument\n");
            return 1;
        }
        if (a == "--") {
            in_opt = 0;
            continue;
        }
        if (a[0] != '-')
            in_opt = 0;
        if (in_opt) {
            werror("unlink: unexpected option: '%s'\n", a);
            usage();
        }
        if (stringp(filename)) {
            werror("unlink: extra argument: '%s'\n", a);
            usage();
        }
        filename = a;
    }
    if (!stringp(filename))
        usage();
    st = file_stat(filename);
    if (!st) {
        werror("unlink: '%s': %s\n", filename, strerror(errno()));
        return 1;
    }
    if (st->isdir) {
        werror("unlink: directory argument\n");
        return 1;
    }
    if (!rm(filename)) {
        werror("unlink: '%s': %s\n", filename, strerror(errno()));
        return 1;
    }
    return 0;
}
