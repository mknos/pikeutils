#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

int main(int argc, array(string) argv) {
    int rc = 0;
    if (argc > 1) { // argv[2..] ignored for BSD compat
        string val = getenv(argv[1]);
        if (val)
            write(val + "\n");
        else
            rc = 1;
    } else {
        mapping env = getenv();
        foreach (indices(env), string k)
            write(k + "=" + env[k] + "\n");
    }
    return rc;
}
