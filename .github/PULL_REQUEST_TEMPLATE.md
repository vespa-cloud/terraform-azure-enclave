<!--
Versioning & tagging quick guide (read this before submitting):

- Regular PRs: bump `locals.template_version` in `main.tf` to a SemVer strictly greater than BOTH `origin/main` and the latest tag.
- Minor/no-tag PRs: do NOT change `locals.template_version`. Only use this for truly trivial changes (e.g., code comments, whitespace, non-functional renames). Mark this PR by adding the `no-tag` label or starting the title with `minor` or `[minor` (case-insensitive).
- Documentation changes are NOT minor.
- On merge to `main`, a tag `v<template_version>` is created automatically if the version increased.

See more details in .github/CONTRIBUTING.md.
-->

### Summary

Describe what this PR changes.

### Intent (select one)

- [ ] Minor/no-tag (trivial; no docs; no version bump)
- [ ] Regular (version bump in `main.tf`)

### Checklist
- [ ] If regular: bumped `locals.template_version` and verified it’s higher than BOTH `origin/main` and the latest tag.
- [ ] If minor/no-tag: left `locals.template_version` unchanged and labeled/title-marked the PR.
- [ ] This PR follows the policy in [CONTRIBUTING.md](./CONTRIBUTING.md).
