#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

int MATCH   = 0;
int NOMATCH = 1;
int ERROR   = 2;

int opt_A = 0;
int opt_B = 0;
int opt_c = 0;
int opt_F = 0;
int opt_i = 0;
int opt_L = 0;
int opt_l = 0;
int opt_m = 0;
int opt_n = 0;
int opt_q = 0;
int opt_v = 0;

void usage() {
    werror("usage: grep [-cFHhilnqsv] [-A num] [-B num] [-C num] " +
        "[-m num] [-e pattern] [pattern] [file ...]\n");
    exit(ERROR);
}

int matchfile(Stdio.FILE f, string name, array pats) {
    array(string) lnprefix = ({ });
    int count = 0;
    int lineno = 0;
    int i_after = 0;
    int showmatch = !opt_c && !opt_L && !opt_l && !opt_q;
    int shortcut = opt_q || opt_L || opt_l; // terminate on 1st match
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
                int i_before = 0;
                if (opt_B) {
                    for (int i = 0; i < sizeof(lnprefix); i++) {
                        int ctx_lineno = lineno - (opt_B - i);
                        if (stringp(name))
                            write("%s:", name);
                        if (opt_n)
                            write("%d-", ctx_lineno);
                        write("%s\n", lnprefix[i]);
                        i_before = 1;
                    }
                    lnprefix = ({ });
                }
                if (showmatch) {
                    if (stringp(name))
                        write("%s:", name);
                    if (opt_n)
                        write("%d:", lineno);
                    write("%s\n", line);
                    if (i_before && !opt_A)
                        write("--\n");
                }
                if (shortcut)
                    break;
                i_after = opt_A;
                if (!opt_A && opt_m == count)
                    break; // final match, no trailing context
            } else if (i_after) {
                if (stringp(name))
                    write("%s:", name);
                if (opt_n)
                    write("%d-", lineno);
                write("%s\n", line);
                i_after--;
                if (!i_after) {
                    write("--\n");
                    if (opt_m == count)
                        break; // final match with context
                }
            } else if (opt_B) {
                lnprefix += ({ line });
                if (sizeof(lnprefix) > opt_B)
                    lnprefix = lnprefix[1..];
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
                int i_before = 0;
                if (opt_B) {
                    for (int i = 0; i < sizeof(lnprefix); i++) {
                        int ctx_lineno = lineno - (opt_B - i);
                        if (stringp(name))
                            write("%s:", name);
                        if (opt_n)
                            write("%d-", ctx_lineno);
                        write("%s\n", lnprefix[i]);
                        i_before = 1;
                    }
                    lnprefix = ({ });
                }
                if (showmatch) {
                    if (stringp(name))
                        write("%s:", name);
                    if (opt_n)
                        write("%d:", lineno);
                    write("%s\n", line);
                    if (i_before && !opt_A)
                        write("--\n");
                }
                if (shortcut)
                    break;
                i_after = opt_A;
                if (!opt_A && opt_m == count)
                    break;
            } else if (i_after) {
                if (stringp(name))
                    write("%s:", name);
                if (opt_n)
                    write("%d-", lineno);
                write("%s\n", line);
                i_after--;
                if (!i_after) {
                    write("--\n");
                    if (opt_m == count)
                        break;
                }
            } else if (opt_B) {
                lnprefix += ({ line });
                if (sizeof(lnprefix) > opt_B)
                    lnprefix = lnprefix[1..];
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

    Regexp num_re = Regexp("^[0-9]+$");
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
        } else if (argv[i] == "-A") {
            if (i + 1 == argc)
                usage();
            if (!num_re.match(argv[i + 1])) {
                werror("invalid -A number\n");
                usage();
            }
            opt_A = (int)argv[i + 1];
            argv[i + 1] = argv[i] = 0;
        } else if (argv[i] == "-B") {
            if (i + 1 == argc)
                usage();
            if (!num_re.match(argv[i + 1])) {
                werror("invalid -B number\n");
                usage();
            }
            opt_B = (int)argv[i + 1];
            argv[i + 1] = argv[i] = 0;
        } else if (argv[i] == "-C") {
            if (i + 1 == argc)
                usage();
            if (!num_re.match(argv[i + 1])) {
                werror("invalid -C number\n");
                usage();
            }
            opt_A = opt_B = (int)argv[i + 1];
            argv[i + 1] = argv[i] = 0;
        } else if (argv[i] == "-m") {
            if (i + 1 == argc)
                usage();
            if (!num_re.match(argv[i + 1])) {
                werror("invalid -m number\n");
                usage();
            }
            opt_m = (int)argv[i + 1];
            argv[i + 1] = argv[i] = 0;
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
        } else if (argv[i] == "-L") {
            opt_L = 1;
            opt_l = opt_A = opt_B = opt_c = 0;
            argv[i] = 0;
        } else if (argv[i] == "-l") {
            opt_l = 1;
            opt_L = opt_A = opt_B = opt_c = 0;
            argv[i] = 0;
        } else if (argv[i] == "-q") {
            opt_q = 1;
            opt_A = opt_B = opt_c = opt_l = 0;
            argv[i] = 0;
        } else if (argv[i] == "-v") {
            opt_v = 1;
            argv[i] = 0;
        } else if (argv[i] == "-c") {
            opt_c = 1;
            opt_A = opt_B = 0;
            argv[i] = 0;
        } else if (argv[i] == "-s") {
            opt_s = 1;
            argv[i] = 0;
        } else if (argv[i] == "-e") {
            if (i + 1 == argc)
                usage();
            patterns += ({ argv[i + 1] });
            argv[i + 1] = argv[i] = 0;
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
        } else {
            if (opt_L)
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
        } else {
            if (opt_L)
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
