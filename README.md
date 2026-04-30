# vim-practice

Five focused exercise files and 20 timed challenges. Each exercise file has folded solutions — try before peeking.

## Installation

**vim-plug:**
```vim
Plug 'ilia-murzinov/vim-practice'
```

**Optional — fzf integration** (challenge picker uses fzf when available):
```vim
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'ilia-murzinov/vim-practice'
```

**Without a plugin manager** — clone the repo and source the plugin manually:
```vim
source /path/to/vim-practice/plugin/vim-practice.vim
```

## Exercise Files

| File | Topic |
|------|-------|
| `01_word_motions.txt`  | w b e W B E ge — word jumping |
| `02_find_motions.txt`  | f F t T ; , — character targeting |
| `03_text_objects.txt`  | iw aw i" i( i{ — operate on text objects |
| `04_operators.txt`     | d c y with motions — efficient editing |
| `05_real_world.txt`    | Mixed — realistic code editing scenarios |

## Challenges

20 start→target editing challenges in `challenges/`. Each challenge has:
- `start.txt` — the file to edit
- `target.txt` — what it should look like when done
- `info.txt` — description, optimal keystroke count, and solution(s)

| # | Challenge | Key technique |
|---|-----------|---------------|
| 01 | Delete a word cleanly | `daw` |
| 02 | Change a string value | `ci"` |
| 03 | Delete a trailing comment | `f/hD` |
| 04 | Comment out 3 lines | `<C-v>I` visual block insert |
| 05 | Swap two function args | `ci(` retype |
| 06 | Replace all args with one | `ci(` |
| 07 | Add semicolons to 4 lines | `A;<Esc>` + dot-repeat |
| 08 | Uppercase a string | `gUi"` |
| 09 | Clear a string value | `ci"<Esc>` |
| 10 | Join two lines | `J` |
| 11 | Rename 3 occurrences in a function | `cgn` + dot-repeat |
| 12 | Collapse 4 lines to one | `JJJ` |
| 13 | Add a trailing comma | `GkA,` |
| 14 | Delete all console.log lines | `:g/pattern/d` |
| 15 | Remove an HTML attribute | `fcdtd` |
| 16 | Wrap expression in a function call | `f=w` + two insertions |
| 17 | Swap ternary branches | `ci"` + `;` repeat |
| 18 | Sort import lines | `:sort` |
| 19 | Make step numbers sequential | `g<C-A>` visual increment |
| 20 | Duplicate line and rename constant | `yyp` + `ciw` |

## Playground

`playground/` contains realistic files in several languages (TypeScript, Java, Lua, YAML, JSON, etc.) for freeform practice without guided exercises.

## How to Use

### Exercise files

Open any file in vim. Solutions are hidden in **folds**.

| Key  | Action |
|------|--------|
| `zM` | Close all folds (hide solutions) |
| `zR` | Open all folds (reveal solutions) |
| `za` | Toggle fold under cursor |
| `zo` | Open fold under cursor |

**Workflow:** Read the exercise, attempt it, then `za` on the solution line to check your answer.

### Challenges

```bash
make practice   # open a random challenge in vim
make test       # run all challenges headlessly and check results
make clean      # remove .tmp working files
```

Or open manually: edit `challenges/NN_name/start.txt`, aim to match `target.txt`.

## Scoring

Count your keystrokes. The solutions in `info.txt` show the optimal count. Try to match or beat it.
Normal mode counts — search commands like `/word<CR>` count as the number of characters typed.
