#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

int MATCH   = 0;
int NOMATCH = 1;
int ERROR   = 2;

int opt_c = 0;
int opt_F = 0;
int opt_i = 0;
int opt_l = 0;
int opt_n = 0;
int opt_q = 0;
int opt_v = 0;

void usage() {
    werror("usage: grep [-cFHhilnqsv] [-e pattern] [pattern] [file ...]\n");
    exit(ERROR);
}

int matchfile(Stdio.FILE f, string name, array pats) {
    int count = 0;
    int lineno = 0;
    int showmatch = !opt_c && !opt_l && !opt_q;
    int shortcut = opt_q || opt_l; // terminate on 1st match
    int gotmatch;
    string line;

    if (opt_F) {
        while ((line = f->gets())) {
            lineno++;
            gotmatch = 0;
            foreach (pats, string pattern) {
                if (search(opt_i ? upper_case(line) : line, pattern) >= 0) {
                    gotmatch = 1;
                    break; // avoid checking more patterns
                }
            }
            if (opt_v)
                gotmatch = !gotmatch;
            if (gotmatch) {
                count++;
                if (showmatch) {
                    if (stringp(name))
                        write("%s:", name);
                    if (opt_n)
                        write("%d:", lineno);
                    write("%s\n", line);
                }
                if (shortcut)
                    break;
            }
        }
    } else {
        while ((line = f->gets())) {
            lineno++;
            gotmatch = 0;
            foreach (pats, Regexp re) {
                if (re->match(opt_i ? upper_case(line) : line)) {
                    gotmatch = 1;
                    break;
                }
            }
            if (opt_v)
                gotmatch = !gotmatch;
            if (gotmatch) {
                count++;
                if (showmatch) {
                    if (stringp(name))
                        write("%s:", name);
                    if (opt_n)
                        write("%d:", lineno);
                    write("%s\n", line);
                }
                if (shortcut)
                    break;
            }
        }
    }
    return count;
}

int main(int argc, array(string) argv) {
    array(string) files = ({ });
    array patterns = ({ });
    int opt_H = 0;
    int opt_h = 0;
    int opt_s = 0;
    int header = 0;

    for (int i = 1; i < argc; i++) {
        if (!stringp(argv[i]))
            continue;
        if (argv[i] == "--") {
            argv[i] = 0;
            break;
        }
        if (argv[i][0] != '-')
            break;

        if (argv[i] == "-F") {
            opt_F = 1;
            argv[i] = 0;
        } else if (argv[i] == "-H") {
            opt_H = 1;
            opt_h = 0;
            argv[i] = 0;
        } else if (argv[i] == "-h") {
            opt_h = 1;
            opt_H = 0;
            argv[i] = 0;
        } else if (argv[i] == "-n") {
            opt_n = 1;
            argv[i] = 0;
        } else if (argv[i] == "-i") {
            opt_i = 1;
            argv[i] = 0;
        } else if (argv[i] == "-l") {
            opt_l = 1;
            opt_c = 0;
            argv[i] = 0;
        } else if (argv[i] == "-q") {
            opt_q = 1;
            opt_c = opt_l = 0;
            argv[i] = 0;
        } else if (argv[i] == "-v") {
            opt_v = 1;
            argv[i] = 0;
        } else if (argv[i] == "-c") {
            opt_c = 1;
            argv[i] = 0;
        } else if (argv[i] == "-s") {
            opt_s = 1;
            argv[i] = 0;
        } else if (argv[i] == "-e") {
            if (i + 1 == argc)
                usage();
            patterns += ({ argv[i + 1] });
            argv[i + 1] = 0;
            argv[i] = 0;
        } else {
            werror("invalid option: '%s'\n", argv[i]);
            usage();
        }
    }
    // 1st argument is pattern unless -e was given
    if (sizeof(patterns) == 0) {
        for (int i = 1; i < argc; i++) {
            if (!stringp(argv[i]))
                continue;
            patterns += ({ argv[i] });
            argv[i] = 0;
            break;
        }
    }
    if (sizeof(patterns) == 0)
        usage();
    if (opt_i)
        for (int i = 0; i < sizeof(patterns); i++)
            patterns[i] = upper_case(patterns[i]);
    if (!opt_F)
        for (int i = 0; i < sizeof(patterns); i++)
            patterns[i] = Regexp(patterns[i]);

    foreach (argv[1..], string filename) {
        if (!stringp(filename))
            continue;
        files += ({ filename });
    }
    if (!opt_h && (opt_H || sizeof(files) > 1))
        header = 1;
    int rc = NOMATCH;
    foreach (files, string filename) {
        if (!access(filename, "r")) {
            if (!opt_s)
                werror("grep: '%s': %s\n", filename, strerror(errno()));
            rc = ERROR;
            continue;
        }
        Stdio.FILE f = Stdio.FILE(filename);
        if (!f) {
            if (!opt_s)
                werror("grep: '%s': %s\n", filename, strerror(errno()));
            rc = ERROR;
            continue;
        }
        mixed st = f->stat();
        if (st->isdir) {
            if (!opt_s)
                werror("grep: '%s': is a directory\n", filename);
            f->close();
            rc = ERROR;
            continue;
        }
        int c = matchfile(f, header ? filename : 0, patterns);
        f->close();
        if (c) {
            rc = MATCH;
            if (opt_q)
                break; // avoid searching next file on match
            if (opt_l)
                write("%s\n", filename);
        }
        if (opt_c) {
            if (header)
                write("%s:", filename);
            write("%d\n", c);
        }
    }
    if (sizeof(files) == 0) {
        int c = matchfile(Stdio.stdin, header ? "(stdin)" : 0, patterns);
        if (c) {
            rc = MATCH;
            if (opt_l)
                write("(stdin)\n");
        }
        if (opt_c) {
            if (header)
                write("(stdin):");
            write("%d\n", c);
        }
    }
    return rc;
}
