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

alias opsclogs='f() { docker logs --tail ${1:-10} -f cms-claim-operations-celery; }; f'
alias payclogs='f() { docker logs --tail ${1:-10} -f cms-payment-service-celery; }; f'
alias caslogs='f() { docker logs --tail ${1:-10} -f cms-assessment-service; }; f'
alias opslogs='f() { docker logs --tail ${1:-10} -f cms-claim-operations; }; f'
alias paylogs='f() { docker logs --tail ${1:-10} -f cms-payment-service; }; f'
alias casclogs='f() { docker logs --tail ${1:-10} -f cms-assessment-service-celery; }; f'
alias auditlogs='f() { docker logs --tail ${1:-10} -f cms-audit-log; }; f'
alias cmsclogs='f() { docker logs --tail ${1:-10} -f registration-docker-celery; }; f'
alias cmslogs='f() { docker logs --tail ${1:-10} -f claim-management-system; }; f'
alias jobberlogs='f() { docker logs --tail ${1:-10} -f cms-claim-jobber; }; f'

alias auditrestart='docker restart cms-audit-log'
alias casrestart='docker restart cms-assessment-service-celery && docker restart cms-assessment-service'
alias cmsrestart='docker restart registration-docker-celery && docker restart claim-management-system'
alias opsrestart='docker restart cms-claim-operations-celery && docker restart cms-claim-operations'
alias payrestart='docker restart cms-payment-service-celery && docker restart cms-payment-service'
alias jobberrestart='docker restart cms-claim-jobber'

alias auditrestart='docker stop cms-audit-log'
alias casstop='docker stop cms-assessment-service-celery && docker stop cms-assessment-service'
alias cmsstop='docker stop registration-docker-celery && docker stop claim-management-system'
alias opsstop='docker stop cms-claim-operations-celery && docker stop cms-claim-operations'
alias paystop='docker stop cms-payment-service-celery && docker stop cms-payment-service'
alias jobberstop='docker stop cms-claim-jobber'


alias opsclogsfile='sudo docker logs --tail 20000 cms-claim-operations-celery >& ~/logs/cms-claim-operations-celery_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias payclogsfile='sudo docker logs --tail 20000 cms-payment-service-celery >& ~/logs/cms-payment-service-celery_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias caslogsfile='sudo docker logs --tail 20000 cms-assessment-service >& ~/logs/cms-assessment-service_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias opslogsfile='sudo docker logs --tail 20000 cms-claim-operations >& ~/logs/cms-claim-operations_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias paylogsfile='sudo docker logs --tail 20000 cms-payment-service >& ~/logs/cms-payment-service_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias casclogsfile='sudo docker logs --tail 20000 cms-assessment-service-celery >& ~/logs/cms-assessment-service-celery_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias auditlogsfile='sudo docker logs --tail 20000 cms-audit-log >& ~/logs/cms-audit-log_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias cmsclogsfile='sudo docker logs --tail 20000 registration-docker-celery >& ~/logs/registration-docker-celery_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias cmslogsfile='sudo docker logs --tail 20000 claim-management-system >& ~/logs/claim-management-system_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias jobberlogsfile='sudo docker logs --tail 20000 cms-claim-jobber >& ~/logs/cms-claim-jobber_$(date +\%d\%m\%Y_\%H\%M\%S).log'
alias notifierlogsfile='sudo docker logs --tail 20000 pensive_visvesvaraya >& ~/logs/pensive_visvesvaraya_$(date +\%d\%m\%Y_\%H\%M\%S).log'


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

