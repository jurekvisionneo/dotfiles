#!/bin/zsh

### === Function: Create New Rye Project & Push to GitHub === ###

function new_rye_project() {
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

  default_owner=$(gh api user --jq '.login')
  echo "🏢 Enter owner (your username or org) [default: $default_owner]:"
  read owner
  if [ -z "$owner" ]; then
    owner="$default_owner"
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
    echo "🔗 Enter template repo (format: owner/repo), e.g., justuskilianwolff/python-template:"
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

  echo "📂 Creating project folder: $project_name"
  mkdir "$project_name"
  cd "$project_name" || return

  echo "🐍 Initializing Rye project..."
  rye init

  echo "🔧 Initializing Git..."
  git init
  echo ".venv/" >> .gitignore
  echo "__pycache__/" >> .gitignore
  echo "*.pyc" >> .gitignore
  git add .
  git commit -m "Initial commit"

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

  if git remote | grep origin &>/dev/null; then
    git remote set-url origin "$remote_url"
  else
    git remote add origin "$remote_url"
  fi

  echo "🚀 Pushing to GitHub..."
  git push -u origin main || { echo "❌ Failed to push to GitHub!"; return 1; }

  echo "⏳ Waiting for GitHub to process the repo (5 sec)..."
  sleep 5

  echo "🚀 Pulling template files from GitHub..."
  git pull origin main --allow-unrelated-histories || { echo "❌ Failed to pull template files!"; return 1; }

  echo "💻 Opening in VS Code..."
  code .

  echo "✅ Project $project_name created under $owner ($visibility), synced template, pushed, and opened!"
}

### === Function: Pull & Sync Existing Rye Project === ###

function pull_rye_project() {
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
    echo "🔧 Syncing Rye environment..."
    rye sync || echo "⚠️ Rye sync failed, check configuration."
  else
    echo "⚠️ No pyproject.toml found, skipping Rye sync."
  fi

  echo "💻 Opening in VS Code..."
  code .

  echo "✅ Project $repo cloned, synced, and opened!"
}

### === Aliases for convenience === ###
alias nrp="new_rye_project"
alias prp="pull_rye_project"

