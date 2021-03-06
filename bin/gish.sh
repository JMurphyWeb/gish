#!/bin/sh

writeGitCredentials() {
  echo "Enter your github username"
  read USER_NAME
  echo "Enter your github access token"
  read ACCESS_TOKEN
  echo "USER_NAME=$USER_NAME\nACCESS_TOKEN=$ACCESS_TOKEN" > ~/.gish.env
  source ~/.gish.env
}

# Ensure there is a file to store github credentials
if [ ! -f ~/.gish.env ]
then
  touch ~/.gish.env
  writeGitCredentials
fi

# source gish.env if variables are not accessible
if [ -z "$USER_NAME" ] || [ -z "$ACCESS_TOKEN" ] ; then
  source ~/.gish.env
  # If varables are not available, ask for them again
  if [ -z "$USER_NAME" ] || [ -z "$ACCESS_TOKEN" ] ; then
    writeGitCredentials
  fi
fi


# Exit if we are not in a git directory
if [ ! -d .git ]; then
  echo "You are not in a git directory"
  exit 1
fi




GITHUB_URL=https://api.github.com

getOrgRepo() {
  MYVAR=$(exec git remote -v | grep origin | grep push)
  NAME=${MYVAR%.git*}
  NAME=${NAME#*//github.com}
  echo $NAME
}

ORG_REPO=$(getOrgRepo)


# --------------------------------------- #
# --------------------------------------- #

# gish get <issue_num>
if [ $1 = get ]
then
  re='^[0-9]+$'
  if [[ $2 =~ $re ]]
  then
    ISSUE_NUM=$2
    curl -s -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues/$ISSUE_NUM | grep 'body\|login'
    curl -s -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues/$ISSUE_NUM/comments | grep 'body\|login'

  # gish get
  else
    curl -s -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues | grep '"number"\|"title"\|"comments"'
  fi
fi

# gish comment <issue_num> <comment>
if [ $1 = comment ]
then
  ISSUE_NUM=$2
  COMMENT=$3
  curl -s -d "{ \"body\": \"${COMMENT}\" }" -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues/$ISSUE_NUM/comments
fi


# gish commit <comment>
if [ $1 = commit ]
then
  COMMENT=$2
  ISSUE_NUM=$(cat /tmp/gish${ORG_REPO}/gish.dat)

  re='^[0-9]+$'
  if [[ $ISSUE_NUM =~ $re ]]
  then
    # if an issue has been started
    git commit -m "#$ISSUE_NUM - $COMMENT"
  else
    # if an issue has not been started
    git commit -m "$COMMENT"
  fi
fi


# gish browser
if [ $1 = browser ]
then
  ISSUE_NUM=$(cat /tmp/gish${ORG_REPO}/gish.dat)
  open https://github.com$ORG_REPO/issues/$ISSUE_NUM
fi


# creating an issue
if [ $1 = create ]
then
  TITLE=$2
  DESC=$3
  # Create the issue on github
  curl -s -d "{\"title\": \"$TITLE\", \"body\": \"$DESC\" }" -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues \
    | grep "number\|title"
fi

# starting and finishing an issue
if [ $1 = start ]
then
  ISSUE_NUM=$2
  # if we don't have a file, start at zero
  if [ ! -f "/tmp/gish$ORG_REPO/gish.dat" ]
  # Should check if there is already an issue?
  then
    mkdir -p "/tmp/gish$ORG_REPO"
    touch "/tmp/gish$ORG_REPO/gish.dat"
  fi

  # Add assignent on github
  curl -s -d "{\"assignees\": [ \"$USER_NAME\" ] }" -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues/$ISSUE_NUM \
    | grep "title\|body"

  curl -s -d "[ \"in-progress\" ]" -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues/$ISSUE_NUM/labels \
     > /dev/null

  # show it to the user
  echo "You are now assigned to issue number: ${ISSUE_NUM}"
  echo "to open in the browser, type 'gish browser'"
  echo "to view issue, type 'gish get ${ISSUE_NUM}'"
  echo "to end the issue, type 'gish end'"

  # and save it for next time
  echo "${ISSUE_NUM}" > /tmp/gish$ORG_REPO/gish.dat

fi

if [ $1 = end ]
then
  if [ ! -f "/tmp/gish${ORG_REPO}/gish.dat" ]
  then
    echo 'No issue has started'
    return 1
  else
    ISSUE_NUM=$(cat /tmp/gish${ORG_REPO}/gish.dat)

    # Remove assignent on github
    curl -s -d "{\"assignees\": [] }" -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues/$ISSUE_NUM
    curl -s -X DELETE -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/repos$ORG_REPO/issues/$ISSUE_NUM/labels/in-progress

    echo 'finishing issue number '$ISSUE_NUM
    echo "" > /tmp/gish${ORG_REPO}/gish.dat
  fi
fi


if [ $1 = new_repo ]
then
  curl -s -d "{\"name\": \"$2\" }" -u $USER_NAME:$ACCESS_TOKEN $GITHUB_URL/user/repos \
  | grep "git_url"
  echo "Now adding remote branch origin…"
  git remote add origin https://github.com/JMurphyWeb/$2.git
  echo "git push -u origin master"
fi

if [ $1 = "-h" ]
then
  echo "gish new_repo <repo-name>                  ---   Create a new repo with given name"
  echo "gish create \"<title>\" \"<description>\"      ---   Create a new repo with given name"
  echo "gish get                                   ---   Get list of issues"
  echo "gish get <issue_number>                    ---   Get description and comments of a given issue"
  echo "gish start <issue_number>                  ---   Starts an issue (assigns you & puts in-progress)"
  echo "gish comment <issue_number> \"<comment>\"    ---   Adds a comment to an issue"
  echo "gish commit \"<comment>\"                    ---   Adds current issue number to commit message"
  echo "gish browser                               ---   Opens the current issue in the browser"
  echo "gish end                                   ---   Remove assignment of the current issue"
fi
