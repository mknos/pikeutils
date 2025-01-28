#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

void usage() {
    werror("usage: which [-a] file ...\n");
    exit(2);
}

array(string) search_all(array(string) paths, string file) {
    array(string) found = ({ });

    foreach (paths, string dir) {
        string full = combine_path(dir, file);
        Stdio.Stat st = file_stat(full);
        if (!st)
            continue;
        if (!st->isreg)
            continue;
        if (!access(full, "x"))
            continue;
        found += ({ full });
    }
    return found;
}

int main(int argc, array(string) argv) {
    int aflag = 0;
    int optend = 0;
    int rc = 0;
    array(string) files = ({ });
    array(string) paths;

    if (argc < 2)
        usage();
    foreach (argv[1..], string arg) {
        if (strlen(arg) == 0) {
            werror("which: empty filename string\n");
            continue;
        }
        if (arg == "--") {
            optend = 1;
            continue;
        }
        if (arg[0] != '-')
            optend = 1;
        if (!optend) {
            if (arg == "-a") {
                aflag = 1;
                continue;
            } else if (arg[0] == '-') {
                werror("which: invalid option: %s\n", arg);
                usage();
            }
        } else
            files += ({ arg });
    }

    if (aflag) {
        string path = getenv("PATH");
        if (!path) {
            werror("which: failed to determine PATH\n");
            return 2;
        }
        paths = path / Process.path_separator;
        if (sizeof(paths) == 0) {
            werror("which: empty PATH\n");
            return 2;
        }
    }

    foreach (files, string file) {
        if (aflag) {
            array(string) res = search_all(paths, file);
            if (sizeof(res) == 0) {
                werror("which: %s: command not found\n", file);
                rc = 1;
                continue;
            }
            foreach (res, string path) {
                write(path + "\n");
            }
        } else {
            string path = Process.search_path(file);
            if (!path) {
                werror("which: %s: command not found\n", file);
                rc = 1;
                continue;
            }
            write(path + "\n");
        }
    }
    return rc;
}
