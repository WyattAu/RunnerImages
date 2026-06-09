# PHP Runner Image

PHP 8.3 + Composer for Forgejo Actions CI.

## Tools

- PHP 8.3 (Ubuntu 24.04 default)
- Composer (latest)
- Extensions: curl, mbstring, xml, zip, mysql, pgsql, sqlite3, gd, bcmath, intl, redis, memcached
- unzip, sudo (passwordless)

## Usage

```yaml
container:
  image: ghcr.io/wyattau/runner-images/php:1
```

## Verify

```bash
php --version     # PHP 8.3.x
composer --version
```
