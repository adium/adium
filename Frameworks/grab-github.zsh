#!/bin/zsh -f

#Download an unversioned copy of the files in a GitHub repository.
#Usage: grab-github username projectname commit-ID
#The files will exist in a folder under the project name.
#A file in the same folder named .github_commit_id will contain the commit ID of the version you grabbed. This is mainly useful when you're re-grabbing unchanged source with an updated commit ID, such as after a rebase.

gh_user="$1"
gh_project="$2"
gh_commit="$3"

if test -e "$gh_project"; then
	echo "$gh_project already exists here - aborting" >> /dev/stderr
	exit 1
fi

curl -L "http://github.com/$gh_user/$gh_project/tarball/$gh_commit" | tar xzf -

mv "${gh_user}-${gh_project}-${gh_commit}" "$gh_project"
echo "$gh_commit" > "$gh_project/.github_commit_id"
