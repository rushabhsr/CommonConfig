alias cms='cd /home/rushabhsr/applications/edel-claims_management && python -m venv venv && source venv/bin/activate'
alias cmsops='cd /home/rushabhsr/applications/cms-claim-operation && python -m venv venv && source venv/bin/activate'
alias cas='cd /home/rushabhsr/applications/cms-assessment-service && python -m venv venv && source venv/bin/activate'
alias cmspay='cd /home/rushabhsr/applications/cms-payment-service && python -m venv venv && source venv/bin/activate'
alias audit='cd /home/rushabhsr/applications/cms-audit-log && python -m venv venv && source venv/bin/activate'

alias cascelery='celery -A cms_assessment_service.celery_app worker --pool solo -l info'
alias cmscelery='celery -A CMS.celery_app worker --pool solo -l info'
alias dbshell='python manage.py dbshell'
alias jobber='cd /home/rushabhsr/applications/edel-claim-jobber'
alias migrate='python manage.py migrate'
alias mm='python manage.py makemigrations'
alias opscelery='celery -A cms_claim_operation.celery_app worker --pool solo -l info'
alias paycelery='celery -A cms_payment.celery_app worker --pool solo -l info'
alias run-help=man
alias runcas='python manage.py runserver 8005'
alias runlog='python manage.py runserver 8002'
alias runops='python manage.py runserver 8003'
alias runpay='python manage.py runserver 8006'
alias runserver='python manage.py runserver'

# Define functions for each service
opsclogs() { sudo docker logs --tail ${1:-40} -f cms-claim-operations-celery; }
payclogs() { sudo docker logs --tail ${1:-40} -f cms-payment-service-celery; }
caslogs() { sudo docker logs --tail ${1:-40} -f cms-assessment-service; }
opslogs() { sudo docker logs --tail ${1:-40} -f cms-claim-operations; }
paylogs() { sudo docker logs --tail ${1:-40} -f cms-payment-service; }
casclogs() { sudo docker logs --tail ${1:-40} -f cms-assessment-service-celery; }
auditlogs() { sudo docker logs --tail ${1:-40} -f cms-audit-log; }
cmsclogs() { sudo docker logs --tail ${1:-40} -f registration-docker-celery; }
cmslogs() { sudo docker logs --tail ${1:-40} -f claim-management-system; }
jobberlogs() { sudo docker logs --tail ${1:-40} -f cms-claim-jobber; }

# Optionally, you can use aliases to provide a shorthand (optional step)
alias opsclogs='opsclogs'
alias payclogs='payclogs'
alias caslogs='caslogs'
alias opslogs='opslogs'
alias paylogs='paylogs'
alias casclogs='casclogs'
alias auditlogs='auditlogs'
alias cmsclogs='cmsclogs'
alias cmslogs='cmslogs'
alias jobberlogs='jobberlogs'

alias auditrestart='sudo docker restart cms-audit-log'
alias casrestart='sudo docker restart cms-assessment-service-celery && sudo docker restart cms-assessment-service'
alias cmsrestart='sudo docker restart registration-docker-celery && sudo docker restart claim-management-system'
alias opsrestart='sudo docker restart cms-claim-operations-celery && sudo docker restart cms-claim-operations'
alias payrestart='sudo docker restart cms-payment-service-celery && sudo docker restart cms-payment-service'
alias jobberrestart='sudo docker restart cms-claim-jobber'

alias auditrestart='sudo docker stop cms-audit-log'
alias casstop='sudo docker stop cms-assessment-service-celery && sudo docker stop cms-assessment-service'
alias cmsstop='sudo docker stop registration-docker-celery && sudo docker stop claim-management-system'
alias opsstop='sudo docker stop cms-claim-operations-celery && sudo docker stop cms-claim-operations'
alias paystop='sudo docker stop cms-payment-service-celery && sudo docker stop cms-payment-service'
alias jobberstop='sudo docker stop cms-claim-jobber'


