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

alias sf='if [ "$(basename "$PWD")" != "frontend" ]; then cd frontend; fi && npm run dev'
alias sb='if [ "$(basename "$PWD")" != "backend" ]; then cd backend; fi && npm run dev'
alias sb-indi="cd ~/applications/indi-wheel/backend && sudo docker-compose up"
alias sf-indi="cd ~/applications/indi-wheel/frontend && npm run dev"
alias rd="npm run dev"

# Function to create aliases for each folder in ~/applications
create_app_aliases() {
  local app_dir=~/applications
  for dir in "$app_dir"/*/; do
    folder_name=$(basename "$dir")
    alias "$folder_name"="cd \"$dir\""
  done
}
create_app_aliases
