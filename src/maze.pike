#!/usr/bin/pike

// Copyright (c) 2025, Michael Mikonos (see LICENSE file)
// Based on the PerlPowerTools maze program by Rocco Caputo

// cannot use in switch-case if declared as int
#define MODE_DEPTH        0
#define MODE_BREADTH      1
#define MODE_RAND         2
#define MODE_RAND_SHALLOW 3
#define MODE_RAND_DEEP    4

#define MIN_WIDTH 2
#define MIN_HEIGHT 2

int R = 1;
int B = 2;
int L = 4;
int T = 8;

int in;
int width;
int height;
array maze = ({ });
array walk = ({ });

int test_width() {
    return width - 1;
}

int test_height() {
    return height - 1;
}

void init_maze() {
    for (int i = 0; i < height; i++) {
        array(int) row = ({ 0 }) * width;
        maze += ({ row }); // nest array
    }
}

int traverse(int mode) {
    int i = sizeof(walk);
    if (!i) {
        werror("nothing to traverse\n");
        exit(1);
    }
    switch (mode) {
    case MODE_DEPTH:
        return i - 1;
    case MODE_BREADTH:
        return 0;
    case MODE_RAND:
        return random(i);
    case MODE_RAND_SHALLOW:
        i /= 2;
        return random(i);
    case MODE_RAND_DEEP:
        i /= 2;
        return random(i) + i;
    default:
        werror("unknown traversal mode %d\n", mode);
        exit(1);
    }
}

void show_maze() {
    array cellbits = ({
        ({ "", "   ", "  +", "", "|", "", "", "", "  +" }),
        ({ "", "  |", "--+", "", "|", "", "", "", "--+" })
    });
    array(string) wallbits = ({ "", "|", "+" });

    write("+");
    for (int x = 0; x < width; x++)
        write(cellbits[x != in][T]);
    write("\n");

    array(int) walls = ({ R, B });
    foreach (maze, array row) {
        foreach (walls, int wall) {
            write(wallbits[wall]);
            foreach (row, int cell) {
                write(cellbits[!(cell & wall)][wall]);
            }
            write("\n");
        }
    }
}

void chop_walk(int i) {
    int len = sizeof(walk);
    if (len == 0)
        return;
    if (i <= -2 || i >= len) {
        werror("invalid array index for chop: %d\n", i);
        exit(1);
    }
    if (i == len - 1)
        i = -1;
    int j, k;
    switch (i) {
    case -1:
        j = len - 2;
        walk = walk[..j];
        break;
    case 0:
        walk = walk[1..];
        break;
    default:
        j = i - 1;
        k = i + 1;
        walk = walk[..j] + walk[k..];
    }
}

void walk_maze(int mode) {
    while (sizeof(walk) > 0) {
        int walk_idx = traverse(mode);
        int y = walk[walk_idx][0];
        int x = walk[walk_idx][1];
        array goodpaths = ({ });

        if (y && !maze[y - 1][x])
            goodpaths += ({ ({ T, B, y - 1, x }) });

        if (y < test_height() && !maze[y + 1][x])
            goodpaths += ({ ({ B, T, y + 1, x }) });

        if (x && !maze[y][x - 1])
            goodpaths += ({ ({ L, R, y, x - 1 }) });

        if (x < test_width() && !maze[y][x + 1])
            goodpaths += ({ ({ R, L, y, x + 1 }) });

        if (sizeof(goodpaths) == 0) {
            chop_walk(walk_idx);
            continue;
        }

        int path_idx = random(sizeof(goodpaths));
        int direction = goodpaths[path_idx][0];
        int c_direction = goodpaths[path_idx][1];
        int next_y = goodpaths[path_idx][2];
        int next_x = goodpaths[path_idx][3];

        maze[y][x] |= direction;
        maze[next_y][next_x] |= c_direction;

        if (sizeof(goodpaths) == 1)
            chop_walk(walk_idx);

        walk += ({ ({ next_y, next_x }) });
    }
}

void usage() {
    werror("usage: maze width height [type]\n");
    werror("valid type: depth breadth rand rand-deep rand-shallow\n");
    exit(1);
}

int main(int argc, array(string) argv) {
    if (argc < 3)
        usage();
    int mode = MODE_DEPTH;
    if (argc == 4) {
        switch (argv[3]) {
        case "depth":
            break;
        case "breadth":
            mode = MODE_BREADTH;
            break;
        case "rand":
            mode = MODE_RAND;
            break;
        case "rand-deep":
            mode = MODE_RAND_DEEP;
            break;
        case "rand-shallow":
            mode = MODE_RAND_SHALLOW;
            break;
        default:
            werror("invalid type: '%s'\n", argv[3]);
            usage();
        }
    }

    Regexp re = Regexp("^[0-9]+$");
    if (!re.match(argv[1])) {
        werror("width: expected an integer value\n");
        return 1;
    }
    width = (int)argv[1];
    if (width < MIN_WIDTH) {
        werror("width: value too small (minimum %d)\n", MIN_WIDTH);
        return 1;
    }
    if (!re.match(argv[2])) {
        werror("height: expected an integer value\n");
        return 1;
    }
    height = (int)argv[2];
    if (width < MIN_HEIGHT) {
        werror("height: value too small (minimum %d)\n", MIN_HEIGHT);
        return 1;
    }

    init_maze();
    in = random(width);
    walk += ({ ({0, in }) }); // nest array
    walk_maze(mode);
    maze[-1][random(width)] |= B;
    show_maze();
    return 0;
}
