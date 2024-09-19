function DEBUG(){
    echo -e "`date +%a_%d_%m_%y%H_%M_%S`: $1"
}
export DEBUG

if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    eval "$(ssh-agent -s)"
fi

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
alias sb-indi="cd ${APPS_DIR}/indi-wheel/backend && sudo docker-compose up"
alias sf-indi="cd ${APPS_DIR}/indi-wheel/frontend && npm run dev"
