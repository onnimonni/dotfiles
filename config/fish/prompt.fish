# Terminal startup script
function fish_greeting
    echo -n "Welcome to $USER's "
    set_color green
    echo -n fish
    set_color normal
    echo "!"
end

# Terminal window title
# This is for rescuetime
function fish_title
    echo -n (whoami)@(hostname):(pwd)
end

# Custom prompt: Show current branch in shell
function fish_prompt
  # Quite nice source for colors: http://colours.neilorangepeel.com/
  echo -n (whoami)
  set_color "#FFDAB9" #peachpuff
  echo -n '@'
  set_color normal
  echo -n (hostname)':'
  set_color "#E9967A" #darksalmon
  echo -n (prompt_pwd)
  set_color normal
  echo -n '> '
end

# Show git branch on right prompt
function fish_right_prompt
  if is_git
    if is_git_dirty
      set_color red
    else if is_git_ahead
      set_color yellow
    else
      set_color green
    end
    echo -n (git_branch)
    set_color normal
    echo -n ' '
  end
end

