---
name: git-push
description: Commit all staged/unstaged changes and push to remote in one smooth flow — no confirmations, no pauses. Use this skill whenever the user says "커밋해줘", "푸시해줘", "commit and push", "올려줘", "배포해", "코드 올려", or any variation of committing and pushing code. Also trigger when the user finishes a task and says something like "다 됐어, 올려줘" or "push it up". Even if the user only says "commit", assume they also want to push unless they explicitly say otherwise.
disable-model-invocation: false
---

# Git Push — Commit & Push in One Shot

Your job is to commit all current changes and push to the remote branch as fast as possible. Do NOT ask the user for confirmation at any step. Move through the entire flow without stopping.

## Flow

1. **Check status**: Run `git status` to see what's changed.
   - If there are no changes at all (working tree clean AND nothing staged), tell the user and stop.

2. **Stage changes** (branching logic):
   - Run `git diff --cached --quiet` to check if anything is already staged.
   - **If there ARE staged changes**: Keep them as-is. Do NOT run `git add` — commit only what the user explicitly staged.
   - **If there are NO staged changes**: Run `git add -A` to stage all changes (new, modified, deleted).

3. **Generate a commit message**: Analyze the diff with `git diff --cached --stat` and `git diff --cached` (limit to first 200 lines if huge). Write a clear, conventional commit message:
   - Use conventional commits format: `type(scope): description`
   - Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `build`, `ci`, `perf`
   - Keep the subject line under 72 characters
   - If changes span multiple areas, pick the most dominant type
   - Write the message in English regardless of conversation language

   **Examples:**
   - `feat(auth): add JWT token refresh logic`
   - `fix(api): handle null response in user endpoint`
   - `refactor(utils): extract date formatting helpers`
   - `chore: update dependencies and lock file`

4. **Commit**: Run `git commit -m "<message>"`

5. **Push**: Run `git push`
   - If the current branch has no upstream, run `git push --set-upstream origin <branch-name>`
   - If push is rejected due to divergence, run `git pull --rebase` then `git push` again

6. **Report**: After everything succeeds, give a brief summary:
   - Branch name
   - Commit hash (short)
   - One-line commit message
   - Number of files changed

## Important Rules

- Never ask "should I proceed?" or "is this OK?" — just do it.
- Never ask the user to write the commit message — generate it yourself.
- If the user provides a specific commit message, use that instead of generating one.
- If `git push` fails for auth reasons, explain the issue and how to fix it (SSH key, token, etc.) — don't retry endlessly.
- If there are merge conflicts after `git pull --rebase`, stop and explain the situation to the user.
