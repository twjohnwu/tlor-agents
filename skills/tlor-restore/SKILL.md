---
description: Restore tlor-agents installation from a backup created by /tlor-init
---

# /tlor-restore — Rollback to Previous Installation

Restore agents, rules, and configuration from a backup created by `/tlor-init`.

## Workflow

### Step 1: Find backups

Search for `.tlor-backup-*` directories at all standard locations:

```bash
# Check for backups
for base in ~/.claude .claude .; do
  ls -d "$base"/.tlor-backup-* 2>/dev/null
done
```

If no backups found: report "No backups found. Backups are created
automatically when `/tlor-init` upgrades existing files. Run `/tlor-init`
to create a fresh installation." and stop.

### Step 2: List available backups

Present backups sorted by date (newest first):

| Backup | Date | Files | Size |
|--------|------|-------|------|
| .tlor-backup-YYYYMMDD | YYYY-MM-DD | N files | X KB |

Let the user choose which backup to restore.

### Step 3: Preview restoration

Show what will be restored:

| File | Current version | Backup version | Action |
|------|----------------|----------------|--------|
| (path) | (current ver or "missing") | (backup ver) | restore / skip |

Ask the user to confirm: "Restore N files from backup YYYY-MM-DD? This will
overwrite the current installation. [Confirm / Cancel]"

### Step 4: Execute restoration

For each file in the selected backup:
1. Copy from backup to the original installation path
2. Verify the copy (file exists, size matches)

Do NOT delete the backup after restoring — it remains available for future use.

### Step 5: Report

```
tlor-agents restore complete:
  Source:    .tlor-backup-YYYYMMDD/
  Restored:  N files
  Skipped:   M files
  Backup preserved (not deleted)
```

Suggest running `/tlor-init` afterwards to check if further updates are
available.

## Notes

- Backups are created by `/tlor-init` during upgrades
- Multiple backup points can coexist (different dates)
- Restoring does NOT delete the backup — you can restore the same backup again
- If the backup contains files that no longer exist in the current installation,
  they are recreated at their original paths
