#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

mapping parse_diff_cmd(string s) {
    int i = 0;
    Regexp num_re = Regexp("^([0-9]+)");
    Regexp cmd_re = Regexp("^[acd]");
    mapping hunk = ([ ]);
    array addr1 = num_re.split(s);
    if (!arrayp(addr1))
        return 0; // "foo"
    hunk["start"] = hunk["end"] = (int)addr1[0];
    i = strlen(addr1[0]);
    s = s[i..];
    if (strlen(s) == 0)
        return 0; // bare "123"
    if (s[0] == ',') {
        s = s[1..];
        if (strlen(s) == 0)
            return 0; //  "123,"
        array addr2 = num_re.split(s);
        if (!arrayp(addr2)) // "123,foo"
            return 0;
        hunk["end"] = (int)addr2[0];
        i = strlen(addr2[0]);
        s = s[i..];
    }
    if (!cmd_re.match(s))
        return 0; // bad verb: "1,2x"
    hunk["type"] = s[0..0];
    s = s[1..];
    if (strlen(s) == 0)
        return 0; // missing suffix: "1,2d"
    array addr3 = num_re.split(s);
    if (!arrayp(addr3))
        return 0; // "1,2aX"
    hunk["ostart"] = hunk["oend"] = (int)addr3[0];
    i = strlen(addr3[0]);
    s = s[i..];
    if (strlen(s) > 0) {
        if (s[0] != ',')
            return 0; // "1,2a3x"
        s = s[1..];
        if (strlen(s) == 0)
            return 0; // "1,2a3,"
        array addr4 = num_re.split(s);
        if (!arrayp(addr4))
            return 0; // "1,2a2,X"
        hunk["oend"] = (int)addr4[0];
        i = strlen(addr4[0]);
        s = s[i..];
    }
    if (strlen(s) > 0)
        return 0; // "1,2a3,4XXXXX"
    if (hunk["type"] != "d")
        hunk["olines"] = ({ });
    return hunk;
}

int main(int argc, array(string) argv) {
    if (argc != 3)
        usage();
    if (!access(argv[1], "r")) {
        werror("failed to access '%s': %s\n", argv[1], strerror(errno()));
        return 1;
    }
    Stdio.FILE orig = Stdio.FILE(argv[1]);
    if (!orig) {
        werror("failed to access '%s': %s\n", argv[1], strerror(errno()));
        return 1;
    }
    if (!access(argv[2], "r")) {
        werror("failed to access '%s': %s\n", argv[2], strerror(errno()));
        return 1;
    }
    Stdio.FILE patch = Stdio.FILE(argv[2]);
    if (!patch) {
        werror("failed to access '%s': %s\n", argv[22], strerror(errno()));
        return 1;
    }

    mapping cur_hunk;
    array hunks = ({ });
    string diffcmd;
    while ((diffcmd = patch->gets())) {
        mapping hunk = parse_diff_cmd(diffcmd);
        if (mappingp(hunk)) {
            cur_hunk = hunk;
            hunks += ({ hunk });
        } else if (diffcmd[0] == '<') {
            // discard
        } else if (diffcmd[0] == '>') {
            if (!mappingp(cur_hunk)) {
                werror("patch: '>' seen outside of hunk data\n");
                return 1;
            }
            if (cur_hunk["type"] == "d") {
                werror("patch: '>' seen for deletion\n");
                return 1;
            }
            cur_hunk["olines"] += ({ diffcmd[2..] });
        } else if (diffcmd == "---") {
            if (cur_hunk["type"] != "c") {
                werror("patch: '---' seen for incorrect hunk type\n");
                return 1;
            }
        } else {
            werror("patch: unexpected patch data: '%s'\n", diffcmd);
            return 1;
        }
    }
    patch->close();
    if (sizeof(hunks) == 0) {
        werror("patch: failed to identify any patch data\n");
        return 1;
    }

    string line;
    int hunk = 0;
    int i = 0;
    while ((line = orig->gets())) {
        i++;
        if (hunk < sizeof(hunks) && hunks[hunk]["type"] == "d") {
            int start = hunks[hunk]["start"];
            int end = hunks[hunk]["end"];
            if (end < i)
                hunk++; // XXX: deal with unsorted hunks
            if (i >= start && i <= end)
                continue;
        }
        if (hunk < sizeof(hunks) && hunks[hunk]["type"] == "a") {
            int j = max(hunks[hunk]["start"], hunks[hunk]["end"]);
            j++; // append after line i
            if (i == j) {
                foreach (hunks[hunk]["olines"], string oline) {
                    write("%s\n", oline);
                }
                hunk++;
            }
        }
        if (hunk < sizeof(hunks) && hunks[hunk]["type"] == "c") {
            int start = hunks[hunk]["start"];
            int end = hunks[hunk]["end"];
            if (i >= start && i <= end)
                continue;
            if (i == end + 1) {
                foreach (hunks[hunk]["olines"], string oline) {
                    write("%s\n", oline);
                }
                hunk++;
            }
        }

        write("%s\n", line);
    }

    orig->close();
    return 0;
}

void usage() {
    werror("usage: patch originalfile patchfile\n");
    exit(1);
}
