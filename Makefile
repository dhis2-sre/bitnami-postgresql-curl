SHELL := /bin/bash

build-and-push-all:
	yq -r '.versions[]' versions.yaml | xargs -I '{}' sh -c 'export fromTag="{}" && docker compose build && docker compose push'
