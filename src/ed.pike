#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

int naddr = 0;
int addr1 = 0;
int addr2 = 0;
int curln = 0;
int modified = 0;
int scripted = 0;
int helpmode = 0;
int promptmode = 0;
string curfile;
string warning;
string prompt = "*";
mapping marks = ([ ]);
array(string) lines = ({ "" });

array(string) lesc = ({
    "\\000", "\\001", "\\002", "\\003", "\\004", "\\005", "\\006", "\\a",
    "\\b",   "\\t",   "\$\n",  "\\v",   "\\f",   "\\r",   "\\016", "\\017",
    "\\020", "\\021", "\\022", "\\023", "\\024", "\\025", "\\026", "\\027",
    "\\030", "\\031", "\\032", "\\033", "\\034", "\\035", "\\036", "\\037",
    " ",     "!",     "\"",    "#",     "\\$",   "%",     "&",     "'",
    "(",     ")",     "*",     "+",     ",",     "-",     ".",     "/",
    "0",     "1",     "2",     "3",     "4",     "5",     "6",     "7",
    "8",     "9",     ":",     ";",     "<",     "=",     ">",     "?",
    "@",     "A",     "B",     "C",     "D",     "E",     "F",     "G",
    "H",     "I",     "J",     "K",     "L",     "M",     "N",     "O",
    "P",     "Q",     "R",     "S",     "T",     "U",     "V",     "W",
    "X",     "Y",     "Z",     "[",     "\\\\",  "]",     "^",     "_",
    "`",     "a",     "b",     "c",     "d",     "e",     "f",     "g",
    "h",     "i",     "j",     "k",     "l",     "m",     "n",     "o",
    "p",     "q",     "r",     "s",     "t",     "u",     "v",     "w",
    "x",     "y",     "z",     "{",     "|",     "}",     "~",     "\\177",
    "\\200", "\\201", "\\202", "\\203", "\\204", "\\205", "\\206", "\\207",
    "\\210", "\\211", "\\212", "\\213", "\\214", "\\215", "\\216", "\\217",
    "\\220", "\\221", "\\222", "\\223", "\\224", "\\225", "\\226", "\\227",
    "\\230", "\\231", "\\232", "\\233", "\\234", "\\235", "\\236", "\\237",
    "\\240", "\\241", "\\242", "\\243", "\\244", "\\245", "\\246", "\\247",
    "\\250", "\\251", "\\252", "\\253", "\\254", "\\255", "\\256", "\\257",
    "\\260", "\\261", "\\262", "\\263", "\\264", "\\265", "\\266", "\\267",
    "\\270", "\\271", "\\272", "\\273", "\\274", "\\275", "\\276", "\\277",
    "\\300", "\\301", "\\302", "\\303", "\\304", "\\305", "\\306", "\\307",
    "\\310", "\\311", "\\312", "\\313", "\\314", "\\315", "\\316", "\\317",
    "\\320", "\\321", "\\322", "\\323", "\\324", "\\325", "\\326", "\\327",
    "\\330", "\\331", "\\332", "\\333", "\\334", "\\335", "\\336", "\\337",
    "\\340", "\\341", "\\342", "\\343", "\\344", "\\345", "\\346", "\\347",
    "\\350", "\\351", "\\352", "\\353", "\\354", "\\355", "\\356", "\\357",
    "\\360", "\\361", "\\362", "\\363", "\\364", "\\365", "\\366", "\\367",
    "\\370", "\\371", "\\372", "\\373", "\\374", "\\375", "\\376", "\\377"
});

int maxline() {
    return sizeof(lines) - 1;
}

void alert(string msg) {
    warning = msg;
    werror("?\n");
    if (helpmode)
        werror(msg + "\n");
}

int editfile(string arg) {
    if (strlen(arg) > 0 && arg[0] != ' ') {
        alert("invalid command suffix");
        return 0;
    }
    arg = skip_blank(arg);
    int do_pipe = 0;
    if (strlen(arg) == 0) {
        if (!curfile) {
            alert("no current filename");
            return 0;
        }
        arg = curfile;
    } else if (arg[0] == '!') {
        do_pipe = 1;
        arg = arg[1..];
    }

    Stdio.FILE f;
    if (do_pipe) {
        f = Process.popen(arg, "r");
    } else {
        if (bad_filename(arg)) {
            alert("invalid filename");
            return 0;
        }
        if (!access(arg)) {
            alert("cannot open input file");
            return 0;
        }
        f = Stdio.FILE(arg);
        if (!f) {
            alert("cannot open input file");
            return 0;
        }
        curfile = arg;
    }
    string line;
    int chars = 0;
    lines = ({ 0 });
    do {
        line = f->gets();
        if (line) {
            lines += ({ line });
            chars += sizeof(line) + 1; // count nl
        }
    } while (line);
    f->close();

    modified = 0;
    curln = maxline();
    if (!scripted)
        write("%d\n", chars);
    return 1;
}

