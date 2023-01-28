all: build-all push-all build-latest push-latest

build-all:
	yq -r '.versions | sort | .[]' versions.yaml | xargs -I '{}' sh -c 'fromTag="{}" tag="{}" && docker compose build'

push-all:
	yq -r '.versions | sort | .[]' versions.yaml | xargs -I '{}' sh -c 'fromTag="{}" tag="{}" && docker compose push'

build-latest:
	yq -r '.versions | sort | reverse | .[0]' versions.yaml | xargs -I '{}' sh -c 'fromTag="{}" tag=latest && docker compose build'

push-latest:
	yq -r '.versions | sort | reverse | .[0]' versions.yaml | xargs -I '{}' sh -c 'tag=latest && docker compose push'

remove-all:
	yq -r '.versions | sort | .[]' versions.yaml | xargs -I '{}' sh -c 'docker rmi dhis2/postgresql-curl:{}'
