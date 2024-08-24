# `cat` with beautiful colors. uses Pygments if installed.
# Otherwise fallbacks to basic cat
function c --description 'Print file contents with colors'
  if command_exists bat
    bat $argv
  else
    cat --color=auto $argv
  end
end
