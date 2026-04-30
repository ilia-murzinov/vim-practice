# Vim Motion Practice

Five focused exercise files. Each file has folded solutions — try before peeking.

## Files

| File | Topic |
|------|-------|
| `01_word_motions.txt`  | w b e W B E ge — word jumping |
| `02_find_motions.txt`  | f F t T ; , — character targeting |
| `03_text_objects.txt`  | iw aw i" i( i{ — operate on text objects |
| `04_operators.txt`     | d c y with motions — efficient editing |
| `05_real_world.txt`    | Mixed — realistic code editing scenarios |

## How to Use

Open any file in vim. Solutions are hidden in **folds**.

| Key     | Action                    |
|---------|---------------------------|
| `zM`    | Close all folds (hide all solutions) |
| `zR`    | Open all folds (reveal all solutions) |
| `za`    | Toggle fold under cursor  |
| `zo`    | Open fold under cursor    |

**Workflow:** Read the exercise, attempt it in a scratch buffer or directly in the file,
then `za` on the solution line to check your answer.

## Scoring

Count your keystrokes. The solutions show the optimal count. Try to match or beat it.
Normal mode counts — search commands like `/word<CR>` count as the number of characters typed.
