#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

string wordlist = "/usr/share/dict/words";
array(string) words = ({ });

int readlist(string path) {
    if (!access(path))
        return 0;
    Stdio.FILE f = Stdio.FILE(path);
    if (!f)
        return 0;

    // filter "thing's" and "Adam"
    Regexp re = Regexp("[^a-z]");
    string line;
    while ((line = f->gets())) {
        if (strlen(line) != 5)
            continue;
        if (re.match(line))
            continue;
        words += ({ line });
    }
    f->close();
    if (sizeof(words) < 2) {
        werror("failed to select >1 valid dictionary words\n");
        return 0;
    }
    return 1;
}

string getword() {
   int lim = sizeof(words);
   int idx = random(lim);
   return words[idx];
}

int spellcheck(string word) {
    word = lower_case(word);
    for (int i = 0; i < sizeof(words); i++)
        if (words[i] == word)
            return 1;

    return 0;
}

string nextguess() {
    write("Guess: ");
    string s = Stdio.stdin->gets();
    Regexp re = Regexp("[^A-Za-z]");
    if (strlen(s) != 5 || re.match(s)) {
        werror("Invalid guess.\n");
        return 0;
    }
    if (!spellcheck(s)) {
        werror("'%s' not found in dictionary.\n", s);
        return 0;
    }
    return upper_case(s);
}

int main(int argc, array(string) argv) {
    string path = wordlist;
    if (argc > 1)
        path = argv[1]; // extra args ignored
    if (!readlist(path)) {
        werror("%s: bail...\n", path);
        return 1;
    }
    mapping lcount = ([ ]);
    string word = upper_case(getword());
    write("I have a 5-letter word for you.\n");

    for (int i = 0; i < 6; i++) {
        string guess;
        while (!stringp(guess))
            guess = nextguess();
        if (i == 0)
            write(" *: exact match\t\t!: letter matches elsewhere\n");

        array(int) exactly = ({ 0 }) * 5;
        array(string) wordlet = word / 1;
        for (int j = 0; j < 5; j++)
            if (guess[j] == word[j]) {
                exactly[j] = 1;
                wordlet[j] = " ";
            }
 
        string tmpword = Array.sum(wordlet);
        array(int) partly = ({ 0 }) * 5;
        for (int j = 0; j < 5; j++) {
            if (exactly[j])
                continue;
            int k = search(tmpword, guess[j..j]);
            if (k < 0)
               continue;
            partly[j] = 1;
            wordlet[k] = " ";
            tmpword = Array.sum(wordlet);
        }

        write("\t");
        for (int j = 0; j < 5; j++) {
            string prefix = "";
            if (exactly[j])
                prefix = "*";
            else if (partly[j])
                prefix = "!";
            write(" %1s%1s", prefix, guess[j..j]);
        }
        write("\n");

        if (guess == word) {
            write("You win!\n");
            return 0;
        }
    }

    write("Try again. The word was %s\n", word);
    return 0;
}