int bad_filename(string name) {
    if (strlen(name) == 0)
        return 1;
    if (name[0] == '!')
        return 1;
    if (name[-1] == '/')
        return 1;
    if (name == "." || name == "..")
        return 1;
    return 0;
}

int readin(string arg) {
    if (strlen(arg) > 0 && arg[0] != ' ') {
        alert("invalid command suffix");
        return 0;
    }
    arg = skip_blank(arg);
    if (strlen(arg) == 0) {
        if (!curfile) {
            alert("no current filename");
            return 0;
        }
        arg = curfile;
    }

    int i;
    switch (naddr) {
    case 0:
        i = maxline();
        break;
    case 1:
        i = addr1;
        break;
    case 2:
        i = addr2;
    }

    Stdio.FILE f;
    if (arg[0] == '!') {
        f = Process.popen(arg[1..], "r");
    } else {
        if (bad_filename(arg)) {
            alert("invalid filename");
            return 0;
        }
        if (!access(arg, "r")) {
            alert("cannot open input file");
            return 0;
        }
        f = Stdio.FILE(arg);
        if (!f) {
            alert("cannot open input file");
            return 0;
        }

    }

    array(string) tmp = ({ });
    int chars = 0;
    string line;
    do {
        line = f->gets();
        if (line) {
            tmp += ({ line });
            chars += sizeof(line) + 1; // count nl
        }
    } while (line);
    f->close();
    if (sizeof(tmp) != 0) {
        int j = i + 1;
        lines = lines[0..i] + tmp + lines[j..];
        curln = i + sizeof(tmp);
        modified = 1;
    }
    if (!scripted)
        write("%d\n", chars);
    return 1;
}

int setfile(string arg) {
    if (strlen(arg) > 0 && arg[0] != ' ') {
        alert("invalid command suffix");
        return 0;
    }
    arg = skip_blank(arg);
    if (strlen(arg) == 0) {
        if (!curfile) {
            alert("no current filename");
            return 0;
        }
        write(curfile + "\n");
        return 1;
    }
    if (bad_filename(arg)) {
        alert("invalid filename");
        return 0;
    }
    curfile = arg;
    write(curfile + "\n");
    return 1;
}

int promptsw() {
    promptmode = !promptmode;
    return 1;
}

int helpsw() {
    helpmode = !helpmode;
    if (helpmode && warning)
        werror(warning + "\n");
    return 1;
}

int helpsay() {
    if (warning)
        werror(warning + "\n");
    return 1;
}

int addtext(int insert) {
    int i = select_one_addr();
    if (insert && i > 0)
        i--;

    int count = 0;
    string line;
    array(string) tmp = ({ });
    do {
        line = Stdio.stdin->gets();
        if (line == ".")
            break;
        tmp += ({ line });
        count++;
    } while (line);

    lines = lines[0..i] + tmp + lines[(i+1)..];
    modified = 1;
    curln = i + count;
    return 1;
}

int deltext() {
    int start, end;
    switch (naddr) {
    case 0:
        start = end = curln;
        break;
    case 1:
        start = end = addr1;
        break;
    case 2:
        start = addr1;
        end = addr2;
        break;
    }
    if (start == 0) {
        alert("invalid address");
        return 0;
    }
    int lowend = start - 1; // zero
    array(string) low = lines[0..lowend];

    int highstart = end + 1; // maxline
    int highend = maxline();
    array(string) high = lines[highstart..highend];

    lines = low + high;
    curln = min(start, maxline()); // start may be gone
    modified = 1;
    return 1;
}

int nullcmd() {
    int i = select_one_addr();
    if (i == 0) {
        alert("invalid address");
        return 0;
    }
    if (naddr == 0 && i++ == maxline()) {
        alert("invalid address");
        return 0;
    }
    curln = i;
    write(lines[curln] + "\n");
    return 1;
}

