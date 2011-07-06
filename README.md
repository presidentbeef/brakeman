# Brakeman

Brakeman is a static analysis tool which checks Ruby on Rails applications for security vulnerabilities.

It targets Rails versions > 2.0 with experimental support for Rails 3.x

There is also a [plugin available](https://github.com/presidentbeef/brakeman-jenkins-plugin) for Jenkins/Hudson.

# Installation

Using RubyGems:

    gem install brakeman

From source:

    gem build brakeman.gemspec
    gem install brakeman*.gem

# Usage

    brakeman [app_path]

It is simplest to run Brakeman from the root directory of the Rails application. A path may also be supplied.

# Options

To specify an output file for the results:

    brakeman -o output_file

The output format is determined by the file extension or by using the `-f` option. Current options are: `text`, `html`, `csv`, and `tabs`.

To suppress informational warnings and just output the report:

    brakeman -q

To see all kinds of debugging information:

    brakeman -d

Specific checks can be skipped, if desired. The name needs to be the correct case. For example, to skip looking for default routes (`DefaultRoutes`):

    brakeman -x DefaultRoutes

Multiple checks should be separated by a comma:

    brakeman -x DefaultRoutes,Redirect

To do the opposite and only run a certain set of tests:

    brakeman -t SQL,ValidationRegex

To indicate certain methods are "safe":

    brakeman -s benign_method,totally_safe

By default, brakeman will assume that unknown methods involving untrusted data are dangerous. For example, this would cause a warning (Rails 2):

    <%= some_method(:option => params[:input]) %>

To only raise warnings only when untrusted data is being directly used:

    brakeman -r

# Warning information

See WARNING_TYPES for more information on the warnings reported by this tool.

# Warning context

The HTML output format provides an excerpt from the original application source where a warning was triggered. Due to the processing done while looking for vulnerabilities, the source may not resemble the reported warning and reported line numbers may be slightly off. However, the context still provides a quick look into the code which raised the warning.

# Confidence levels

Brakeman assigns a confidence level to each warning. This provides a rough estimate of how certain the tool is that a given warning is actually a problem. Naturally, these ratings should not be taken as absolute truth.

There are three levels of confidence:

 + High - Either this is a simple warning (boolean value) or user input is very likely being used in unsafe ways.
 + Medium - This generally indicates an unsafe use of a variable, but the variable may or may not be user input.
 + Weak - Typically means user input was indirectly used in a potentially unsafe manner.

To only get warnings above a given confidence level:

    brakeman -w3

The `-w` switch takes a number from 1 to 3, with 1 being low (all warnings) and 3 being high (only highest confidence warnings).

# Configuration files

Brakeman options can stored and read from YAML files. To simplify the process of writing a configuration file, the `-C` option will output the currently set options.

Options passed in on the commandline have priority over configuration files.

The default config locations are `./config.yaml`, `~/.brakeman/`, and `/etc/brakeman/config.yaml`

The `-c` option can be used to specify a configuration file to use.

# License

The MIT License

Copyright (c) 2010, YELLOWPAGES.COM, LLC

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
