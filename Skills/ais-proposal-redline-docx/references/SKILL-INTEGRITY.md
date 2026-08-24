# Skill Integrity

## The problem this solves

A delivery run produced a redline with the wrong response author and no
threading guard, using code that had been fixed in the repository months
earlier. The repository copy was correct the whole time. What ran was a
hand-installed copy under an agent skills cache that predated the fixes.

Two conditions combined:

1. **Silent precedence.** An agent runtime that discovers skills in a cache
   directory loads that copy in preference to the repository, without saying so.
2. **No drift signal.** Both copies declared `metadata.version: "1.0"`, so
   nothing distinguished a current install from a stale one.

Neither condition is unusual. What made it costly is that every other control —
schema validation, guard rails, documentation, review checklists — lives inside
the artifact that went missing. Controls placed in the skill only protect
sessions that already loaded the right skill.

## Precedence

The repository copy at `Skills/ais-proposal-redline-docx/` is authoritative.

Any copy under an agent skills cache — commonly
`~/.agents/skills/ais-proposal-redline-docx/` — is a derived install. Treat it
as a build output, never as a place to make edits. An edit made there is lost
on the next refresh and, worse, diverges silently until it produces a wrong
deliverable.

## The identity banner

Every script prints one line to stderr at the start of each run:

```text
[skill] ais-proposal-redline-docx v2.0 (/path/to/Skills/ais-proposal-redline-docx/scripts)
```

It goes to stderr because stdout carries machine-readable JSON that callers
parse.

This is the highest-leverage control in the skill precisely because it does not
depend on the right copy being loaded. It is emitted by whatever code is
actually running, so it reports the truth even in the failure case the other
controls cannot see.

Check two things:

- **Path** — is it the repository copy you expect?
- **Version** — does it match `metadata.version` in `SKILL.md`?

If either is wrong, refresh before trusting any output from the run.

## Refreshing a cached copy

Replace the cached directory wholesale rather than patching files; a partial
copy reintroduces exactly the drift you are trying to remove.

```bash
rm -rf ~/.agents/skills/ais-proposal-redline-docx
cp -r Skills/ais-proposal-redline-docx ~/.agents/skills/
```

Then confirm both of these:

```bash
# 1. All six scripts are present. A five-script copy is the known-stale shape.
ls ~/.agents/skills/ais-proposal-redline-docx/scripts | wc -l   # expect 6

# 2. No hardcoded legacy author remains in the executable copy.
grep -r "AIS Proposal Team" ~/.agents/skills/ais-proposal-redline-docx/scripts | wc -l  # expect 0
```

The grep is scoped to `scripts/` deliberately. Run against the whole directory
it always matches, because this document quotes the string it is looking for.

The first check catches a copy taken before `docx_redline_lib.py` was
extracted — the shape that hardcoded the author in six places. The second
catches the specific defect that reached a client deliverable.

Finally, run any script and read the banner. That is the only check that
confirms what will actually load.

## Versioning

`metadata.version` in `SKILL.md` and `SKILL_VERSION` in
`scripts/docx_redline_lib.py` must agree; a test enforces this. Bump both
whenever the merge-plan contract or script behaviour changes in a way that
would make an older cached copy produce a different deliverable.

A version that never changes cannot signal drift, which is how two different
copies both claimed to be `1.0`.
