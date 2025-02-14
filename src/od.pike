#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

array(string) octet_octal = ({
    "000", "001", "002", "003", "004", "005", "006", "007", 
    "010", "011", "012", "013", "014", "015", "016", "017", 
    "020", "021", "022", "023", "024", "025", "026", "027", 
    "030", "031", "032", "033", "034", "035", "036", "037", 
    "040", "041", "042", "043", "044", "045", "046", "047", 
    "050", "051", "052", "053", "054", "055", "056", "057", 
    "060", "061", "062", "063", "064", "065", "066", "067", 
    "070", "071", "072", "073", "074", "075", "076", "077", 
    "100", "101", "102", "103", "104", "105", "106", "107", 
    "110", "111", "112", "113", "114", "115", "116", "117", 
    "120", "121", "122", "123", "124", "125", "126", "127", 
    "130", "131", "132", "133", "134", "135", "136", "137", 
    "140", "141", "142", "143", "144", "145", "146", "147", 
    "150", "151", "152", "153", "154", "155", "156", "157", 
    "160", "161", "162", "163", "164", "165", "166", "167", 
    "170", "171", "172", "173", "174", "175", "176", "177", 
    "200", "201", "202", "203", "204", "205", "206", "207", 
    "210", "211", "212", "213", "214", "215", "216", "217", 
    "220", "221", "222", "223", "224", "225", "226", "227", 
    "230", "231", "232", "233", "234", "235", "236", "237", 
    "240", "241", "242", "243", "244", "245", "246", "247", 
    "250", "251", "252", "253", "254", "255", "256", "257", 
    "260", "261", "262", "263", "264", "265", "266", "267", 
    "270", "271", "272", "273", "274", "275", "276", "277", 
    "300", "301", "302", "303", "304", "305", "306", "307", 
    "310", "311", "312", "313", "314", "315", "316", "317", 
    "320", "321", "322", "323", "324", "325", "326", "327", 
    "330", "331", "332", "333", "334", "335", "336", "337", 
    "340", "341", "342", "343", "344", "345", "346", "347", 
    "350", "351", "352", "353", "354", "355", "356", "357", 
    "360", "361", "362", "363", "364", "365", "366", "367", 
    "370", "371", "372", "373", "374", "375", "376", "377" 
});

array(string) ascname = ({
    "nul", "soh", "stx", "etx", "eot", "enq", "ack", "bel",
    " bs", " ht", " nl", " vt", " ff", " cr", " so", " si",
    "dle", "dc1", "dc2", "dc3", "dc4", "nak", "syn", "etb",
    "can", " em", "sub", "esc", " fs", " gs", " rs", " us",
    " sp",     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0,     0,
        0,     0,     0,     0,     0,     0,     0, "del"
});

array(string) cescape = ({
    " \\0", 0, 0, 0, 0, 0, 0, " \\a", " \\b", " \\t",
    " \\n"," \\v", " \\f", " \\r"
});

string to_cescape(string data) {
    int len = strlen(data);
    int esclen = sizeof(cescape);
    string s = "";
    for (int i = 0; i < len; i++) {
        int j = data[i];
        s += " ";
        if (j < esclen && cescape[j]) {
            s += cescape[j];
        } else if (j >= 32 && j <= 126) {
            s += "  " + data[i..i];
        } else {
            s += octet_octal[j];
        } 
    }
    return s;
}

string to_ascname(string data) {
    int len = strlen(data);
    string s = "";
    for (int i = 0; i < len; i++) {
        int j = data[i] & 0x7f; // 7bit code
        string c;
        if (ascname[j])
            c = ascname[j];
        else
            c = "  " + int2char(j);
        s += " ";
        s += c;
    }
    return s;
}

string to_d2(string data) {
    int len = strlen(data);
    data += "\0"; // pad16
    string s = "";
    for (int i = 0; i < len; i += 2) {
        int j = data[i] << 8;
        j |= data[i + 1];
        j = Int.swap_word(j); // use byteorder
        if (j > 0x7fff) {
            j -= 0x10000;
        }
        s += sprintf(" %6d", j);
    }
    return s;
}

string to_u2(string data) {
    int len = strlen(data);
    data += "\0"; // pad16
    string s = "";
    for (int i = 0; i < len; i += 2) {
        int j = data[i] << 8;
        j |= data[i + 1];
        j = Int.swap_word(j);
        s += sprintf(" %5u", j);
    }
    return s;
}

string to_hex4(string data) {
    int len = strlen(data);
    data += "\0\0\0"; // pad32
    string s = "";
    for (int i = 0; i < len; i += 4) {
        int j = data[i] << 8;
        j |= data[i + 1];
        int k = data[i + 2] << 8;
        k |= data[i + 3];
        int x = j << 16 | k;
        x = Int.swap_long(x);
        s += sprintf(" %08x", x);
    }
    return s;
}

