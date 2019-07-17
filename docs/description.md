## Metanorma

### Purpose

Metanorma tool chain requires couple of dependencies, and installation process
might a be bit of a work sometime when you only care about the tools for your
basic usages.

This where this image comes in, so if you want to use the tools without needing
to install every single dependency then all you need to do is pull this image
and it will work straight away.

If you don't have docker installed in your device then please follow this https://docs.docker.com/install.

### Which image to choose?

We are maintaining two images, the `metanorma/metanorma` is the current stable
version and the `metanorma/mn` is the edge version. It is recommended to use the
`metanorma/metanorma` version unless you want to test out our upcoming features.

### Usages

#### Basic usages

The simplest use case, lets say you want to compile a document using metanorma
toolchain then all you need to do is go to our document directory and then
execute the following command.

```sh
docker run \
  -v $(pwd):/metanorma \
  metanorma/metanorma:latest \

  # metanorma command as you would have run normally
  metanorma compile -x html,doc -t iso yourdocument.adoc
```

This compile your document with expected output format, here the `-v` option is
used to map your current directory to the metanorma directory, so the image can
locate all files/assets properly.

**Windows** user, please note, you will need to use correct command to reference
your current directory, like: `-v "%cd%":/metanorma`.

You can run any metanorma command using the image directly, but if you need to
bind your `stdin` and `stdin` then use the `-it` option when running the image.

#### Advance usages

If you want to use the toolchain extensively it might be a good idea to ssh into
the container and run any command from there. For example, your document has some
custom dependency that is defined in a Gemfile file and you want to make sure
the metanorma usages this dependency then you can do the following.

```sh
# ssh to the container
docker run -it -v $(pwd):/metanorma metanorma/metanorma:latest bash

# install your depencencies (inside the container)
bundle install

# run metanorma commands
bundle exec metanorma compile -x html,doc -t iso yourdocument.adoc
```

In another word, once you are inside the container then it's similar to ubuntu
with all necessary ruby/metanorma toolchain setup, and you can run anything you
want as you would have done in any other machine.

#### Using specific version

Normally we try to keep the metanorma image version semantic to the underlying
`metanorma-cli` gem, so if you want to use any of of the specific version then
you can do so by specifying the image tag.

For example, if you want to run metanorma version `1.1.8` then first please check
the tags section of this image to make sure we actually have a release for that
version, and once confirmed then you can run.

```sh
docker run \
  -v $(pwd):/metanorma \
  metanorma/metanorma:1.1.8 \
  metanorma compile -x html,doc -t iso yourdocument.adoc
```

#### Updating the image

To update the metanorma image, you can do a docker pull and it will pull the
latest version, and will tag this image correctly.

```sh
docker pull metanorma/metanorma
```

### Credits

This image is developed, maintained and funded by [Ribose Inc.][riboseinc]

### License

The gem is available as open source under the terms of the [MIT License][mit].

[riboseinc]: https://www.ribose.com
[mit]: http://opensource.org/licenses/MIT
