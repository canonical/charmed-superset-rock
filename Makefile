# Variables
REPO_FOLDER = charmed-superset-rock
REPO = https://github.com/canonical/$(REPO_FOLDER).git
ROCK_DEV = rock-dev
ROCK_VERSION = 2.1.0
UBUNTU_VER = 22.04
DOCKER_NAME = superset-ui-services
DOCKER_PORT = 8088
DOCKER_ARGS = superset-ui -g 'daemon off:' \; start superset-ui

REQUIRED_VARS := ROCK_DEV UBUNTU_VER REPO_FOLDER DOCKER_NAME DOCKER_PORT DOCKER_ARGS ROCK_VERSION

$(foreach var,$(REQUIRED_VARS),\
    $(if $(value $(var)),,$(error $(var) is not set)))

# Targets
.PHONY: all dev build install clean clean-all

all: dev build install

dev: install-multipass setup-multipass clone install-prerequisites configure-prerequisites

build: pack

install: run

clean-all:
	multipass delete -p $(ROCK_DEV)

install-multipass:
	sudo snap install multipass

setup-multipass:
	multipass launch $(UBUNTU_VER) -n $(ROCK_DEV) -m 8g -c 2 -d 20G

clone:
	multipass exec $(ROCK_DEV) -- git clone $(REPO)

install-prerequisites:
	multipass exec $(ROCK_DEV) -- bash -c 'sudo snap install rockcraft --edge --classic &&\
	sudo snap install skopeo --edge --devmode &&\
	sudo snap install lxd && sudo lxd init --auto'
	multipass exec $(ROCK_DEV) -- sudo snap install docker

configure-prerequisites:
	multipass exec $(ROCK_DEV) -- bash -c 'if getent group docker > /dev/null; then echo "The docker group exists"; else sudo groupadd docker && echo "The docker group has been created"; fi; sudo usermod -aG docker $$USER'
	multipass exec $(ROCK_DEV) -- bash -c 'sudo snap disable docker && sudo snap enable docker'

.PHONY: pack
pack:
	multipass exec $(ROCK_DEV) -- bash -c 'cd $(REPO_FOLDER) && rockcraft pack'

run:
	multipass exec $(ROCK_DEV) -- bash -c 'cd $(REPO_FOLDER) &&\
		sudo skopeo --insecure-policy copy oci-archive:charmed-superset-rock_$(ROCK_VERSION)-$(UBUNTU_VER)-edge_amd64.rock docker-daemon:charmed-superset-rock:$(ROCK_VERSION)'
	multipass exec $(ROCK_DEV) -- bash -c "cd $(REPO_FOLDER) &&\
	docker run -d --name $(DOCKER_NAME) -p $(DOCKER_PORT):$(DOCKER_PORT) charmed-superset-rock:$(ROCK_VERSION) --args $(DOCKER_ARGS)"
