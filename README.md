# LocalSetup

1. `git clone git@github.com:ih14c-13-14/artist.git`
2. `make setup-local`

以上です。

# 起動方法

-   `make up`

# 終了方法

-   `make down`

コンテナごと破棄する場合は

-   `make destroy`

# 手元でのテスト方法

## Unit test

-   `make test`

## Static analysis

-   `make lint`

PHPStan 単体では

-   `make phpstan`
