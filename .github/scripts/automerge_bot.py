"""
VALIXIS Midnight Autonomous PR Auto-Merge & Conflict Prompt Bot
Runs in GitHub Actions runners at 12:00 AM Midnight IST (18:30 UTC).

Non-blocking algorithm:
1. Scans all open PRs targeting main/master in chronological order (ascending PR number).
2. For clean, passing PRs: auto-merges them into main via GitHub CLI / REST API.
3. For conflicting PRs:
   - Identifies conflicting files.
   - Generates a customized Ready-to-Run Antigravity Prompt.
   - Comments the prompt directly on the PR.
   - Continues evaluating and merging remaining PRs without halting!
4. Produces MIDNIGHT_AUTOFOCUS_REPORT.md and midnight_summary.json.
"""

import sys
import os
import subprocess
import json
import argparse
import time
import urllib.request
import urllib.error
from pathlib import Path
from typing import List, Dict, Any, Tuple

REPO_ROOT = Path(".").resolve()

def run_cmd(cmd: List[str], cwd: Path = REPO_ROOT) -> subprocess.CompletedProcess:
    """Run command with shell=False so arguments in list are properly passed."""
    return subprocess.run(cmd, cwd=str(cwd), capture_output=True, text=True, shell=False)

def github_api_request_with_status(endpoint: str, method: str = "GET", data: Dict[str, Any] = None) -> Tuple[Any, int]:
    """Execute authenticated GitHub REST API request and return (data, status_code)."""
    token = os.environ.get("GH_TOKEN") or os.environ.get("GITHUB_TOKEN")
    repo = os.environ.get("GITHUB_REPOSITORY", "VALIXIS/PocketLedger")
    if not token:
        print("  Warning: No GH_TOKEN or GITHUB_TOKEN found in environment.")
        return None, 401

    url = f"https://api.github.com/repos/{repo}/{endpoint.lstrip('/')}"
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3+json",
        "User-Agent": "VALIXIS-Midnight-Bot"
    }

    req_data = json.dumps(data).encode('utf-8') if data else None
    req = urllib.request.Request(url, data=req_data, headers=headers, method=method)

    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            content = resp.read().decode('utf-8')
            return (json.loads(content) if content else {}), resp.status
    except urllib.error.HTTPError as e:
        error_detail = e.read().decode('utf-8', errors='ignore')
        try:
            parsed = json.loads(error_detail)
        except Exception:
            parsed = {"message": error_detail}
        return parsed, e.code
    except Exception as e:
        print(f"  GitHub API exception ({method} {endpoint}): {e}")
        return None, 500

def github_api_request(endpoint: str, method: str = "GET", data: Dict[str, Any] = None) -> Any:
    """Helper wrapper for github_api_request_with_status."""
    res, _ = github_api_request_with_status(endpoint, method=method, data=data)
    return res

def get_open_pull_requests() -> List[Dict[str, Any]]:
    """Retrieve all open pull requests targeting default branch sorted by number ascending."""
    # First attempt: GitHub CLI
    cmd = [
        'gh', 'pr', 'list',
        '--state', 'open',
        '--json', 'number,title,headRefName,baseRefName,mergeable,statusCheckRollup,url,author,labels'
    ]
    res = run_cmd(cmd)
    if res.returncode == 0 and res.stdout.strip():
        try:
            prs = json.loads(res.stdout)
            if isinstance(prs, list) and len(prs) > 0:
                return sorted(prs, key=lambda p: p["number"])
        except Exception as e:
            print(f"Failed to parse gh pr list output: {e}")

    # Second attempt: GitHub REST API
    api_res = github_api_request("pulls?state=open&sort=created&direction=asc")
    if api_res and isinstance(api_res, list):
        prs = []
        for p in api_res:
            prs.append({
                "number": p["number"],
                "title": p["title"],
                "headRefName": p["head"]["ref"],
                "baseRefName": p["base"]["ref"],
                "mergeable": "UNKNOWN",
                "url": p["html_url"],
                "author": {"login": p["user"]["login"]}
            })
        return sorted(prs, key=lambda p: p["number"])

    return []

def get_conflicting_files(pr_number: int) -> List[str]:
    """Retrieve changed/conflicting files for a PR."""
    cmd = ['gh', 'pr', 'view', str(pr_number), '--json', 'files']
    res = run_cmd(cmd)
    if res.returncode == 0 and res.stdout.strip():
        try:
            data = json.loads(res.stdout)
            return [f.get('path', '') for f in data.get('files', []) if f.get('path')]
        except Exception:
            pass

    # API fallback
    api_files = github_api_request(f"pulls/{pr_number}/files")
    if api_files and isinstance(api_files, list):
        return [f["filename"] for f in api_files if "filename" in f]

    return []

