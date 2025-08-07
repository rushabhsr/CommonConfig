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
  done

  for dir in "$HOME"/my_applications/*/; do
    folder_name=$(basename "$dir")
    alias "$folder_name"="cd \"$dir\""
    alias "code-$folder_name"="code \"$dir\""
    alias "sf-$folder_name"="cd \"$dir\"frontend && rd"
    alias "sb-$folder_name"="cd \"$dir\"backend && rd"
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

