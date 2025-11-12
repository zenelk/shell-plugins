function_redefine grc
function grc() {
  git add -A
  git commit --amend --no-edit
  git push -f
}
