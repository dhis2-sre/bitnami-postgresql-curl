all: build-all push-all

build-all:
	yq -r '.versions | sort | .[]' versions.yaml | xargs -I '{}' sh -c 'fromTag="{}" tag="{}" docker compose build'

push-all:
	yq -r '.versions | sort | .[]' versions.yaml | xargs -I '{}' sh -c 'fromTag="{}" tag="{}" docker compose push'

remove-all:
	yq -r '.versions | sort | .[]' versions.yaml | xargs -I '{}' sh -c 'docker rmi dhis2/postgresql-curl:{}'
