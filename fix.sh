#!/bin/sh

git filter-branch --env-filter '

OLD_EMAIL="none@none"
CORRECT_NAME="Your Correct Name"
CORRECT_EMAIL="your-correct-email@example.com"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
  echo $GIT_COMMITTER_NAME
    # export GIT_COMMITTER_NAME="$CORRECT_NAME"
    # export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
# if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
# then
#     export GIT_AUTHOR_NAME="$CORRECT_NAME"
#     export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
# fi
' --tag-name-filter cat -- --branches --tags
