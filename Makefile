docker_tag 	= freinet/postfix-relay

build:
	docker build -t $(docker_tag) .

bash:
	docker run --rm -it -e MAILNAME=mail.example.com $(docker_tag) bash

run:
	$(eval ID := $(shell docker run -d --name postfix -e RELAYHOST=172.17.0.2 -e MAILNAME=mail.example.com -e SIZELIMIT=20480000 -e LOGOUTPUT=/var/log/maillog ${docker_tag}))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ smtp://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}

run-dkim:
	$(eval ID := $(shell docker run -d --name postfix --hostname mail.example.com -e RELAYHOST=172.17.0.2 -e MAILNAME=mail.example.com -e DKIM_DOMAINS=foo.example.com,bar.example.com,example.net -e USE_DKIM=yes -v `pwd`/dkim.key:/etc/opendkim/dkim.key ${docker_tag}))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ smtp://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}

run-all-dkim:
	$(eval ID := $(shell docker run -d --name postfix --hostname mail.gc.com -e RELAYHOST=172.17.0.2 -e MAILNAME=mail.gc.com -e 'DKIM_DOMAINS=campus.gradconnection.com' -e DKIM_SELECTOR=6091aa68-f43d-47cf-a52e-bafda525d0bc -e USE_DKIM=yes -v `pwd`/dkim.key:/etc/opendkim/dkim.key ${docker_tag}))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ smtp://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}
