#!/usr/bin/env python3
"""
Generate Vim practice challenges.

Single challenge (for :VimRandom):
    python3 generate.py .tmp/random

Batch — repopulate the challenges/ directory:
    python3 generate.py --batch 20 challenges/
"""

import argparse
import random
import shutil
import sys
from pathlib import Path
from textwrap import dedent

# ── name pools ────────────────────────────────────────────────────────────────

PARAMS = ['user', 'item', 'record', 'entry', 'config', 'result', 'payload',
          'response', 'request', 'event', 'node', 'context', 'options', 'data']
VERBS  = ['process', 'transform', 'validate', 'parse', 'format', 'filter',
          'handle', 'fetch', 'load', 'save', 'update', 'compute', 'normalize',
          'prepare', 'serialize', 'enrich', 'dispatch', 'apply', 'merge']
FIELDS = ['id', 'name', 'type', 'status', 'value', 'count', 'label',
          'key', 'tag', 'role', 'size', 'mode', 'level', 'score', 'active',
          'enabled', 'visible', 'index', 'order', 'priority']

def _pick(pool, exclude=()):
    return random.choice([x for x in pool if x not in exclude])

def _sample(pool, n, exclude=()):
    candidates = [x for x in pool if x not in exclude]
    return random.sample(candidates, n)

# ── challenge generators ──────────────────────────────────────────────────────
# Each returns (start, target, description, optimal_keys, [solution_strings], slug)

def rename_all():
    """Rename an identifier appearing 6 times — cgn + dot-repeat or :%s."""
    old, new     = _sample(PARAMS, 2)
    fn           = _pick(VERBS)
    f1, f2       = _sample(FIELDS, 2)
    v1, v2       = _sample(VERBS, 2, exclude=(fn,))

    start = dedent(f"""\
        function {fn}({old}) {{
          if (!{old}) {{
            throw new Error('missing {old}');
          }}
          const {f1} = {v1}({old}.{f1});
          {v2}({old}.{f2}, {f1});
          return {old}.{f2};
        }}""")

    target = start.replace(old, new)

    cgn_keys = (1 + len(old) + 1) + (3 + len(new) + 1) + 5
    sub_keys = 6 + len(old) + 3 + len(new) + 4
    optimal  = min(cgn_keys, sub_keys)

    return (start, target,
            f'Rename "{old}" to "{new}" — 6 occurrences',
            optimal,
            [f'/{old}<CR>cgn{new}<Esc>.....  —  cgn + dot-repeat for all 6',
             f':%s/\\b{old}\\b/{new}/g<CR>  —  word-boundary substitution'],
            'rename_all')


def for_to_map():
    """4-line for-of/push loop → single .map() call."""
    item = _pick(PARAMS)
    coll = _pick(PARAMS, exclude=(item,)) + 's'
    fn   = _pick(VERBS)
    out  = _pick(['results', 'output', 'mapped'], exclude=(coll,))

    start = dedent(f"""\
        const {out} = [];
        for (const {item} of {coll}) {{
          {out}.push({fn}({item}));
        }}""")

    target = f"const {out} = {coll}.map({item} => {fn}({item}));"

    optimal = 4 + len(target) + 1  # ggcG + content + Esc

    return (start, target,
            'Convert the for-of/push loop to a .map() one-liner',
            optimal,
            [f'ggcG{target}<Esc>  —  cG changes from line 1 to end of file'],
            'for_to_map')


def early_return():
    """Invert if-guard, remove nesting — early return pattern."""
    param       = _pick(PARAMS)
    fn          = _pick(VERBS)
    v1, v2, v3  = _sample(VERBS, 3, exclude=(fn,))

    start = dedent(f"""\
        function {fn}({param}) {{
          if ({param} !== null) {{
            {v1}({param});
            {v2}({param});
            {v3}({param});
          }}
        }}""")

    target = dedent(f"""\
        function {fn}({param}) {{
          if ({param} === null) return;
          {v1}({param});
          {v2}({param});
          {v3}({param});
        }}""")

    return (start, target,
            'Convert the if-block to an early return (invert condition, dedent, remove closing brace)',
            39,
            ['2Gf!c$=== null) return;<Esc>  —  rewrite condition line',
             'then  j<<j<<j<<  —  dedent the three body lines',
             'then  /  }<CR>dd  —  delete the if closing brace'],
            'early_return')


