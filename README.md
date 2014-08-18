# Git Branch Deploy

A [wercker](http://wercker.com/) step to deploy to a certain git branch in a repo. Supports also [Github Pages](http://pages.github.com/).

## Options

You either have to define a `gh_token` if you deploy to github or a `host` if you want to deploy via SSH.
(Please use wercker steps `leipert/add-ssh-key-gh-bb` and `add-to-known_hosts` to setup your SSH token for github and bitbucket)

- `gh_token` *optional* Github API access token, if you want to deploy to github. ([documentation](https://github.com/blog/1509-personal-api-tokens)). **don't share this on a public repo, use an environment variable!**
- `host` *optional* Set this to a host like "example.org". Defaults to your build host or github if `gh_token` is used.
- `repo` *optional* Set this to a repo like "username/repo". Defaults to your build repo.
- `branch` *optional* If set this branch will be used as deploy goal. Defaults to build master
- `basedir` *optional* Set this if your build step outputs to a folder
- `discard_history` **DANGER** *optional* Discards history of that branch. Use with care as it could destroy your whole programming history.
- `gh_pages` *optional* Set this to true if you want to deploy to [Github Pages](http://pages.github.com/). The Branch will be set accordingly.
- `gh_pages_domain` *optional* Custom domain ([documentation](https://help.github.com/articles/setting-up-a-custom-domain-with-pages))

## Example

For Github Pages:
```
deploy:
  steps:
    - git-push:
         gh_token: $GIT_TOKEN
         gh_pages: true
         gh_pages_domain: example.org
         basedir: build
```
Deploy with SSH
```
deploy:
  steps:
    # Add SSH-Key to
    - leipert/add-ssh-key-gh-bb:
        keyname: DEPLOY_SSH
    # Add bitbucket to known hosts, so they won't ask us whether we trust bitbucket
    - add-to-known_hosts:
        hostname: bitbucket.org
        fingerprint: 97:8c:1b:f2:6f:14:6b:5c:3b:ec:aa:46:46:74:7c:40
    - git-push:
         host: bitbucket.org
         repo: example/exampleRepo
         branch: example
         basedir: build
```
