NAME := postfix
TAG := latest
IMAGE_NAME := panubo/$(NAME)

.PHONY: help bash run run-dkim run-all-dkim build push clean

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
	docker build --pull -t $(IMAGE_NAME):latest .

push: ## Pushes the docker image to hub.docker.com
	# Don't --pull here, we don't want any last minute upsteam changes
	docker build -t $(IMAGE_NAME):$(TAG) .
	docker tag $(IMAGE_NAME):$(TAG) $(IMAGE_NAME):latest
	docker push $(IMAGE_NAME):$(TAG)
	docker push $(IMAGE_NAME):latest

clean: ## Remove built images
	docker rmi $(IMAGE_NAME):latest
	docker rmi $(IMAGE_NAME):$(TAG)
