# fluent-plugin-fixfile

[Fluentd](http://fluentd.org/) output plugin to output file with fix path.

``output file`` cannot fixed path like ``out_file.%Y%m%d_**.log``.

``symlink_path`` don't work at Windows enviroment.

This plugin can output the file at fixed path like ``out_file.log`` for Windows enviroment.

## Installation


### RubyGems

```
$ gem install fluent-plugin-fixfile
```

### Bundler

Add following line to your Gemfile:

```ruby
gem "fluent-plugin-fixfile"
```

And then execute:

```
$ bundle
```

## Configuration

```
<match *>
  @type fixfile
  path SOMETHING
  append true
</match>
```

``append true`` is required.

If ``append false`` it outputs the file at ``SOMETHING_0.log``

``time_format`` option is not available.

## Copyright

* Copyright(c) 2017- soulhead
* License
  * Apache License, Version 2.0
