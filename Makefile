NAME := postfix
TAG := latest
IMAGE_NAME := panubo/$(NAME)

.PHONY: *

help:
	@printf "$$(grep -hE '^\S+:.*##' $(MAKEFILE_LIST) | sed -e 's/:.*##\s*/:/' -e 's/^\(.\+\):\(.*\)/\\x1b[36m\1\\x1b[m:\2/' | column -c2 -t -s :)\n"

bash: ## Runs a bash shell in the docker image
	docker run --rm -it -e MAILNAME=mail.example.com $(IMAGE_NAME):latest bash

run: ## Runs the docker image in a test mode
	$(eval ID := $(shell docker run -d --name postfix -e RELAYHOST=172.17.0.2 -e MAILNAME=mail.example.com -e SIZELIMIT=20480000 -e LOGOUTPUT=/var/log/maillog $(IMAGE_NAME):latest))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ smtp://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}

run-tls: ## Runs the docker image in a test mode with TLS
		$(eval ID := $(shell docker run -d --name postfix --hostname mail.example.com -e RELAYHOST=172.17.0.2 -e MAILNAME=mail.example.com -e USE_TLS=yes $(IMAGE_NAME):latest))
		$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
		@echo "Running ${ID} @ smtp://${IP}"
		@docker attach ${ID}
		@docker kill ${ID}

run-dkim: ## Runs the docker image in a test mode with DKIM
	$(eval ID := $(shell docker run -d --name postfix --hostname mail.example.com -e RELAYHOST=172.17.0.2 -e MAILNAME=mail.example.com -e DKIM_DOMAINS=foo.example.com,bar.example.com,example.net -e USE_DKIM=yes -v `pwd`/dkim.key:/etc/opendkim/dkim.key $(IMAGE_NAME):latest))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ smtp://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}

run-all-dkim: ## Runs the docker image in a test mode. All settings
	$(eval ID := $(shell docker run -d --name postfix --hostname mail.example.com -e RELAYHOST=172.17.0.2 -e MAILNAME=mail.example.com -e DKIM_DOMAINS=foo.example.com,bar.example.com,example.net -e DKIM_SELECTOR=6091aa68-f43d-47cf-a52e-bafda525d0bc -e USE_DKIM=yes -v `pwd`/dkim.key:/etc/opendkim/dkim.key $(IMAGE_NAME):latest))
	$(eval IP := $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' ${ID}))
	@echo "Running ${ID} @ smtp://${IP}"
	@docker attach ${ID}
	@docker kill ${ID}

build: ## Builds docker image latest
	docker build --pull -t $(IMAGE_NAME):$(TAG) .

push: ## Pushes the docker image to hub.docker.com
	docker push $(IMAGE_NAME):$(TAG)

clean: ## Remove built image
	docker rmi $(IMAGE_NAME):$(TAG)

_ci_test:
	true