int joinup() {
    int start, end;
    if (naddr > 0 && addr1 == 0) {
        alert("invalid address");
        return 0;
    }
    switch (naddr) {
    case 0:
        if (curln == maxline()) {
            alert("invalid address");
            return 0;
        }
        start = curln;
        end = curln + 1;
        break;
    case 1:
        return 1;
    case 2:
        if (addr1 == addr2)
            return 1;
        start = addr1;
        end = addr2;
        break;
    }
    string line = Array.sum(lines[start..end]);
    int i = start - 1;
    int j = end + 1;
    lines = lines[0..i] + ({ line }) + lines[j..];
    curln = addr1;
    modified = 1;
    return 1;
}

int reveal(string arg, int shownum, int binmode) {
    while (strlen(arg) > 0) {
        switch (arg[0]) {
        case 'p':
            break;
        case 'n':
            shownum = 1;
            break;
        case 'l':
            binmode = 1;
            break;
        default:
            alert("invalid command suffix");
            return 0;
        }
        arg = arg[1..];
    }

    int start, end;
    switch (naddr) {
    case 0:
        start = end = curln;
        break;
    case 1:
        start = end = addr1;
        break;
    case 2:
        start = addr1;
        end = addr2;
        break;
    }
    if (start == 0) {
        alert("invalid address");
        return 0;
    }
    for (int i = start; i <= end; i++) {
        if (shownum)
            write("%d\t", i);
        if (binmode) {
            foreach (lines[i] / 1, string c)
                write(lesc[c[0]]);
            write(lesc['\n']);
        } else
            write(lines[i] + "\n");
    }
    curln = end;
    return 1;
}

int listaddr() {
    int i = select_one_addr();
    write("%d\n", i);
    return 1;
}

int select_one_addr() {
    switch (naddr) {
    case 0: return curln;
    case 1: return addr1;
    case 2: return addr2;
    }
    return -1;
}

int setmark(string letter) {
    if (strlen(letter) != 1 || letter[0] < 'a' || letter[0] > 'z') {
        alert("invalid command suffix");
        return 0;
    }
    int i = select_one_addr();
    if (i == 0) {
        alert("invalid address");
        return 0;
    }
    marks[letter] = i;
    return 1;
}

int writebuf(string arg, int appendmode) {
    int quitmode = 0;
    if (strlen(arg) > 0 && (arg[0] == 'q' || arg[0] == 'Q')) {
        quitmode = 1;
        arg = arg[1..];
    }
    if (strlen(arg) > 0 && arg[0] != ' ') {
        alert("invalid command suffix");
        return 0;
    }
    arg = skip_blank(arg);
    int do_pipe = 0;
    if (strlen(arg) == 0) {
        if (!curfile) {
            alert("no current filename");
            return 0;
        }
        arg = curfile;
    } else if (arg[0] == '!') {
        do_pipe = 1;
        arg = arg[1..];
    }

    int start, end;
    switch (naddr) {
    case 0:
        start = 1;
        end = maxline();
        break;
    case 1:
        start = end = addr1;
        break;
    case 2:
        start = addr1;
        end = addr2;
        break;
    }
    if (start == 0) {
        alert("invalid address");
        return 0;
    }
    Stdio.FILE f;
    if (do_pipe) {
        f = Process.popen(arg, "w");
        if (!f) {
            alert("cannot open pipe");
            return 0;
        }
    } else {
        if (bad_filename(arg)) {
            alert("invalid filename");
            return 0;
        }
        string modestr = appendmode ? "caw" : "ctw";
        f = Stdio.FILE(arg, modestr);
        if (!f) {
            alert("cannot open output file");
            return 0;
        }
    }
    int chars = 0;
    for (int i = start; i <= end; i++) {
        f->write(lines[i] + "\n");
        chars += strlen(lines[i]) + 1;
    }
    f->close();

    int written = end - start + 1;
    if (!do_pipe && written == sizeof(lines) - 1)
        modified = 0;
    if (!scripted)
        write("%d\n", chars);
    if (quitmode)
        exit(0); // err-exit
    return 1;
}

int quitme() {
    exit(0); // err-exit
}

int reptext() {
    if (!deltext())
        return 0;
    if (naddr == 2)
        naddr--; // low addr for insert
    return addtext(1);
}

