#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)

array(string) valid_alg = ({
    "gost94", "md2", "md4", "md5", "ripemd160", "sha1", "sha224", "sha256",
    "sha384", "sha512", "sha3-224", "sha3-256", "sha3-384", "sha3-512"
});

void usage() {
   write("usage: sum algorithms file ...\n");
   exit(1);
}

int is_valid_alg(string a) {
    foreach (valid_alg, string supported)
        if (a == supported)
            return 1;

    return 0;
}

int hash_a_file(string algname, string path) {
    if (!access(path)) {
        werror("sum: %s: %s\n", path, strerror(errno()));
        return 0;
    }
    Stdio.FILE f = Stdio.FILE(path);
    if (!f) {
        werror("sum: %s: %s\n", path, strerror(errno()));
        return 0;
    }
    string digest;
    switch (algname) {
    case "gost94":
        digest = Crypto.GOST94.hash(f);
        break;
    case "md2":
        digest = Crypto.MD2.hash(f);
        break;
    case "md4":
        digest = Crypto.MD4.hash(f);
        break;
    case "md5":
        digest = Crypto.MD5.hash(f);
        break;
    case "ripemd160":
        digest = Crypto.RIPEMD160.hash(f);
        break;
    case "sha1":
        digest = Crypto.SHA1.hash(f);
        break;
    case "sha224":
        digest = Crypto.SHA224.hash(f);
        break;
    case "sha256":
        digest = Crypto.SHA256.hash(f);
        break;
    case "sha384":
        digest = Crypto.SHA384.hash(f);
        break;
    case "sha512":
        digest = Crypto.SHA512.hash(f);
        break;
    case "sha3-224":
        digest = Crypto.SHA3_224.hash(f);
        break;
    case "sha3-256":
        digest = Crypto.SHA3_256.hash(f);
        break;
    case "sha3-384":
        digest = Crypto.SHA3_384.hash(f);
        break;
    case "sha3-512":
        digest = Crypto.SHA3_512.hash(f);
        break;
    default:
        werror("unknown algorithm\n");
        exit(1);
    }
    f->close();
    string hxstr = String.string2hex(digest);
    write("%s(%s)= %s\n", upper_case(algname), path, hxstr);
    return 1;
}

int main(int argc, array(string) argv) {
    if (argc < 3) {
        werror("sum: missing argument\n");
        usage();
    }
    array(string) algs = ({ });
    mapping algnames = ([ ]);
    if (argc > 1) {
        if (search(argv[1], ",") >= 0) {
            algs += argv[1] / ",";
        } else {
            algs += ({ argv[1] });
        }
    }
    foreach (algs, string a) {
        if (strlen(a) == 0) // redundant ,,,
            continue;
        if (!is_valid_alg(a)) {
            werror("sum: unexpected algorithm '%s'\n", a);
            werror("supported: %s\n", String.implode_nicely(valid_alg));
            return 1;
        }
        algnames[a] = 1; // redundant md4,md4
    }
    int rc = 0;
    foreach (argv[2..], string path) {
        foreach (valid_alg, string a) {
            if (!algnames[a])
                continue;
            if (!hash_a_file(a, path)) {
                rc = 1;
                break;
            }
        }
    }
    return rc;
}
