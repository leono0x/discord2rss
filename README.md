# discord2rss

Create an rss feed from discord channels.

## Config

- Login to Discord web in chrome.
- Open ChromeWebTools > Network tab and write `messages channels` in the filter box.
- Go to Discord and click in any channel.
- Go to ChromeWebTools, select the filtered request and copy the `authorization` header.
- Go to `config.json` and paste the authToken.
- Add some of your servers/channels in `channles.csv`.

## Use
``` bash
ruby discord2rss.rb
```