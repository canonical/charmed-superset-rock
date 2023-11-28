# Variables
REPO_FOLDER = charmed-superset-rock
REPO = https://github.com/canonical/$(REPO_FOLDER).git
ROCK_DEV = rock-dev
ROCK_VERSION = 2.1.0
DOCKER_NAME = superset-ui-services
DOCKER_PORT = 8088
DOCKER_ARGS = superset-ui -g 'daemon off:' \; start superset-ui

# Targets
.PHONY: all
all: install-multipass setup-multipass clone install-prerequisites configure-prerequisites pack run

.PHONY: dev
dev: install-mutipass setup-multipass clone install-prereuisites configure-prerequisites

.PHONY: build
buid: pack

.PHONY: install
install: run

.PHONY: install-multipass
install-multipass:
	sudo snap install multipass

.PHONY: setup-multipass
setup-multipass:
	multipass launch 22.04 -n $(ROCK_DEV)

.PHONY: clone
clone:
	multipass exec $(ROCK_DEV) -- git clone $(REPO)

.PHONY: install-prerequisites
install-prerequisites:
	multipass exec $(ROCK_DEV) -- sudo snap install rockcraft --edge --classic
	multipass exec $(ROCK_DEV) -- sudo snap install docker
	multipass exec $(ROCK_DEV) -- sudo snap install lxd
	multipass exec $(ROCK_DEV) -- sudo snap install skopeo --edge --devmode

.PHONY: configure-prerequisites
configure-prerequisites:
	multipass exec $(ROCK_DEV) -- bash -c 'if getent group docker > /dev/null; then echo "The docker group exists"; else sudo groupadd docker && echo "The docker group has been created"; fi; sudo usermod -aG docker $$USER'
	multipass exec $(ROCK_DEV) -- sudo lxd init --auto

.PHONY: pack
pack:
	multipass exec $(ROCK_DEV) -- bash -c 'cd $(REPO_FOLDER) && rockcraft pack'

.PHONY: run
run:
	multipass exec $(ROCK_DEV) -- bash -c 'cd $(REPO_FOLDER) &&\
		sudo skopeo --insecure-policy copy oci-archive:charmed-superset-rock_$(ROCK_VERSION)_amd64.rock docker-daemon:/charmed-superset-rock:$(ROCK_VERSION)'
	multipass exec $(ROCK_DEV) -- bash -c 'cd $(REPO_FOLDER) &&\
	docker run -d --name $(DOCKER_NAME) -p $(DOCKER_PORT):$(DOCKER_PORT) charmed-superset-rock:$(ROCK_VERSION) --args $(DOCKER_ARGS)'
