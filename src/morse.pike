#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

mapping chartab = ([
    "0"  : "-----",   "1"  : ".----",   "2" : "..---",   "3"  : "...--",
    "4"  : "....-",   "5"  : ".....",   "6" : "-....",   "7"  : "--...",
    "8"  : "---..",   "9"  : "----.",   "a" : ".-",      "b"  : "-...",
    "c"  : "-.-.",    "d"  : "-..",     "e" : ".",       "f"  : "..-.",
    "g"  : "--.",     "h"  : "....",    "i" : "..",      "j"  : ".---",
    "k"  : "-.-",     "l"  : ".-..",    "m" : "--",      "n"  : "-.",
    "o"  : "---",     "p"  : ".--.",    "q" : "--.-",    "r"  : ".-.",
    "s"  : "...",     "t"  : "-",       "u" : "..-",     "v"  : "...-",
    "w"  : ".--",     "x"  : "-..-",    "y" : "-.--",    "z"  : "--..",

    "."  : ".-.-.-",  ","  : "--..--",  ":"  : "---...", "?"  : "..--..",
    "'"  : ".----.",  "-"  : "-....-",  "/"  : "-..-.",  "("  : "-.--.-",
    ")"  : "-.--.-",  "\"" : ".-..-.",  "="  : "-...-",  ";"  : "-.-.-.",
    "+"  : ".-.-.", 
]);

string widen(string dots) {
    string str = "";
    foreach (dots / 1, string c) {
        if (c == ".")
            str += " dit";
        else if (c == "-")
            str +=  " daw";
        else {
            werror("invalid short morse string: '%s'\n", dots);
            exit(1);
        }
    }
    return str;
}

void encode_word(string word, int shortmode) {
    word = lower_case(word);
    foreach (word / 1, string c) {
        string mors = chartab[c];
        if (!stringp(mors)) {
            write("x");
            continue;
        }
        if (shortmode)
            write("%s\n", mors);
        else
            write("%s\n", widen(mors));
    }
    write("\n");
}

array(string) line_words(string line) {
    array(string) words = ({ });
    int len = strlen(line);
    if (len == 0)
        return words;
    int in_space = 0;
    string squash = "";
    Regexp sp = Regexp("[ \t]");
    foreach (line / 1, string c) {
        if (sp.match(c)) {
            if (!in_space)
                squash += " ";
            in_space = 1;
        } else {
            in_space = 0;
            squash += c;
        }
    }
    foreach (squash / " ", string word) {
        if (strlen(word) == 0)
            continue;
        words += ({ word });
    }
    return words;
}

int main(int argc, array(string) argv) {
    int shortmode = 0;
    int filemode = 0;
    for (int i = 1; i < argc; i++) {
        if (argv[i] == "--") {
            argv[i] = 0;
            break;
        }
        if (argv[i][0] != '-')
            break; // non-option

        if (argv[i] == "-s")
            shortmode = 1;
        else if (argv[i] == "-f")
            filemode = 1;
        else {
            werror("unexpected option: '%s'\n", argv[i]);
            usage();
        }
        argv[i] = 0;
    }

    if (!filemode) {
        int i = 0;
        foreach (argv[1..], string word) {
            if (!stringp(word))
                continue;
            encode_word(word, shortmode);
            i++;
        }
        if (i == 0)
            usage();
        return 0;
    }

    string file;
    foreach (argv[1..], string path) {
        if (!stringp(path))
            continue;
        if (stringp(file)) {
            werror("extra file argument: '%s'\n", path);
            return 1;
        }
        file = path;
    }
    if (!stringp(file)) {
        werror("missing file argument\n");
        usage();
    }
    if (!access(file, "r")) {
        werror("failed to access '%s': %s\n", file, strerror(errno()));
        return 1;
    }
    Stdio.FILE fh = Stdio.FILE(file);
    if (!fh) {
        werror("failed to access '%s': %s\n", file, strerror(errno()));
        return 1;
    }
    string line;
    while ((line = fh->gets())) {
        array(string) words = line_words(line);
        foreach (words, string word)
            encode_word(word, shortmode);
    }
    fh->close();
    return 0;
}

void usage() {
    werror("usage: morse [-s] words ...\n");
    werror("       morse [-s] -f file\n");
    exit(1);
}