string to_octal4(string data) {
    int len = strlen(data);
    data += "\0\0\0"; // pad32
    string s = "";
    for (int i = 0; i < len; i += 4) {
        int j = data[i] << 8;
        j |= data[i + 1];
        int k = data[i + 2] << 8;
        k |= data[i + 3];
        int x = j << 16 | k;
        x = Int.swap_long(x);
        s += sprintf(" %011o", x);
    }
    return s;
}

string to_hex2(string data) {
    int len = strlen(data);
    data += "\0"; // pad16
    string s = "";
    for (int i = 0; i < len; i += 2) {
        int j = data[i] << 8;
        j |= data[i + 1];
        j = Int.swap_word(j);
        s += sprintf(" %04x", j);
    }
    return s;
}

string to_octal2(string data) {
    int len = strlen(data);
    data += "\0"; // pad16
    string s = "";
    for (int i = 0; i < len; i += 2) {
        int j = data[i] << 8;
        j |= data[i + 1];
        j = Int.swap_word(j);
        s += sprintf(" %06o", j);
    }
    return s;
}

string to_octal1(string data) {
    int len = strlen(data);
    string s = "";
    for (int i = 0; i < len; i++) {
        int j = data[i];
        s += " ";
        s += octet_octal[j];
    }
    return s;
}

string to_hex1(string data) {
    string hex = String.string2hex(data);
    string s = "";
    foreach (hex / 2, string octet) {
        s += " ";
        s += octet;
    }
    return s;
}

string to_d1(string data) {
    int len = strlen(data);
    string s = "";
    for (int i = 0; i < len; i++) {
        int j = data[i];
        if (j > 127)
            j -= 256; 
        s += sprintf(" %4d", j);
    }
    return s;
}

string to_u1(string data) {
    int len = strlen(data);
    string s = "";
    for (int i = 0; i < len; i++) {
        s += sprintf(" %3d", data[i]);
    }
    return s;
}

int format_file(Stdio.File f, int offset, string fmt) {
    int chunk_size = 16;
    while (1) {
        string data = f->read(chunk_size);
        int len = strlen(data);
        if (len == 0)
            break;
        write("%08o", offset);
        switch (fmt) {
        case "a":
            write(to_ascname(data));
            break;
        case "c":
            write(to_cescape(data));
            break;
        case "d1":
            write(to_d1(data));
            break;
        case "d2":
            write(to_d2(data));
            break;
        case "o1":
            write(to_octal1(data));
            break;
        case "o2":
            write(to_octal2(data));
            break;
        case "o4":
            write(to_octal4(data));
            break;
        case "u1":
            write(to_u1(data));
            break;
        case "u2":
            write(to_u2(data));
            break;
        case "x1":
            write(to_hex1(data));
            break;
        case "x2":
            write(to_hex2(data));
            break;
        case "x4":
            write(to_hex4(data));
            break;
        default:
            werror("invalid fmt: %s\n", fmt);
            exit(1);
        }
        
        write("\n");
        offset += len;
    }
    write("%08o\n", offset);
    return offset;
}

string valid_format(string s) {
    if (strlen(s) == 0)
        return 0;
    array(string) fmt = ({ "a", "c", "d1", "d2", "o1", "o2", "o4", "u1",
        "u2", "x1", "x2", "x4" });
    foreach (fmt, string f) {
        if (s == f)
            return s;
    }
    return 0;
}

int main(int argc, array(string) argv) {
    if (argc < 2)
        usage();
    string format = "o2";

    for (int i = 1; i < argc; i++) {
        if (!stringp(argv[i]))
            continue;
        string arg = argv[i];
        if (arg[0] != '-')
            break;
        if (arg == "--") {
            argv[0] = 0;
            break;
        }
        switch (arg) {
        case "-a":
            format = "a";
            break;
        case "-B":
        case "-o":
            format = "o2";
            break;
        case "-b":
            format = "o1";
            break;
        case "-c":
            format = "c";
            break;
        case "-D":
            format = "u4";
            break;
        case "-d":
            format = "u2";
            break;
        case "-O":
            format = "o4";
            break;
        case "-h":
        case "-x":
            format = "x2";
            break;
        case "-H":
        case "-X":
            format = "x4";
            break;
        case "-i":
        case "-s":
            format = "d2";
            break;
        case "-t":
            if (i + 1 == argc)
                usage();
            format = valid_format(argv[i + 1]);
            if (!format) {
                werror("invalid format specifier\n");
                usage();
            }
            argv[i + 1] = 0;
            break;
        default:
            werror("invalid option: '%s'\n", arg);
            usage();
        }
        argv[i] = 0;
    }

    int offset = 0;
    int rc = 0;
    foreach (argv[1..], string filename) {
        if (!stringp(filename)) // poisoned arg
            continue;
        if (!access(filename, "r")) {
            werror("od: %s: %s\n", filename, strerror(errno()));
            rc = 1;
            continue;
        }
        Stdio.File file = Stdio.File(filename);
        offset = format_file(file, offset, format);
        file->close();
    }
    return rc;
}

void usage() {
    werror("usage: od [-aBbcDdHhiOosXx] [-t type] file...\n");
    exit(1);
}
