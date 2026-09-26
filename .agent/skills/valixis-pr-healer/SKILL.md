---
name: valixis-pr-healer
description: Autonomous Zero-Touch Closed-Loop PR Protocol. Automatically opens PRs, watches Gatekeeper bot CI reviews, parses failure comments, self-corrects the code, and re-pushes until 100% passed without human intervention.
---

# VALIXIS Autonomous Closed-Loop PR Healer

This skill enables Antigravity to deliver features end-to-end with **Zero-Touch Autonomy**. The human developer does not need to intervene or ask Antigravity to fix PR review issues. Antigravity watches the Gatekeeper bot, receives its comments, fixes the code, and verifies the PR autonomously.

---

## Autonomous Zero-Touch Protocol

Whenever you are tasked with creating a Pull Request or completing an employee task (e.g. "Build Day 1 task & open PR"):

### Phase 1: Pre-Flight Local Check
Before pushing to GitHub:
```bash
valixis-gatekeeper check --fast
```
If any critical issues are found locally (linter errors, Hive `typeId` collisions, floating currency), fix them immediately before opening the PR.

### Phase 2: Open PR & Enter Watch Mode
Push the branch and open the Pull Request:
```bash
git push origin HEAD
gh pr create --fill || true
```

**CRITICAL**: Do NOT end your turn here! Immediately enter automated watch mode:
```bash
valixis-gatekeeper wait-pr --timeout 180
```

### Phase 3: Autonomous Self-Healing Loop
- **If Gatekeeper returns `PASSED`**:
  Your job is complete! Output a celebratory summary to the user confirming the PR is green and ready for merge.
- **If Gatekeeper returns `FAILED`**:
  Do NOT prompt the user or ask for help. Immediately execute self-repair:
  1. Read the `details` field from the Gatekeeper bot's output.
  2. Locate the flagged files (e.g., unused imports, duplicate Hive IDs, unhandled exceptions).
  3. Edit the files using `replace_file_content` to fix the exact issue.
  4. Verify the fix locally:
     ```bash
     valixis-gatekeeper check --fast
     ```
  5. Commit and re-push the fix:
     ```bash
     git add -A
     git commit -m "fix(gatekeeper): autonomously resolve bot review issues"
     git push origin HEAD
     ```
  6. Re-run `valixis-gatekeeper wait-pr` until the bot reports `PASSED`.

---

### Phase 4: Morning Briefing & 1-Click Conflict Resolver
When the user opens Antigravity in the morning or asks:
- "What happened last night?"
- "Morning briefing"
- "Resolve conflicts"

1. Run the morning brief tool:
   ```bash
   valixis-gatekeeper morning-brief
   ```
2. Greet the user with a concise summary of auto-merged PRs and any conflicting branches.
3. If conflicts exist:
   - Ask the user: *"Should I resolve the merge conflict in branch `<branch>` now?"*
   - When confirmed, checkout `<branch>`, run `git pull origin main`, resolve conflict markers (`<<<<<<<`), verify with `valixis-gatekeeper check --fast`, and push cleanly so the next midnight run merges it automatically!

---

## Common Auto-Repair Playbook

| Violation | Autonomous Fix Strategy |
| :--- | :--- |
| `unused_import` | Remove the unused `import '...';` line from the file. |
| `HIVE_TYPE_ID_COLLISION` | Check `pocketledger_employee_tasks.md` or sprint plan for the assigned unique `typeId` (e.g. Budget=3, Goal=4, Recurring=5) and update `@HiveType(typeId: N)`. |
| `prefer_interpolation_to_compose_strings` | Replace string concatenation (`'a' + b`) with interpolation (`'a$b'`). |
| `FINANCIAL_PRECISION_RULE` | Change `double amount` to `int amountInCents` in domain models. |
| `CONFLICT_MARKER` | Resolve Git conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`) cleanly. |
