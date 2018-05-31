#!/bin/bash
echo "geminidata-entrypoint.sh initialized"

set -e

echo "Hi $NAME, normal Ghost deployment has started"

# allow the container to be started with `--user`
if [[ "$*" == node*current/index.js* ]] && [ "$(id -u)" = '0' ]; then
	chown -R node "$GHOST_CONTENT"
	exec su-exec node "$BASH_SOURCE" "$@"
fi

if [[ "$*" == node*current/index.js* ]]; then
	baseDir="$GHOST_INSTALL/content.orig"
	for src in "$baseDir"/*/ "$baseDir"/themes/*; do
		src="${src%/}"
		target="$GHOST_CONTENT/${src#$baseDir/}"
		mkdir -p "$(dirname "$target")"
		if [ ! -e "$target" ]; then
			tar -cC "$(dirname "$src")" "$(basename "$src")" | tar -xC "$(dirname "$target")"
		fi
	done

	knex-migrator-migrate --init --mgpath "$GHOST_INSTALL/current"
fi

echo "$NAME, normal Ghost deployment finished. Now adding S3 hook"

npm install ghost-storage-adapter-s3
mkdir -p ./content/adapters/storage
cp -r ./node_modules/ghost-storage-adapter-s3 ./content/adapters/storage/s3

echo "AWS S3 storage blocked added to config.production.json"

exec "$@"