alias opsclogsfile='f() { sudo docker logs --tail ${1:-20000} cms-claim-operations-celery >& ~/logs/cms-claim-operations-celery_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias payclogsfile='f() { sudo docker logs --tail ${1:-20000} cms-payment-service-celery >& ~/logs/cms-payment-service-celery_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias caslogsfile='f() { sudo docker logs --tail ${1:-20000} cms-assessment-service >& ~/logs/cms-assessment-service_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias opslogsfile='f() { sudo docker logs --tail ${1:-20000} cms-claim-operations >& ~/logs/cms-claim-operations_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias paylogsfile='f() { sudo docker logs --tail ${1:-20000} cms-payment-service >& ~/logs/cms-payment-service_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias casclogsfile='f() { sudo docker logs --tail ${1:-20000} cms-assessment-service-celery >& ~/logs/cms-assessment-service-celery_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias auditlogsfile='f() { sudo docker logs --tail ${1:-20000} cms-audit-log >& ~/logs/cms-audit-log_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias cmsclogsfile='f() { sudo docker logs --tail ${1:-20000} registration-docker-celery >& ~/logs/registration-docker-celery_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias cmslogsfile='f() { sudo docker logs --tail ${1:-20000} claim-management-system >& ~/logs/claim-management-system_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias jobberlogsfile='f() { sudo docker logs --tail ${1:-20000} cms-claim-jobber >& ~/logs/cms-claim-jobber_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'
alias notifierlogsfile='f() { sudo docker logs --tail ${1:-20000} pensive_visvesvaraya >& ~/logs/pensive_visvesvaraya_$(date +\%d\%m\%Y_\%H\%M\%S).log; }; f'


alias generate_all_logs='
  opsclogsfile && \
  payclogsfile && \
  caslogsfile && \
  opslogsfile && \
  paylogsfile && \
  casclogsfile && \
  auditlogsfile && \
  cmsclogsfile && \
  cmslogsfile && \
  jobberlogsfile'


alias sf-cv='cd /home/rushabhsr/applications/cms-frontend && npm start'
alias sb-cv='cd /home/rushabhsr/applications/edel-claims_management && sudo docker-compose up'
alias sf-staar='cd /home/rushabhsr/applications/pulse-ui && npm start'
alias sb-staar='cd /home/rushabhsr/applications/pulse-api && npm run dev'

alias qassh='sshpass -p "2YNyKp^'\''FTP+:F+A" ssh cms-admin@172.31.0.19'
alias uatssh='sshpass -p "2YNyKp^'\''FTP+:F+A" ssh cms-admin@10.226.241.35'


code-cv() {
    code $HOME/applications/cms-frontend &
    wait $!
    
    code $HOME/applications/edel-claims_management &
    wait $!
    
    code $HOME/applications/cms-claim-operation &
    wait $!
    
    code $HOME/applications/cms-assessment-service &
    wait $!
    
    code $HOME/applications/cms-payment-service &
    wait $!
}


delkeys() {
  redis-cli --scan --pattern "$1" | xargs redis-cli del
}

mrprod() {
  glab mr create -s "${2:-$(git rev-parse --abbrev-ref HEAD)}" --target-branch production --title "$1-$(date +%d%m%Y)" -d "$1" -y
}

mruat() {
  glab mr create -s "${2:-$(git rev-parse --abbrev-ref HEAD)}" --target-branch uat --title "$1-$(date +%d%m%Y)-RS" -d "$1" -y
}

mrqa() {
  glab mr create -s "${2:-$(git rev-parse --abbrev-ref HEAD)}" --target-branch qa --title "$1-$(date +%d%m%Y)-RS" -d "$1" -y
}

mrdev() {
  glab mr create -s "${2:-$(git rev-parse --abbrev-ref HEAD)}" --target-branch development --title "$1-$(date +%d%m%Y)-RS" -d "$1" -y
}

