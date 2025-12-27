function DEBUG(){
    echo -e "`date +%a_%d_%m_%y%H_%M_%S`: $1"
}
export DEBUG

dockerclean() {
  if [ -n "$1" ]; then
    echo "Deleting containers, images, and volumes starting with: $1"

    # Remove all containers where image name or container name contains $1
    docker ps -a --format '{{.ID}} {{.Image}} {{.Names}}' | grep "$1" | awk '{print $1}' | xargs -r docker rm -f

    # Remove images where name starts with $1
    docker images --format '{{.Repository}}:{{.Tag}} {{.ID}}' | grep "^$1" | awk '{print $2}' | xargs -r docker rmi -f

    # Remove volumes starting with $1
    docker volume ls --format '{{.Name}}' | grep "^$1" | xargs -r docker volume rm
  else
    echo "Running full system prune..."
    sudo docker system prune -a --volumes --force
  fi
}

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)"
fi

alias rm='rm -v'
alias ls20='ls -lrth | tail -20'
alias ls10='ls -lrth | tail -10'

# Aliases to start Apache2 and MySQL
alias start_php='sudo systemctl start apache2 && sudo systemctl start mysql'
# Aliases to stop Apache2 and MySQL
alias stop_php='sudo systemctl stop apache2 && sudo systemctl stop mysql'

# Function to create aliases for each folder in ~/applications
APPS_DIR=$HOME/applications
create_app_aliases() {
  for dir in "$APPS_DIR"/*/; do
    folder_name=$(basename "$dir")
    alias "$folder_name"="cd \"$dir\""
    alias "code-$folder_name"="cd $APPS_DIR/$folder_name && code \"$dir\""
    alias "sf-$folder_name"="cd \"$dir\"frontend && rd"
    alias "sb-$folder_name"="cd \"$dir\"backend && rd"
    
    # Create kiro-cli agent aliases
    agent_name=$(echo "$folder_name" | sed 's/_/-/g')
    alias "kiro-$folder_name"="kiro-cli chat --agent $agent_name"
    alias "k-$folder_name"="kiro-cli chat --agent $agent_name"
  done

  for dir in "$HOME"/my_applications/*/; do
    folder_name=$(basename "$dir")
    alias "$folder_name"="cd \"$dir\""
    alias "code-$folder_name"="code \"$dir\""
    alias "sf-$folder_name"="cd \"$dir\"frontend && rd"
    alias "sb-$folder_name"="cd \"$dir\"backend && rd"
    
    # Create kiro-cli agent aliases for my_applications too
    agent_name=$(echo "$folder_name" | sed 's/_/-/g')
    alias "kiro-$folder_name"="kiro-cli chat --agent $agent_name"
    alias "k-$folder_name"="kiro-cli chat --agent $agent_name"
  done
}

create_app_aliases

alias lapps="cd ${APPS_DIR}/ && ls -lrth"
alias ltapps="cd ${APPS_DIR}/temp/ && ls -lrth"
alias rd="npm run dev"
alias sf='if [ "$(basename "$PWD")" != "frontend" ]; then cd frontend; fi && rd'
alias sb='if [ "$(basename "$PWD")" != "backend" ]; then cd backend; fi && rd'

alias gbDexcept='f(){ git branch --format="%(refname:short)" | grep -vE "($(IFS="|"; echo "$*"))" | grep -v "$(git rev-parse --abbrev-ref HEAD)" | xargs -r git branch -D; }; f'
alias lstree='find . -type d | while read dir; do echo "${dir}"; ls -p "$dir" | grep -v / | sed "s/^/  ├── /"; done'

alias init-react-structure='mkdir -p src/{app/{router,context,hooks,config},components/{layout,common,auth},features/{auth/pages,dashboard/{admin,user}},pages,assets,styles,utils} && touch \
src/app/router/AppRouter.jsx \
src/app/context/AuthContext.jsx \
src/app/hooks/useAuth.js \
src/app/config/roles.js \
src/features/auth/pages/Login.jsx \
src/features/dashboard/admin/AdminDashboard.jsx \
src/features/dashboard/user/UserDashboard.jsx \
src/pages/NotFound.jsx \
src/pages/Unauthorized.jsx \
src/main.jsx \
src/index.css'

