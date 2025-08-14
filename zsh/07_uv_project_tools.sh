#!/bin/zsh

### === Function: Create New uv Project & Push to GitHub === ###

function new_uv_project() {
  echo "📁 Enter project name:"
  read project_name

  if [ -z "$project_name" ]; then
    echo "❌ Project name cannot be empty!"
    return 1
  fi

  echo "🔌 Choose remote type (ssh/https) [default: https]:"
  read remote_type
  if [ -z "$remote_type" ]; then
    remote_type="https"
  fi

  default_owner=$(gh api user --jq '.login' 2>/dev/null)
  if [ -z "$default_owner" ]; then
    echo "⚠️ Could not detect GitHub username via 'gh'."
    echo "🏢 Enter owner (your username or org):"
  else
    echo "🏢 Enter owner (your username or org) [default: $default_owner]:"
  fi
  read owner
  if [ -z "$owner" ]; then
    owner="$default_owner"
  fi

  if [ -z "$owner" ]; then
    echo "❌ Owner cannot be empty!"
    return 1
  fi

  echo "🔐 Visibility (public/private) [default: public]:"
  read visibility
  if [ -z "$visibility" ]; then
    visibility="public"
  fi

  echo "📄 Use a GitHub repo as template? (yes/no) [default: no]:"
  read use_template
  template_repo=""
  if [ "$use_template" = "yes" ]; then
    echo "🔗 Enter template repo (format: owner/repo), e.g., astral-sh/uv-template:"
    read template_repo
  fi

  echo "✅ Summary:"
  echo "Project Name: $project_name"
  echo "Remote Type: $remote_type"
  echo "Owner: $owner"
  echo "Visibility: $visibility"
  if [ -n "$template_repo" ]; then
    echo "Template: $template_repo"
  else
    echo "Template: None"
  fi
  echo "---------------------------"

  echo "Proceed? (y/n)"
  read confirm
  if [ "$confirm" != "y" ]; then
    echo "❌ Aborted!"
    return 1
  fi

  # Create project with uv (generates pyproject.toml, README.md, .gitignore, etc.)
  echo "📂 Creating uv project: $project_name"
  uv init "$project_name" || { echo "❌ uv init failed!"; return 1; }
  cd "$project_name" || return

  # Ensure a local virtual environment exists (optional; uv auto-manages, but this is explicit)
  # Creates .venv if missing and ensures Python is installed if needed
  if [ ! -d ".venv" ]; then
    echo "🐍 Creating local virtual environment (.venv)..."
    uv venv || { echo "❌ uv venv failed!"; return 1; }
  fi

  # Initialize Git (if not already)
  if [ ! -d ".git" ]; then
    echo "🔧 Initializing Git..."
    git init -b main || { echo "❌ git init failed!"; return 1; }
  else
    # Normalize branch name to main
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ "$current_branch" != "main" ]; then
      echo "🔧 Renaming Git branch to 'main'..."
      git branch -m main || { echo "❌ Failed to rename branch to main!"; return 1; }
    fi
  fi

  # First commit
  git add . || { echo "❌ git add failed!"; return 1; }
  git commit -m "Initial commit (uv project scaffold)" || echo "ℹ️ Nothing to commit."

  echo "🚀 Checking if GitHub repo exists..."
  if gh repo view "$owner/$project_name" &>/dev/null; then
    echo "⚠️ Repo $owner/$project_name already exists on GitHub, skipping creation."
  else
    echo "📡 Creating GitHub repo under $owner, visibility: $visibility..."
    if [ -n "$template_repo" ]; then
      gh repo create "$owner/$project_name" --$visibility --template "$template_repo" || { echo "❌ Failed to create GitHub repo!"; return 1; }
    else
      gh repo create "$owner/$project_name" --$visibility || { echo "❌ Failed to create GitHub repo!"; return 1; }
    fi
  fi

  # Set remote URL
  if [ "$remote_type" = "ssh" ]; then
    remote_url="git@github.com:${owner}/${project_name}.git"
    echo "🔗 Adding SSH remote origin..."
  else
    remote_url="https://github.com/${owner}/${project_name}.git"
    echo "🔗 Adding HTTPS remote origin..."
  fi

  if git remote | grep -q '^origin$'; then
    git remote set-url origin "$remote_url"
  else
    git remote add origin "$remote_url"
  fi

  echo "🚀 Pushing to GitHub..."
  git push -u origin main || { echo "❌ Failed to push to GitHub!"; return 1; }

  echo "⏳ Waiting for GitHub to process the repo (5 sec)..."
  sleep 5

  if [ -n "$template_repo" ]; then
    echo "🚀 Pulling template files from GitHub (if applicable)..."
    git pull origin main --allow-unrelated-histories || { echo "❌ Failed to pull template files!"; return 1; }
  fi

  # Make sure dependencies/env are in sync (creates uv.lock if needed)
  echo "🔧 Ensuring environment is synced..."
  uv sync || echo "⚠️ uv sync failed, check configuration."

  echo "💻 Opening in VS Code..."
  command -v code >/dev/null 2>&1 && code . || echo "ℹ️ VS Code not found, skipping."

  echo "✅ Project $project_name created under $owner ($visibility), pushed, and opened!"
}


### === Function: Pull & Sync Existing uv Project === ###

function pull_uv_project() {
  echo "📦 Enter GitHub repo (format: owner/repo):"
  read repo

  if [ -z "$repo" ]; then
    echo "❌ Repo cannot be empty!"
    return 1
  fi

  echo "🔌 Clone using ssh or https? [default: https]:"
  read remote_type
  if [ -z "$remote_type" ]; then
    remote_type="https"
  fi

  default_folder=$(basename "$repo")
  echo "📂 Enter local folder name [default: $default_folder]:"
  read folder_name
  if [ -z "$folder_name" ]; then
    folder_name="$default_folder"
  fi

  echo "✅ Summary:"
  echo "Repo: $repo"
  echo "Clone Type: $remote_type"
  echo "Local Folder: $folder_name"
  echo "---------------------------"

  echo "Proceed? (y/n)"
  read confirm
  if [ "$confirm" != "y" ]; then
    echo "❌ Aborted!"
    return 1
  fi

  # Build remote URL
  if [ "$remote_type" = "ssh" ]; then
    clone_url="git@github.com:${repo}.git"
  else
    clone_url="https://github.com/${repo}.git"
  fi

  echo "🚀 Cloning $repo..."
  git clone "$clone_url" "$folder_name" || { echo "❌ Failed to clone!"; return 1; }

  cd "$folder_name" || return

  if [ -f "pyproject.toml" ]; then
    echo "🔧 Syncing uv environment (this will create .venv if needed and install Python if missing)..."
    uv sync || echo "⚠️ uv sync failed, check configuration."
  else
    echo "⚠️ No pyproject.toml found, skipping uv sync."
  fi

  echo "💻 Opening in VS Code..."
  command -v code >/dev/null 2>&1 && code . || echo "ℹ️ VS Code not found, skipping."

  echo "✅ Project $repo cloned, synced, and opened!"
}

### === Aliases for convenience === ###
alias nup="new_uv_project"
alias pup="pull_uv_project"

