#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

int is_number(string arg) {
    if (strlen(arg) == 0)
        return 0;
    int isneg = 0;
    if (arg[0] == '+' || arg[0] == '-') {
        isneg = arg[0] == '-';
        arg = arg[1..];
    }
    Regexp digits = Regexp("^([0-9]+)");
    array(string) wholepart = digits->split(arg);
    if (!arrayp(wholepart))
        return 0; // initial digits are required
    int i = strlen(wholepart[0]);
    arg = arg[i..];
    if (strlen(arg) == 0)
        return 1; // saw +1

    array(string) fraction;
    if (arg[0] == '.') {
        arg = arg[1..];
        if (strlen(arg) == 0)
            return 1; // saw +1.
        fraction = digits->split(arg);
        if (arrayp(fraction)) {
            i = strlen(fraction[0]);
            arg = arg[i..];
            if (strlen(arg) == 0)
                return 1; // saw +1.2
        }
    }

    int isneg_exp = 0;
    if (arg[0] == 'e' || arg[0] == 'E') {
        arg = arg[1..];
        if (strlen(arg) == 0)
            return 0; // +1.2e invalid
        if (arg[0] == '+' || arg[0] == '-') {
            isneg_exp = arg[0] == '-';
            arg = arg[1..];
            if (strlen(arg) == 0)
                return 0; // +1.2e- invalid
        }
        array(string) edigits = digits->split(arg);
        if (!arrayp(edigits))
            return 0;
        i = strlen(edigits[0]);
        arg = arg[i..];
    }

    return strlen(arg) == 0 ? 1 : 0;
}

int main(int argc, array(string) argv) {
    float first = 1.0;
    float last;
    float incr;
    float cur;
    float prev;
    int step;

    if (argc == 2) {
        if (!is_number(argv[1])) {
            werror("invalid last number: '%s'\n", argv[1]);
            return 1;
        }
        last = (float)argv[1];
    } else if (argc == 3) {
        if (!is_number(argv[1])) {
            werror("invalid first number: '%s'\n", argv[1]);
            return 1;
        }
        first = (float)argv[1];
        if (!is_number(argv[2])) {
            werror("invalid last number: '%s'\n", argv[2]);
            return 1;
        }
        last = (float)argv[2];
    } else if (argc == 4) {
        if (!is_number(argv[1])) {
            werror("invalid first number: '%s'\n", argv[1]);
            return 1;
        }
        first = (float)argv[1];
        if (!is_number(argv[2])) {
            werror("invalid increment number: '%s'\n", argv[2]);
            return 1;
        }
        incr = (float)argv[2];
        if (!is_number(argv[3])) {
            werror("invalid last number: '%s'\n", argv[3]);
            return 1;
        }
        last = (float)argv[3];
    } else
        usage();

    if (floatp(incr)) {
        if (incr <= 0.0 && first < last) {
            werror("needs positive increment\n");
            return 1;
        }
        if (incr >= 0.0 && first > last) {
            werror("needs negative decrement\n");
            return 1;
        }
    } else
        incr = (first < last) ? 1.0 : -1.0;

    for (step = 1, cur = first; incr > 0 ? cur <= last : cur >= last;
      cur = first + incr * step++) {
        write("%g\n", cur);
        prev = cur;
    }
    return 0;
}

void usage() {
    werror("usage: seq [first [incr]] last\n");
    exit(1);
}
