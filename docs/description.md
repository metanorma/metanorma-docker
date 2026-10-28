## Metanorma Docker Container

### Purpose

Metanorma requires a number of dependencies to run, and the installation process
might a be bit cumbersome if you only care about functions for the most basic uses.

The Docker container allows you utilize all Metanorma functionality without any
installation needed. All you need to do is pull this image and it will work
straight away.

If you don't have Docker installed on your computer,
please follow this https://docs.docker.com/install.


### Which Metanorma image to choose?

We provide the following images:

* `metanorma/metanorma` (`metanorma/metanorma:latest`) is the current stable version
* `metanorma/metanorma:edge` tracks the `main` branch of
  https://github.com/metanorma/metanorma-docker

It is strongly recommended to use the `metanorma/metanorma` image
unless you want to test out our upcoming features.

### Usage

#### Basic usage

The simplest use case is to compile a document using Metanorma.
All you need to do is go to a document directory and then
execute the following command.

macOS / Linux:

```sh
docker run \
  -v $(pwd):/metanorma \
  metanorma/metanorma:latest \

  # metanorma command as you would have run normally
  metanorma compile -x html,doc -t iso yourdocument.adoc
```

Windows:

```sh
docker run \
  -v "%cd%":/metanorma \
  metanorma/metanorma:latest \
  metanorma compile -x html,doc -t iso yourdocument.adoc
```

This compiles your document with expected output format.

The `-v` option is used to map your current directory to the
Metanorma document directory inside the container, so the `metanorma`
executable within the Docker image can locate the document's
files/assets properly.

NOTE: **Windows** users will need to reference
the current directory with the -v option.

You can run any Metanorma command using the image directly,
but if you need to bind your `STDIN` and `STDOUT`, then use
the `-it` option when running the image.


#### Advanced usage

If you want to tinker with the toolchain extensively, you could
run `bash` within the container and run any command from there.

For example, your document has some custom dependency that is defined
in a `Gemfile` file, and you want to make sure the `metanorma`
command utilizes this dependency. This is how you do it.

Your `Gemfile` should include `metanorma-cli` itself plus your extra gems:

```ruby
source "https://rubygems.org"
gem "metanorma-cli", "= 1.17.0"
gem "my-custom-dependency"
```

Then point `BUNDLE_GEMFILE` at your mounted `Gemfile`:

```sh
# install your dependencies (inside the container)
docker run -it -v $(pwd):/metanorma \
  -e BUNDLE_GEMFILE=/metanorma/Gemfile \
  metanorma/metanorma:latest \
  bash -c "RUBYOPT= bundle install && bundle exec metanorma compile -x html,doc -t iso yourdocument.adoc"
```

NOTE: `RUBYOPT=` (cleared) is needed for the one-time `bundle install`
because the image sets `RUBYOPT=-rbundler/setup`, which cannot boot until
your `Gemfile.lock` exists. After that, `bundle exec metanorma` runs your
bundle with your gems.


#### Using a specific version of Metanorma

Normally we try to keep the metanorma image version semantic to the underlying
`metanorma-cli` gem, so if you want to use any of of the specific version then
you can do so by specifying the image tag.

For example, if you want to run metanorma version `1.1.8`, please first check
the tags section of this image to make sure we actually have a release for that
version, and once confirmed then you can run.

```sh
# pull the 1.1.8 image
docker pull metanorma/metanorma:1.1.8

# compile with the 1.1.8 image
docker run \
  -v $(pwd):/metanorma \
  metanorma/metanorma:1.1.8 \
  metanorma compile -x html,doc -t iso yourdocument.adoc
```

#### Updating the container image

To update the metanorma image, you can do a docker pull and it will pull the
latest version, and will tag this image correctly.

```sh
docker pull metanorma/metanorma
# equivalent to
# docker pull metanorma/metanorma:latest
```

### License

The image is available open source under the terms of the
[MIT License](http://opensource.org/licenses/MIT).