alias sb-indi="cd ${APPS_DIR}/indi-wheel/backend && sudo docker-compose up"
alias sb-horilla="cd ${APPS_DIR}/horilla && sudo docker-compose up"
alias sb-hrms="cd ${APPS_DIR}/hrms/docker/ && sudo docker-compose up"
alias sb-candidperks="cd ${APPS_DIR}/candidperks/backend && uvicorn app.main:app --reload --host 0.0.0.0 --port 8001"

redis-clear() {
  local pattern="*"
  if [ -n "$1" ]; then
    pattern="*$1*"
  fi
  redis-cli --scan --pattern "$pattern" | xargs -r redis-cli del
}

spillover() {
    if [ $# -eq 0 ]; then
        echo "Usage: spillover <previous_spillover_mins> <start_time> [end_time] [session_mins]"
        echo "Example: spillover 90 \"14:53\""
        echo "         spillover 90 \"14:53\" \"16:30\""
        echo "         spillover 90 \"14:53\" \"16:30\" 120"
        return 1
    fi

    local previous_spillover_mins="$1"
    local start_time="$2"
    local end_time="${3:-$(date +"%H:%M")}"
    local session_mins="${4:-120}"

    # Convert times to minutes since midnight (handle leading zeros)
    local end_hour=$(echo "$end_time" | cut -d: -f1 | sed 's/^0*//')
    local end_min=$(echo "$end_time" | cut -d: -f2 | sed 's/^0*//')
    local start_hour=$(echo "$start_time" | cut -d: -f1 | sed 's/^0*//')
    local start_min=$(echo "$start_time" | cut -d: -f2 | sed 's/^0*//')
    
    # Handle empty strings (when time is 00)
    [ -z "$end_hour" ] && end_hour=0
    [ -z "$end_min" ] && end_min=0
    [ -z "$start_hour" ] && start_hour=0
    [ -z "$start_min" ] && start_min=0

    local end_mins=$((end_hour * 60 + end_min))
    local prev_mins=$((start_hour * 60 + start_min))

    # If previous time is greater than current time, assume it's from yesterday
    if [ $prev_mins -gt $end_mins ]; then
        prev_mins=$((prev_mins - 1440))
    fi

    # Calculate night and day minutes separately
    local night_mins=0
    local day_mins=0
    
    # Night hours: 22:00-08:00 (10pm-8am)
    local night_start=1320  # 22:00 in minutes
    local night_end=480     # 08:00 in minutes

    # Calculate minutes in each period
    local current_mins=$prev_mins
    while [ $current_mins -lt $end_mins ]; do
        # Check if current minute is in night hours
        local hour_mins=$((current_mins % 1440))
        if [ $hour_mins -ge $night_start ] || [ $hour_mins -lt $night_end ]; then
            night_mins=$((night_mins + 1))
        else
            day_mins=$((day_mins + 1))
        fi
        
        current_mins=$((current_mins + 1))
    done

    # Apply 1.5x multiplier only to night minutes
    local night_weighted=$((night_mins * 3 / 2))
    local diff_mins=$((day_mins + night_weighted))

    local new_total=$((previous_spillover_mins + diff_mins))

    # Calculate sessions and spillover
    local sessions=$((new_total / session_mins))
    local spillover_mins=$((new_total % session_mins))

    if [ $sessions -eq 0 ]; then
        echo "Spillover ~ ${spillover_mins}mins"
    else
        if [ $sessions -eq 1 ]; then
            echo "Please drop a message in the group after that"
        else
            echo "Please drop ${sessions} messages in the group after that"
        fi
        echo "Spillover ~ ${spillover_mins}mins"
    fi
    echo "Start Time: $start_time, End Time: $end_time (Day: ${day_mins}min, Night: ${night_mins}min)"
}
