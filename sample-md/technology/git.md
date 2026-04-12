# Git: The Distributed Version Control System

> "I'm an egotistical bastard, and I name all my projects after myself. First 'Linux', now 'git'."
> -- **Linus Torvalds**

Git is the most widely used distributed version control system in the world. Created by **Linus Torvalds** in 2005, it was born out of necessity when the free license for BitKeeper -- the proprietary source-control system used for Linux kernel development -- was revoked. Today, over **93%** of professional developers rely on Git as their primary version control tool.

## History

### The BitKeeper Crisis

In early 2005, the relationship between the Linux kernel community and the commercial company that developed BitKeeper broke down. The tool's free-of-charge status was revoked, prompting Torvalds to develop a replacement.

### Rapid Development

The timeline of Git's creation is remarkably compressed:

1. **April 3, 2005** -- Development began
2. **April 6, 2005** -- Torvalds announced the project
3. **April 7, 2005** -- Git achieved *self-hosting* (tracking its own source code)
4. **April 29, 2005** -- Benchmarked at 6.7 patches per second
5. **July 26, 2005** -- Maintenance transferred to **Junio Hamano**
6. **December 21, 2005** -- Version 1.0 released

### The Name

The man page describes Git as *"the stupid content tracker,"* while the source code README calls it *"the information manager from hell."* The word "git" is British slang for a foolish person -- Torvalds chose the name with characteristic humor.

## Design Goals

Torvalds designed Git around four core principles, explicitly rejecting CVS as a model:

- **Speed and performance** -- Patches should apply in under 3 seconds (compared to 30 seconds in existing systems)
- **Distributed workflows** -- Supporting BitKeeper-like operations across multiple developers
- **Data integrity** -- Strong safeguards against accidental or malicious corruption
- **Non-linear development** -- Support for thousands of parallel branches

## Technical Architecture

### The Object Database

Git stores all data as **immutable objects** identified by SHA-1 hashes. There are five object types:

| Object Type | Description |
|-------------|-------------|
| **Blob** | File content without metadata; each version is a separate blob |
| **Tree** | Directory equivalent containing file names, type bits, and references |
| **Commit** | Links tree objects into history with parent commits and timestamps |
| **Tag** | Container for metadata, commonly storing digital signatures |
| **Packfile** | Compressed bundle combining multiple objects with delta compression |

Objects are stored in directories matching the first two hash characters, with the remaining characters forming the filename.

### References

Git stores **refs** (references) as labels pointing to specific commits:

- **Heads** (branches) -- Auto-advance to new commits as they are created
- **HEAD** -- Special reference indicating the current working branch
- **Tags** -- Fixed references to particular commits, used for marking releases

### Snapshots, Not Deltas

Unlike older systems (SCCS, RCS, SVN), Git records **snapshots** of the entire directory tree rather than tracking individual file deltas. This design simplifies rename handling -- Git detects renames while browsing history rather than recording them explicitly.

> "You can just see git as a filesystem -- it's content-addressable, and it has a notion of versioning."
> -- **Linus Torvalds**

## Essential Commands

### Repository Setup

```bash
# Create a new local repository
git init

# Clone an existing repository
git clone https://github.com/user/repo.git

# Clone with a specific branch
git clone -b develop https://github.com/user/repo.git
```

### Daily Workflow

```bash
# Check working tree status
git status

# Stage specific files
git add index.html styles.css

# Stage all changes
git add -A

# Commit staged changes
git commit -m "Add landing page layout"

# View commit history
git log --oneline --graph
```

### Branching and Merging

```bash
# Create and switch to a new branch
git checkout -b feature/auth

# Switch to an existing branch
git checkout main

# Merge a branch into the current branch
git merge feature/auth

# Delete a merged branch
git branch -d feature/auth
```

### Remote Operations

