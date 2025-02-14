#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

string make_secret(int length) {
    array(string) digits = Array.shuffle(({
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
    }));
    int i = length - 1;
    return Array.sum(digits[..i]);
}

string prompt(int length) {
    string guess = "";
    Regexp re = Regexp("^[0-9]+$");
    for (;;) {
        write("Enter your guess (" + length + " unique digits): ");
        guess = Stdio.stdin->gets();
        guess = String.trim_whites(guess);
        if (!re->match(guess)) {
            write("Not a number\n");
            continue;
        }
        if (strlen(guess) != length) {
            write("Number must be %d digits long\n", length);
            continue;
        }
        if (has_duplicates(guess)) {
            write("Digits in number must be unique\n");
            continue;
        }
        break;
    }
    return guess;
}

int has_duplicates(string s) {
    mapping seen = ([ ]);
    foreach (s / 1, string c) {
        if (seen[c])
            return 1;
        seen[c] = 1;
    }
    return 0;
}

array(int) cow_n_bull(string secret, string guess) {
    int bulls = 0, cows = 0;
    for (int i = 0; i < strlen(secret); i++)
        if (secret[i] == guess[i]) 
            bulls++;
        else if (search(secret, guess[i..i]) != -1)
            cows++; // no need to ignore exact match; digits are unique

    return ({ cows, bulls });
}

void usage() {
    werror("usage: moo [length]\n");
    exit(1);
}

int main(int argc, array(string) argv) {
    int length = 4;
    if (argc > 2)
        usage();
    if (argc > 1) {
        Regexp re = Regexp("^[0-9]+$");
        if (!re->match(argv[1])) {
            werror("length must be an integer\n");
            return 1;
        }
        length = (int)argv[1];
    }
    if (length < 2 || length > 10) {
        werror("length must be within range 2-10\n");
        return 1;
    }
    string secret = make_secret(length);
    write("Moo to you! Try to guess my secret number too.\n");

    for (int i = 1;; i++) {
        string guess = prompt(length);
        array(int) result = cow_n_bull(secret, guess);
        int cows = result[0];
        int bulls = result[1];
        write(sprintf("Bulls: %d, Cows: %d\n", bulls, cows));
        
        if (bulls == length) { 
            write("Great! You guessed it in %d attempts\n", i);
            break;
        }
        write("Try again!\n");
    }
    return 0;
}
