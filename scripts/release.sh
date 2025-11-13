#!/bin/bash
set -euo pipefail

VERSION="$1"  # first argument passed to the script
RELEASE_BRANCH="release-$VERSION"
TAG="v$VERSION"

git config --global user.name "release plugin"
git config --global user.email "release-plugin@users.noreply.github.com"

# create release branch
git checkout -b ""$RELEASE_BRANCH""

mvn versions:set -ntp -DnewVersion="$VERSION"
git add -u

git status
git config --list --global

git commit -m "Prepare release $VERSION"

git tag -a "$TAG" -m "Release $TAG"

# merge to master
git checkout master
git merge --no-edit "$RELEASE_BRANCH"

# merge to develop
git checkout develop
git merge --no-edit "$RELEASE_BRANCH"

# create new snapshot version
NEXT_VERSION="$(echo "$VERSION" | perl -pe 's{^(([0-9]\.)+)?([0-9]+)$}{$1 . ($3 + 1) . "-SNAPSHOT"}e')"
mvn versions:set -ntp -DnewVersion="$NEXT_VERSION"

# alternatively:
# mvn build-helper:parse-version versions:set -DnewVersion=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.nextIncrementalVersion}-SNAPSHOT
# NEXT_VERSION=$(mvn help:evaluate -Dexpression=project.version -q -DforceStdout)

git add -u
git status
git commit -m "Start next iteration with $NEXT_VERSION"

# push everything
git push --atomic origin "$RELEASE_BRANCH" master develop --follow-tags # all or nothing