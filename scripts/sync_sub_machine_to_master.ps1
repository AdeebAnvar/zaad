# From repo root: merge origin/sub_machine into local master and push master.
# Use when GitHub Actions is disabled or branch protection blocked the workflow.
Param(
    [switch]$NoPush
)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $root

git fetch origin master sub_machine
git checkout master
git merge origin/sub_machine --no-edit
if (-not $NoPush) {
    git push origin master
}