```bash
# Add a remote repository
git remote add origin https://github.com/user/repo.git

# Push commits to the remote
git push origin main

# Fetch changes without merging
git fetch origin

# Pull (fetch + merge) from remote
git pull origin main
```

### Inspecting Changes

```bash
# Show unstaged changes
git diff

# Show staged changes
git diff --cached

# Show changes in a specific commit
git show abc1234

# Blame a file (show who changed each line)
git blame src/app.js
```

### Undoing Changes

```bash
# Unstage a file (keep changes in working directory)
git restore --staged file.txt

# Discard working directory changes
git restore file.txt

# Revert a commit (creates a new commit)
git revert abc1234

# Amend the last commit message
git commit --amend -m "Corrected message"
```

## The .gitignore File

Projects use a `.gitignore` file to specify untracked files that Git should ignore:

```gitignore
# Compiled output
build/
dist/
*.o

# Dependencies
node_modules/
.venv/

# Environment files
.env
.env.local

# IDE files
.idea/
.vscode/
*.swp
```

## Merge Strategies

Git implements multiple merge algorithms for different situations:

- **Resolve** -- Traditional three-way merge for two heads
- **Recursive** -- Default strategy for single branches; creates a merged tree of common ancestors
- **Octopus** -- Default when merging more than two heads simultaneously
- **Ours** -- Resolves conflicts by always favoring the current branch
- **Subtree** -- Adjusts trees to match before performing a recursive merge

## Distributed Workflows

### Centralized Workflow

A single shared repository acts as the central point. Developers clone, make changes locally, and push back to the central repo. Similar to SVN but with full local history.

### Integration Manager Workflow

1. Each developer has a **public** and a **private** repository
2. Developers push to their own public repo
3. An integration manager pulls from contributor repos
4. The manager pushes the merged result to the *blessed* repository
5. Contributors pull from the blessed repository to stay up to date

### Dictator and Lieutenants Workflow

Used by the **Linux kernel** project itself:

1. *Lieutenants* manage subsystems and merge contributor patches
2. The *dictator* (Torvalds) merges from lieutenants into the master branch
3. All developers rebase their work on top of the master branch

## Adoption and Industry Impact

Git's adoption has been extraordinary:

- **2022**: 93.9% of developers reported using Git (Stack Overflow survey)
- **2016**: 29.27% of UK software development job postings cited Git
- **2014**: 42.9% of professional developers used Git as their primary VCS (Eclipse Foundation survey)

Major hosting platforms built around Git include **GitHub**, **GitLab**, **Bitbucket**, and **SourceForge**.

## Alternative Implementations

Beyond the original C implementation, Git has been reimplemented in multiple languages:

- **JGit** -- Pure Java (used in Gerrit and Eclipse)
- **go-git** -- Open-source Go implementation
- **libgit2** -- ANSI C library with bindings for Ruby, Python, and Haskell
- **Dulwich** -- Pure Python implementation
- **gitoxide** -- Rust implementation focused on performance

## Security

Git initially used **SHA-1** hashing for object identification, though Torvalds emphasized this was intended to guard against *accidental* corruption rather than provide cryptographic security. Following the 2017 **SHAttered** attack demonstration, Git adopted hardened SHA-1 variants resistant to known collision attacks, and work on SHA-256 support has progressed.

Notable vulnerabilities have included arbitrary code execution exploits (December 2014, CVE-2015-7545), which were patched in subsequent releases.

## Conventions and Best Practices

Common practices in Git-based development include:

- Default **main** branch for integration (historically called *master*)
- Avoiding rewrites of pushed commits; prefer **reverting** instead
- The **git-flow** workflow distinguishing feature branches, development, production, and hotfix branches
- **Pull requests** (or *merge requests*) for code review before merging -- a feature of hosting services, not Git itself
- Writing descriptive commit messages with a short subject line and optional detailed body

---

*Source: [Git -- Wikipedia](https://en.wikipedia.org/wiki/Git). Content adapted and reformatted for demonstration purposes.*
