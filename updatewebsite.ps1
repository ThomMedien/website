# PowerShell Script for Windows

# Set variables for Obsidian to Hugo copy
$sourcePath = "C:\Users\Tom Coffey\Desktop\Technical\Obsidian Notes\Mediengestaltung Notes\Posts for website"
$destinationPath = "C:\Users\Tom Coffey\Documents\website\content\posts"
$publicImagesPath = "C:\Users\Tom Coffey\Documents\website\public\images"

# Set Github repo 
$myrepo = "git@github.com:ThomMedien/website.git"

# Set error handling
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Change to the script's directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
Set-Location $ScriptDir

# Check for required commands
$requiredCommands = @('git', 'hugo')

# Check for Python command (python or python3)
if (Get-Command 'python' -ErrorAction SilentlyContinue) {
    $pythonCommand = 'python'
} elseif (Get-Command 'python3' -ErrorAction SilentlyContinue) {
    $pythonCommand = 'python3'
} else {
    Write-Error "Python is not installed or not in PATH."
    exit 1
}

foreach ($cmd in $requiredCommands) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Write-Error "$cmd is not installed or not in PATH."
        exit 1
    }
}

# Step 1: Check if Git is initialized, and initialize if necessary
if (-not (Test-Path ".git")) {
    Write-Host "Initializing Git repository..."
    git init
    git remote add origin $myrepo
} else {
    Write-Host "Git repository already initialized."
    $remotes = git remote
    if (-not ($remotes -contains 'origin')) {
        Write-Host "Adding remote origin..."
        git remote add origin $myrepo
    }
}

# New Step 2: Copy images from all post subdirectories to the public images folder
Write-Host "Copying images to public directory..."

if (-not (Test-Path $sourcePath)) {
    Write-Error "Source path does not exist: $sourcePath"
    exit 1
}

if (-not (Test-Path $publicImagesPath)) {
    Write-Host "Public images directory does not exist. Creating it..."
    New-Item -Path $publicImagesPath -ItemType Directory -Force
}

Get-ChildItem -Path $sourcePath -Recurse -Include *.jpg, *.png, *.jpeg | ForEach-Object {
    Copy-Item -Path $_.FullName -Destination $publicImagesPath
}

# Step 3: Build the Hugo site
Write-Host "Building the Hugo site..."
try {
    hugo
} catch {
    Write-Error "Hugo build failed."
    exit 1
}

# Step 4: Add changes to Git
Write-Host "Staging changes for Git..."
$hasChanges = (git status --porcelain) -ne ""
if (-not $hasChanges) {
    Write-Host "No changes to stage."
} else {
    git add .
}

# Step 5: Commit changes with a dynamic message
$commitMessage = "New Blog Post on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$hasStagedChanges = (git diff --cached --name-only) -ne ""
if (-not $hasStagedChanges) {
    Write-Host "No changes to commit."
} else {
    Write-Host "Committing changes..."
    git commit -m "$commitMessage"
}

# Step 6: Push all changes to the main branch
Write-Host "Deploying to GitHub Master..."
try {
    git push origin master
} catch {
    Write-Error "Failed to push to Master branch."
    exit 1
}

# Step 7: Push the public folder to the hostinger branch using subtree split and force push
Write-Host "Deploying to GitHub Hostinger..."

# Check if the temporary branch exists and delete it
$branchExists = git branch --list "hostinger-deploy"
if ($branchExists) {
    git branch -D hostinger-deploy
}

# Perform subtree split
try {
    git subtree split --prefix public -b hostinger-deploy
} catch {
    Write-Error "Subtree split failed."
    exit 1
}

# Push to hostinger branch with force
try {
    git push origin hostinger-deploy:hostinger --force
} catch {
    Write-Error "Failed to push to hostinger branch."
    git branch -D hostinger-deploy
    exit 1
}

# Delete the temporary branch
git branch -D hostinger-deploy

Write-Host "All done! Site synced, processed, committed, built, and deployed."