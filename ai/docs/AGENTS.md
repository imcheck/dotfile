# ai/docs

Index for shared reference documents that agents may use during a session.

## Session Start

- When this file exists, read it early in the session so you know which shared documents are available.
- Do not assume every file in `ai/docs/` must be read unconditionally. Open individual documents only when they are relevant.

## Available Docs

- `WHOAMI.md`: confirmed personal reference details for the repository owner. Use when a task depends on identity, address, family, or other personal profile information.

## Notes

- Keep documents in this directory factual, focused, and explicitly scoped.
- When a document includes inferred information, label it clearly so it is not mistaken for a confirmed fact.
- Write documents so they are usable by both Claude and Codex.
