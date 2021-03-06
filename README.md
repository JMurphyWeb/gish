## gish - command line github workflow tool


### Getting started

1. run `npm install gish-workflow -g`

2. Generate a personal access token by following [this link](https://github.com/settings/tokens)

3. Run `gish` which will prompt you to enter your GitHub username and your new access token


### Interface

gish exposes the following commands:


```bash
$ gish -h
```
Get a list of the available commands.


```bash
$ gish new_repo <title>
```
Creates a new github repo and adds remote branch called `origin`.


```bash
$ gish create <title> <body>
```
Creates a new issue



```bash
$ gish get
```
Gets most recent ~20 issues



```bash
$ gish get <issue number>
```
Gets title, description and comments of specified issue


```bash
$ gish start <issue number>
```
Assigns user to said issue, adds the `in-progress` label and stores the number locally. If used with the custom pure zsh theme, it also adds the issue number to the command line prompt so you never have to check:

![screen shot](./assets/gish-start.png)


```bash
gish comment <issue number> <comment>
```
Adds a comment to specified issue number


```bash
gish commit <comment>
```
Adds a git commit with the message prefixed with the previously started issue number:

- `$ gish start 4`
- `$ gish commit "fixes dashboard url"` -> message becomes: `#4 - fixes dashboard url`


```bash
$ gish end
```
Removes assignment and `in-progress` label on GitHub and removes the issue from command line prompt (for users with custom zsh theme set up)

```bash
$ gish browser
```
Opens the issue you are working on in the browser. If no issue is being worked on, it opens all issues view.


________________________

### Using gish

I will release as an npm package when it is a bit more dynamic and useful, for now, add the file `gish` to your `/usr/local/bin/` directory, remembering to add your GitHub user name and an access token.

#### ... with zsh

In order to get the prompt to be updated with the current issue you are working on, you need to create a custom oh-my-zsh theme in `.oh-my-zsh/custom/themes/`. You can copy mine `pure.zsh-theme`. Remember to specify the theme in your `~/.zshrc` file (if using my theme, you should have the following line in `.zshrc`: `ZSH_THEME="pure"`)