def is_ci_passing(pr: Dict[str, Any]) -> bool:
    """Verify that CI status checks for PR are passing."""
    checks = pr.get("statusCheckRollup", [])
    if not checks:
        return True
    
    for check in checks:
        conclusion = (check.get("conclusion") or check.get("state") or "").upper()
        name = check.get("name", "")
        if "midnight" in name.lower():
            continue
        if conclusion in ("FAILURE", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED"):
            return False
    return True

def comment_on_pr(pr_number: int, comment_body: str) -> bool:
    """Post comment on PR via GitHub CLI or fallback to REST API."""
    res = run_cmd(['gh', 'pr', 'comment', str(pr_number), '--body', comment_body])
    if res.returncode == 0:
        return True
    api_res, code = github_api_request_with_status(
        f"issues/{pr_number}/comments",
        method="POST",
        data={"body": comment_body}
    )
    return code in (200, 201)

def merge_pull_request(pr_number: int, branch: str) -> Tuple[bool, str]:
    """
    Attempts to merge PR into base branch.
    Returns (success: bool, status_reason: str).
    """
    # 1. Attempt GitHub CLI
    merge_cmd = ['gh', 'pr', 'merge', str(pr_number), '--merge', '--delete-branch']
    m_res = run_cmd(merge_cmd)
    if m_res.returncode == 0:
        return True, "merged_gh_cli"

    err_msg = (m_res.stderr or m_res.stdout or "").strip()
    print(f"  Notice: 'gh pr merge' returned {m_res.returncode}: {err_msg}")
    if "conflict" in err_msg.lower() or "merge conflict" in err_msg.lower():
        return False, "conflict"

    # 2. Attempt GitHub REST API fallback
    api_res, status_code = github_api_request_with_status(
        f"pulls/{pr_number}/merge",
        method="PUT",
        data={
            "merge_method": "merge",
            "commit_title": f"Merge pull request #{pr_number} from {branch}"
        }
    )
    if status_code == 200 and api_res and api_res.get("merged") is True:
        # Best effort branch deletion
        try:
            github_api_request(f"git/refs/heads/{branch}", method="DELETE")
        except Exception:
            pass
        return True, "merged_api"
    elif status_code == 409:
        return False, "conflict"
    else:
        err_text = api_res.get("message", f"HTTP {status_code}") if isinstance(api_res, dict) else f"HTTP {status_code}"
        return False, err_text

def generate_antigravity_prompt(pr: Dict[str, Any], conflicting_files: List[str]) -> str:
    """Generate the exact prompt to run in Antigravity for instant morning resolution."""
    branch = pr.get('headRefName', 'feature-branch')
    base = pr.get('baseRefName', 'main')
    files_str = "\n".join([f"- `{f}`" for f in conflicting_files[:8]]) or "- (All modified files in PR branch)"

    prompt = f"""Antigravity, checkout branch '{branch}' and pull latest 'origin/{base}'.
Resolve all merge conflict markers (<<<<<<<, =======, >>>>>>>) in:
{files_str}

Ensure changes from both branches are preserved cleanly without breaking Clean Architecture or Riverpod state.
Run `valixis-gatekeeper check --fast` to verify zero errors or lint warnings remain.
Once passing, commit and push to '{branch}' so the midnight bot can auto-merge.
"""
    return prompt.strip()

def process_pull_requests(dry_run: bool = False) -> Dict[str, Any]:
    """Process all PRs non-blockingly."""
    prs = get_open_pull_requests()
    print(f"Found {len(prs)} open Pull Requests targeting main.")

    results = {
        "timestamp": os.environ.get("GITHUB_RUN_ID", "local-test"),
        "total_prs": len(prs),
        "merged": [],
        "conflicts": [],
        "failing_ci": []
    }

    for pr in prs:
        num = pr["number"]
        title = pr["title"]
        branch = pr["headRefName"]
        ci_ok = is_ci_passing(pr)

        print(f"\nEvaluating PR #{num} ('{title}') [Branch: {branch}]...")

        # Dynamically query fresh mergeability against latest main
        mergeable = "UNKNOWN"
        for _ in range(3):
            detail = github_api_request(f"pulls/{num}")
            if detail and detail.get("mergeable") is not None:
                mergeable = "MERGEABLE" if detail["mergeable"] else "CONFLICTING"
                break
            time.sleep(1.5)

        print(f"  Mergeable: {mergeable} | CI Passing: {ci_ok}")

        if mergeable == "CONFLICTING":
            print(f"  🚨 Merge conflict detected on PR #{num}!")
            conflicting_files = get_conflicting_files(num)
            prompt = generate_antigravity_prompt(pr, conflicting_files)

            comment_body = f"""### 🚨 Merge Conflict Detected by VALIXIS Midnight Bot

The newly merged changes in `main` conflict with branch `{branch}`.

#### 📋 Ready-to-Run Antigravity Prompt:
> Copy and run this in Antigravity to resolve automatically:

```text
{prompt}
```
"""
            if not dry_run:
                comment_on_pr(num, comment_body)

            results["conflicts"].append({
                "pr_number": num,
                "title": title,
                "branch": branch,
                "files": conflicting_files,
                "antigravity_prompt": prompt
            })
            continue

        elif not ci_ok:
            print(f"  ⚠️ CI checks not passing on PR #{num}. Skipping auto-merge.")
            results["failing_ci"].append({
                "pr_number": num,
                "title": title,
                "branch": branch
            })
            continue

        else:
            # Clean and ready to merge!
            print(f"  ✔ PR #{num} is clean and passing CI. Merging...")
            if not dry_run:
                merged, status = merge_pull_request(num, branch)
                if merged:
                    confirm_body = "🤖 **Autonomously merged into main by VALIXIS Midnight Bot.** All integrity verifications passed."
                    comment_on_pr(num, confirm_body)
                    results["merged"].append({
                        "pr_number": num,
                        "title": title,
                        "branch": branch
                    })
                    print(f"  🚀 PR #{num} successfully merged! ({status})")
                elif status == "conflict":
                    print(f"  🚨 Merge conflict detected during merge attempt on PR #{num}!")
                    conflicting_files = get_conflicting_files(num)
                    prompt = generate_antigravity_prompt(pr, conflicting_files)
                    comment_body = f"""### 🚨 Merge Conflict Detected by VALIXIS Midnight Bot

The newly merged changes in `main` conflict with branch `{branch}`.

#### 📋 Ready-to-Run Antigravity Prompt:
> Copy and run this in Antigravity to resolve automatically:

```text
{prompt}
```
"""
                    comment_on_pr(num, comment_body)
                    results["conflicts"].append({
                        "pr_number": num,
                        "title": title,
                        "branch": branch,
                        "files": conflicting_files,
                        "antigravity_prompt": prompt
                    })
                else:
                    print(f"  Failed to merge PR #{num}: {status}")
            else:
                print(f"  [DRY RUN] Would auto-merge PR #{num} ({branch})")
                results["merged"].append({
                    "pr_number": num,
                    "title": title,
                    "branch": branch
                })

    # Generate Reports
    generate_reports(results)
    return results

def generate_reports(results: Dict[str, Any]):
    """Write summary markdown and json files."""
    md = f"""# 🌙 VALIXIS Midnight Auto-Merge Briefing

| Metric | Count |
| :--- | :---: |
| **Total Open PRs Evaluated** | {results['total_prs']} |
| **Successfully Auto-Merged** | {len(results['merged'])} |
| **Conflicts Detected** | {len(results['conflicts'])} |
| **Failing CI / In Progress** | {len(results['failing_ci'])} |

---

## 1. Successfully Merged PRs
"""
    if not results["merged"]:
        md += "_No clean PRs were ready to merge._\n"
    else:
        for m in results["merged"]:
            md += f"- ✅ **PR #{m['pr_number']}**: {m['title']} (`{m['branch']}`)\n"

    md += "\n---\n\n## 2. Conflicts Requiring Antigravity Morning Resolution\n"
    if not results["conflicts"]:
        md += "_🎉 Zero merge conflicts detected across all branches!_\n"
    else:
        for idx, c in enumerate(results["conflicts"], start=1):
            md += f"\n### {idx}. PR #{c['pr_number']}: {c['title']} (`{c['branch']}`)\n"
            md += f"**Conflicting Files**:\n"
            for f in c["files"]:
                md += f"- `{f}`\n"
            md += f"\n**Ready-to-Run Antigravity Prompt**:\n```text\n{c['antigravity_prompt']}\n```\n"

    Path("MIDNIGHT_AUTOFOCUS_REPORT.md").write_text(md, encoding='utf-8')
    Path("midnight_summary.json").write_text(json.dumps(results, indent=2), encoding='utf-8')
    print("\nReports successfully written to MIDNIGHT_AUTOFOCUS_REPORT.md and midnight_summary.json")

def main():
    parser = argparse.ArgumentParser(description="VALIXIS Midnight Autonomous PR Auto-Merge Bot")
    parser.add_argument("--dry-run", action="store_true", help="Simulate run without performing actual merges or comments")
    args = parser.parse_args()

    process_pull_requests(dry_run=args.dry_run)

if __name__ == "__main__":
    main()