def destructure():
    """Three prop-access assignments → one destructuring."""
    obj         = _pick(PARAMS)
    f1, f2, f3  = _sample(FIELDS, 3)

    start = dedent(f"""\
        const {f1} = {obj}.{f1};
        const {f2} = {obj}.{f2};
        const {f3} = {obj}.{f3};""")

    target = f"const {{ {f1}, {f2}, {f3} }} = {obj};"

    optimal = 4 + len(target) + 1  # ggcG + content + Esc

    return (start, target,
            f'Collapse the three `{obj}.*` assignments into one destructuring',
            optimal,
            [f'ggcG{target}<Esc>  —  cG replaces all three lines at once'],
            'destructure')


def template_literal():
    """String concatenation → template literal."""
    v1, v2 = _sample(PARAMS, 2)
    noun   = _pick(['message', 'greeting', 'summary', 'title', 'output'])
    word1  = _pick(['Hello', 'Hi', 'Welcome', 'Hey'])
    mid    = _pick(['you have', 'there are', 'found', 'loaded'])
    unit   = _pick(['items', 'results', 'records', 'entries'])

    start  = f"const {noun} = '{word1}, ' + {v1} + '! {mid.capitalize()} ' + {v2} + ' {unit}.';"
    rhs    = f"`{word1}, ${{{v1}}}! {mid.capitalize()} ${{{v2}}} {unit}.`"
    target = f"const {noun} = {rhs};"

    optimal = 3 + len(rhs) + 1  # f=lc$ + rhs + Esc

    return (start, target,
            'Rewrite the string concatenation as a template literal',
            optimal,
            [f'f=lc${rhs}<Esc>  —  f= finds =, l skips space, c$ rewrites the RHS'],
            'template_literal')


def reorder_fields():
    """Sort object literal fields alphabetically."""
    obj    = _pick(PARAMS)
    fields = _sample(FIELDS, 5)
    vals   = [str(random.randint(1, 99)) for _ in range(5)]
    pairs  = list(zip(fields, vals))

    while pairs == sorted(pairs):
        random.shuffle(pairs)

    def render(ps):
        return "\n".join([f"const {obj} = {{"] +
                         [f"  {k}: {v}," for k, v in ps] +
                         ["};"])

    start  = render(pairs)
    target = render(sorted(pairs))
    optimal = len(':2,6sort\r')

    return (start, target,
            f'Sort the {obj} fields alphabetically',
            optimal,
            [':2,6sort<CR>  —  sort the field lines, leaving the braces in place',
             'Vjjjj:sort<CR>  —  visually select the fields then sort'],
            'reorder_fields')


def extract_variable():
    """Extract a repeated sub-expression into a named const."""
    obj    = _pick(PARAMS)
    f1, f2 = _sample(FIELDS, 2)
    fn     = _pick(VERBS)
    var    = _pick(['prefix', 'key', 'tag', 'base', 'token'])

    expr   = f'{obj}.{f1} + "-" + {obj}.{f2}'

    start = dedent(f"""\
        function {fn}({obj}) {{
          const full = {expr};
          const short = ({expr}).slice(0, 8);
          return {{ full, short, raw: {expr} }};
        }}""")

    target = dedent(f"""\
        function {fn}({obj}) {{
          const {var} = {expr};
          const full = {var};
          const short = {var}.slice(0, 8);
          return {{ full, short, raw: {var} }};
        }}""")

    expr_e  = expr.replace('+', r'\+').replace('"', r'\"')
    insert  = f'const {var} = {expr};'
    optimal = (1 + len(insert) + 1) + (len(f':%s/{expr_e}/{var}/g\r'))

    return (start, target,
            f'Extract the repeated expression "{expr}" into a "{var}" variable',
            optimal,
            [f'2GOconst {var} = {expr};<Esc>  —  open a line above the first use',
             f'then  :%s/{expr_e}/{var}/g<CR>  —  replace all 3 occurrences'],
            'extract_variable')


