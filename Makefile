docker_tag 	= panubo/postfix

build:
	docker build -t $(docker_tag) .

bash:
	docker run --rm -it -e MAILNAME=mail.example.com $(docker_tag) bash

run:
	$(eval ID := $(shell docker run -d -e MAILNAME=mail.example.com -e SIZELIMIT=20480000 -e LOGOUTPUT=/var/log/maillog ${docker_tag}))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ smtp://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}

run-dkim:
	$(eval ID := $(shell docker run -d --hostname mail.example.com -e MAILNAME=mail.example.com -e DKIM_DOMAINS=foo.example.com,bar.example.com -e USE_DKIM=yes -v `pwd`/dkim.key:/etc/opendkim/dkim.key ${docker_tag}))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ smtp://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}