int copyover(string arg, int delete) {
    int start, end, target;
    switch (naddr) {
    case 0:
        start = 1;
        end = maxline();
        break;
    case 1:
        start = end = addr1;
        break;
    case 2:
        start = addr1;
        end = addr2;
        break;
    }
    if (start == 0) {
        alert("invalid address");
        return 0;
    }
    target = -1;
    if (strlen(arg) > 0) {
        naddr = 0;
        string remain = getaddr(arg);
        if (!stringp(remain))
            return 0;
        if (strlen(remain) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        if (naddr != 0)
            target = addr1; // 0 is allowed
    }
    if (target == -1)
        target = curln;
    if (delete && target >= start && target < end) {
        alert("invalid destination"); // m forbids overlap
        return 0;
    }

    lines = lines[0..target]
        + lines[start..end]  + lines[(target+1)..];
    int count = end - start + 1;
    if (delete) {
        int st = (start < target) ? start : start + count;
        int i = st - 1;
        int j = st + count;
        lines = lines[0..i] + lines[j..];
    }
    curln = target + count;
    modified = 1;
    if (curln > maxline())
        curln = maxline();
    return 1;
}

int substitute(string cmd) {
    int start, end;
    switch (naddr) {
    case 0:
        start = end = curln;
        break;
    case 1:
        start = end = addr1;
        break;
    case 2:
        start = addr1;
        end = addr2;
    }
    if (start == 0) {
        alert("invalid address");
        return 0;
    }
    if (strlen(cmd) < 1 || cmd[0] != '/') {
        alert("invalid pattern");
        return 0;
    }
    int i, len;
    len = strlen(cmd);
    int escaped = 0;
    for (i = 1; i < len; i++) {
        if (cmd[i] == '\\') {
            escaped = 1;
            continue;
        }
        if (cmd[i] == '/') {
            if (escaped) {
               escaped = 0;
            } else {
                break;
            }
        }
    }
    if (i >= len) {
        alert("invalid pattern");
        return 0;
    }
    string part1 = cmd[1..(i-1)];
    cmd = cmd[(i+1)..];

    len = strlen(cmd);
    escaped = 0;
    for (i = 0; i < len; i++) {
        if (cmd[i] == '\\') {
            escaped = 1;
            continue;
        }
        if (cmd[i] == '/') {
            if (escaped) {
               escaped = 0;
            } else {
                break;
            }
        }
    }
    if (i >= len) {
        alert("invalid pattern");
        return 0;
    }
    string part2 = cmd[0..(i-1)];
    Regexp re = Regexp(part1);
    for (i = start; i <= end; i++) {
        string rep = re.replace(lines[i], part2);
        lines[i] = rep;
        modified = 1;
    }
    return 1;
}

int shellout(string cmd) {
    if (strlen(cmd) > 0) {
        string res = Process.popen(cmd);
        write(res);
    }
    write("!\n");
    return 1;
}

string getaddr(string cmd) {
    if (strlen(cmd) == 0)
        return cmd;
    int n = 0;
    int found = 0;
    if (cmd[0] == '.') {
        n = curln;
        found = 1;
        cmd = cmd[1..];
    } else if (cmd[0] == '$') {
        n = maxline();
        found = 1;
        cmd = cmd[1..];
    }
    if (!found && strlen(cmd) > 1) {
        if (cmd[0] == '\'') {
            if (cmd[1] < 'a' || cmd[1] > 'z') {
                alert("invalid mark character");
                return 0;
            }
            string lc = cmd[1..1];
            if (!marks[lc]) {
                alert("invalid address");
                return 0;
            }
            n = marks[lc];
            found = 1;
            cmd = cmd[2..];
        }
    }
    if (!found) {
        Regexp re = Regexp("^([0-9]+)");
        array(string) cap = re.split(cmd);
        if (cap) {
            n = (int)cap[0];
            found = 1;
            int len = strlen(cap[0]);
            cmd = cmd[len..];
        }
    }

    array(string) cap;
    do {
        Regexp re = Regexp("^([\+\-])([0-9]+)");
        cap = re.split(cmd);
        if (cap) {
            int offset = (int)cap[1];
            if (cap[0] == "-")
                offset = -offset;
            if (!found) {
                n = curln;
                found = 1;
            }
            n += offset;
            int len = strlen(cap[0]) + strlen(cap[1]);
            cmd = cmd[len..];
        }
    } while (cap);

    Regexp re = Regexp("^([\+\-]+)");
    cap = re.split(cmd);
    if (cap) {
        if (!found) {
            n = curln;
            found = 1;
        }
        foreach (cap[0] / 1, string c) {
            if (c == "-")
                n--;
            else
                n++;
        }
        int len = strlen(cap[0]);
        cmd = cmd[len..];
    }

    if (found) {
        if (n < 0 || n > maxline()) {
            alert("invalid address");
            return 0;
        }
        if (naddr == 0)
            addr1 = n;
        else if (naddr == 1)
            addr2 = n;
        else {
            alert("too many addresses");
            return 0;
        }
        naddr++;
    }

    return cmd;
}

string skip_blank(string s) {
    int len = strlen(s);
    int i;

    for (i = 0; i < len; i++)
       if (s[i] != ' ' && s[i] != '\t')
           break;
    if (i)
        return s[i..];
    return s;
}

int commandline(string cmd) {
    naddr = addr1 = addr2 = 0;
    cmd = skip_blank(cmd);
    cmd = getaddr(cmd);
    if (!stringp(cmd))
        return 0;
    if (strlen(cmd) > 0 && (cmd[0] == ',' || cmd[0] == ';' || cmd[0] == '%')) {
        if (naddr == 1 && cmd[0] == '%') {
            alert("unknown command");
            return 0;
        }
        int infer1 = 0;
        if (naddr == 0) {
            naddr = infer1 = 1;
            if (cmd[0] == ';')
                addr1 = curln;
            else
                addr1 = 1; // ,N and %N
        }
        cmd = getaddr(cmd[1..]);
        if (!stringp(cmd))
            return 0;
        if (infer1 && naddr == 1) {
            naddr = 2;
            addr2 = maxline();
        }
    }
    if (naddr == 2) {
        if (addr1 > addr2) {
            alert("invalid address");
            return 0;
        }
    }
    if (strlen(cmd) == 0) {
        nullcmd();
        return 1;
    }
    string command = cmd[0..0];
    cmd = cmd[1..];

    switch (command) {
    case "H":
        if (naddr != 0) {
            alert("invalid address");
            return 0;
        }
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        helpsw();
        break;
    case "h":
        if (naddr != 0) {
            alert("invalid address");
            return 0;
        }
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        helpsay();
        break;
    case "P":
        if (naddr != 0) {
            alert("invalid address");
            return 0;
        }
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        promptsw();
        break;
    case "=":
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        listaddr();
        break;
    case "k":
        setmark(cmd);
        break;
    case "Q":
    case "q":
        if (!scripted && modified && command == "q") {
            alert("buffer modified");
            modified = 0;
            return 0;
        }
        if (naddr != 0) {
            alert("invalid address");
            return 0;
        }
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        quitme();
        break;
    case "j":
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        joinup();
        break;
    case "f":
        if (naddr != 0) {
            alert("invalid address");
            return 0;
        }
        setfile(cmd);
        break;
    case "d":
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        deltext();
        break;
    case "a":
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        addtext(0);
        break;
    case "i":
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        addtext(1);
        break;
    case "c":
        if (strlen(skip_blank(cmd)) > 0) {
            alert("invalid command suffix");
            return 0;
        }
        reptext();
        break;
    case "t":
        copyover(cmd, 0);
        break;
    case "m":
        copyover(cmd, 1);
        break;
    case "W":
        writebuf(cmd, 1);
        break;
    case "w":
        writebuf(cmd, 0);
        break;
    case "r":
        readin(cmd);
        break;
    case "E":
    case "e":
        if (!scripted && modified && command == "e") {
            alert("buffer modified");
            modified = 0;
            return 0;
        }
        if (naddr != 0) {
            alert("unexpected address");
            return 0;
        }
        editfile(cmd);
        break;
    case "s":
        substitute(cmd);
        break;
    case "l":
    case "n":
    case "p":
        reveal(cmd, command == "n", command == "l");
        break;
    case "!":
        if (naddr != 0) {
            alert("unexpected address");
            return 0;
        }
        shellout(cmd);
        break;
    default:
        alert("unknown command");
        return 0;
    }
    return 1;
}

int main(int argc, array(string) argv) {
    for (int i = 1; i < argc; i++) {
        if (!stringp(argv[i]))
            continue;
        string a = argv[i];
        if (a[0] != '-')
            break;
        if (a == "--") {
            argv[i] = 0;
            break;
        }
        if (a == "-p") {
            if (i + 1 == argc)
                usage();
            promptmode = 1;
            prompt = argv[i + 1];
            argv[i + 1] = 0;
        } else if (a == "-s")
            scripted = 1;
        else {
            werror("unexpected option: '%s'\n", a);
            usage();
        }
        argv[i] = 0;
    }
    string file = 0;
    foreach (argv[1..], string arg) {
        if (!stringp(arg))
            continue;
        if (stringp(file))
            usage();
        file = arg;
    }
    if (stringp(file))
        editfile(" " + file);

    string cmd;
    do {
        if (promptmode)
            write(prompt);
        cmd = Stdio.stdin->gets();
        commandline(cmd);
    } while (cmd);
    return 0;
}

void usage() {
    werror("usage: ed [-s] [-p prompt] [file]\n");
    exit(1);
}
