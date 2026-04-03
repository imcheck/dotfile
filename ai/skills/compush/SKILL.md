---
name: compush
description: Commit the current changes and push them to the remote branch. Use this skill only when the user explicitly asks to commit, push, or both, or explicitly invokes $compush, for example "커밋해줘", "푸시해줘", "commit and push", "올려줘", or "push it up".
disable-model-invocation: true
---

# Compush — Commit & Push in One Shot

Your job is to commit the current changes and push to the remote branch as fast as possible. Do NOT ask the user for confirmation at any step. Move through the entire flow without stopping.

## Flow

1. **Check status**: Run `git status` to see what's changed.
   - If there are no changes at all (working tree clean AND nothing staged), tell the user and stop.

2. **Check staging state**: Run `git diff --cached --quiet` to check if anything is already staged.
   - **If there ARE staged changes**: Note `STAGE_FLAG=""` (don't use --all)
   - **If there are NO staged changes**: Note `STAGE_FLAG="--all"` (will stage everything)

3. **Generate a commit message**: Analyze the diff with `git diff --cached --stat` and `git diff --cached` (or `git diff --stat` / `git diff` if nothing is staged). Limit to first 200 lines if huge. Write a clear, conventional commit message:
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

4. **Commit & Push**: Run the `run.sh` script in this skill's directory:
   ```
   <skill-directory>/run.sh [--all] -m "<message>"
   ```
   - Include `--all` only if step 2 determined no staged changes exist.
   - If the user provided a specific commit message, use that instead of generating one.

5. **Report**: After the script succeeds, give a brief summary from its output:
   - Branch name
   - Commit hash (short)
   - One-line commit message
   - Number of files changed

## Important Rules

- Never ask "should I proceed?" or "is this OK?" — just do it.
- Never ask the user to write the commit message — generate it yourself.
- If the user provides a specific commit message, use that instead of generating one.
- Always use this skill's `run.sh` for the commit+push step. Never run `git commit` or `git push` directly.
- If the user explicitly asks for commit only and says not to push, stop after the commit step.
- If the script fails for auth reasons, explain the issue and how to fix it (SSH key, token, etc.) — don't retry endlessly.
- If the script fails due to merge conflicts, stop and explain the situation to the user.