def swap_object_methods():
    """Swap two consecutive single-line arrow methods in an object."""
    obj     = _pick(PARAMS)
    m1, m2  = _sample(VERBS, 2)
    p1      = _pick(PARAMS, exclude=(obj,))
    p2      = _pick(PARAMS, exclude=(obj, p1))
    f1, f2  = _sample(FIELDS, 2)

    start = dedent(f"""\
        const {obj} = {{
          {m1}: ({p1}) => {p1}.{f1},
          {m2}: ({p2}) => {p2}.{f2},
        }};""")

    target = dedent(f"""\
        const {obj} = {{
          {m2}: ({p2}) => {p2}.{f2},
          {m1}: ({p1}) => {p1}.{f1},
        }};""")

    # ddp on line 2 swaps lines 2 and 3
    optimal = 3  # 2Gddp
    return (start, target,
            f'Swap the two methods in the {obj} object',
            optimal,
            ['2Gddp  —  go to line 2, cut it, paste below line 3'],
            'swap_methods')


def add_default_param():
    """Add a default value to each of three function parameters."""
    fn          = _pick(VERBS)
    p1, p2, p3  = _sample(PARAMS, 3)
    d1          = _pick(['null', '""', '[]', '{}', '0', 'false'])
    d2          = _pick(['null', '""', '[]', '{}', '0', 'false'], exclude=(d1,))
    d3          = _pick(['null', '""', '[]', '{}', '0', 'false'], exclude=(d1, d2))

    start = dedent(f"""\
        function {fn}(
          {p1},
          {p2},
          {p3},
        ) {{}}""")

    target = dedent(f"""\
        function {fn}(
          {p1} = {d1},
          {p2} = {d2},
          {p3} = {d3},
        ) {{}}""")

    # A on each param line, insert " = default"
    s1 = f' = {d1}'
    s2 = f' = {d2}'
    s3 = f' = {d3}'
    optimal = 2 + (1 + len(s1) + 1) + 1 + (1 + len(s2) + 1) + 1 + (1 + len(s3) + 1)

    return (start, target,
            'Add a default value to each of the three parameters',
            optimal,
            [f'2GA = {d1}<Esc>jA = {d2}<Esc>jA = {d3}<Esc>  —  A appends at end of line; j moves down'],
            'add_default_param')


# ── registry ──────────────────────────────────────────────────────────────────

GENERATORS = [
    rename_all,
    for_to_map,
    early_return,
    destructure,
    template_literal,
    reorder_fields,
    extract_variable,
    swap_object_methods,
    add_default_param,
]

# ── writers ───────────────────────────────────────────────────────────────────

def write_challenge(out_dir: Path, start, target, desc, optimal, solutions):
    out_dir.mkdir(parents=True, exist_ok=True)
    (out_dir / 'start.txt').write_text(start + '\n')
    (out_dir / 'target.txt').write_text(target + '\n')
    info = [f'DESCRIPTION: {desc}', f'OPTIMAL: {optimal}']
    for i, sol in enumerate(solutions, 1):
        info.append(f'SOLUTION_{chr(64 + i)}: {sol}')
    (out_dir / 'info.txt').write_text('\n'.join(info) + '\n')


def generate_one(out_dir: Path):
    gen = random.choice(GENERATORS)
    start, target, desc, optimal, solutions, _slug = gen()
    write_challenge(out_dir, start, target, desc, optimal, solutions)


def generate_batch(challenges_dir: Path, count: int):
    if challenges_dir.exists():
        shutil.rmtree(challenges_dir)
    challenges_dir.mkdir(parents=True)

    # cycle through generators to ensure variety
    gens = (GENERATORS * ((count // len(GENERATORS)) + 1))[:count]
    random.shuffle(gens)

    for i, gen in enumerate(gens, 1):
        start, target, desc, optimal, solutions, slug = gen()
        out_dir = challenges_dir / f'{i:02d}_{slug}'
        write_challenge(out_dir, start, target, desc, optimal, solutions)
        print(f'  {i:02d}  {desc}')


# ── entry point ───────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('out', nargs='?', default='.tmp/random',
                        help='output directory (single challenge mode)')
    parser.add_argument('--batch', type=int, metavar='N',
                        help='generate N challenges into <out> as the challenges/ dir')
    args = parser.parse_args()

    if args.batch:
        print(f'Generating {args.batch} challenges into {args.out}/')
        generate_batch(Path(args.out), args.batch)
        print(f'Done.')
    else:
        generate_one(Path(args.out))


if __name__ == '__main__':
    main()
