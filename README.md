# Image Server

## Frontend

* View Image
  * search image
  * tags

* DL Image
  * multiple select
* Upload Image
  * multiple select
  * tagging
  * images in page
* Delete Image
  * multiple select

## Get Started

### 1. write config.json

```json
{
  "db": {
	"name": "dbname",
	"pass": "dbpass",
	"host": "dbhost",
	"user": "user"
  },
  "app": {
	"img_path": "./public/imgs/",
	"img_url_path": "/imgs/"
  }
}

```

### 2. run create.rb

create table.

* advance preparation
  * create db.
  * create user and set permission.

```bash
$ bundle install
$ bundle exec ruby create.rb
```

### 3. run web app

```bash
$ bundle exec ruby srv.rb
```
