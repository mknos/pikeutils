#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

int canprint(int c) {
    if (c == '\t')
        return 1;
    if (c >= 32 && c <= 126) 
        return 1;
    return 0;
}

void usage() {
    werror("usage: strings [-n min_length] file ...\n");
    exit(1);
}

int do_file(string filename, int length) { 
    if (!access(filename)) {
        werror("strings: %s: %s\n", filename, strerror(errno()));
        return 0;
    }
    Stdio.File infile = Stdio.File(filename);
    if (!infile) {
        werror("strings: %s: %s\n", filename, strerror(errno()));
        return 0;
    }
    string data = infile->read();
    infile->close();

    string current_string = "";
    array(string) found_strings = ({});

    foreach (data / 1, string s) {
        if (canprint(s[0]))
            current_string += s;
        else {
            if (strlen(current_string) >= length)
                found_strings += ({current_string});
            current_string = "";
        }
    }

    if (strlen(current_string) >= length)
        found_strings += ({current_string});

    foreach(found_strings, string s) 
        write(s + "\n");
    return 1;
}

int main(int argc, array(string) argv) {
    int length = 4;
    int i = 1;
    if (argc < 2)
        usage();
    if (argv[1] == "-n") {
        if (argc < 3)
            usage();
        Regexp re = Regexp("^[0-9]+$");
        if (!re->match(argv[2])) {
            werror("strings: length argument '%s' not a number\n", argv[2]);
            return 1;
        }
        length = (int)argv[2];
        i += 2;
    }
    if (length < 1) {
        werror("strings: invalid minimum string length '%d'\n", length);
        return 1;
    }
    int rc = 0;
    foreach (argv[i..], string filename) {
        if (!do_file(filename, length))
            rc = 1;
    }
    return rc;
}
