#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

void usage() {
    werror("usage: what [-s] file...\n");
    exit(1);
}

int prefix_match(Stdio.FILE f) {
    string s = f->read(3);
    if (strlen(s) != 3)
        return 0;
    if (s != "(#)")
        return 0;
    return 1;
}

string read_ident(Stdio.FILE f) {
    array(int) term = ({ 0, '\n', '\\', '>', '"' });
    string id = "";
    int c;
  
    while ((c = f->getchar()) != -1) {
        foreach (term, int endval)
            if (c == endval)
                return id;

        id += String.int2char(c);
    }
    return id;
}

int main(int argc, array(string) argv) {
    if (argc < 2)
        usage();
    int sflag = 0;
    if (argv[1] == "-s") {
        if (argc == 2)
            usage();
        sflag = 1;
        argv[1] = 0;
    }
    foreach (argv[1..], string filename) {
        if (!stringp(filename)) // poisoned arg
            continue;
        if (!access(filename, "r")) {
            werror("what: %s: %s\n", filename, strerror(errno()));
            exit(1);
        }
        Stdio.FILE f = Stdio.FILE(filename);
        write("%s:\n", filename);
        int filematch = 0;
        int c;
        while ((c = f->getchar()) != -1) {
            if (c != '@')
                continue;
            if (!prefix_match(f))
                continue;
            string id = read_ident(f);
            if (strlen(id) == 0)
                continue;
            filematch++;
            write("\t%s\n", id);
            if (sflag && filematch == 1)
                break;
        }
        f->close();
    }
    return 0;
}
