# Griddler::Mandrill
[![Build Status](http://img.shields.io/travis/wingrunr21/griddler-mandrill.svg?style=flat)](https://travis-ci.org/wingrunr21/griddler-mandrill)
[![Dependency Status](http://img.shields.io/gemnasium/wingrunr21/griddler-mandrill.svg?style=flat)](https://gemnasium.com/wingrunr21/griddler-mandrill)
[![Gem Version](http://img.shields.io/gem/v/griddler-mandrill.svg?style=flat)](https://rubygems.org/gems/griddler-mandrill)

This is an adapter that allows [Griddler](https://github.com/thoughtbot/griddler) to be used with [Mandrill's Inbound Email Processing](http://help.mandrill.com/entries/21699367-Inbound-Email-Processing-Overview).

## Installation

Add this line to your application's Gemfile:

    gem 'griddler'
    gem 'griddler-mandrill'

## SPF Spam filtering

Please note that ONLY email received with SPF headers that are 'pass' or 'neutral' will be processed. Emails without SPF or with failing SPF will be silently swallowed and will not be set to your email processor.

## Usage

[thoughtbot](http://thoughtbot.com) has a blog post on how to use Griddler over on their blog: [Giant
Robots](http://robots.thoughtbot.com/handle-incoming-email-with-griddler).

### Additional Setup

When adding a webhook in their administration panel, Mandrill will issue a HEAD
request to check if the webhook is valid (see [Adding Routes]).  If the HEAD
request fails, Mandrill will not allow you to add the webhook.  Since Griddler
is only configured to handle POST requests, you will not be able to add the
webhook as-is. To solve this, add a temporary route to your application that can
handle the HEAD request:

    # config/routes.rb
    get "/email_processor", to: proc { [200, {}, ["OK"]] }, as: "mandrill_head_test_request"

Once you have correctly configured Mandrill, you can go ahead and delete this code.

[Adding Routes]: http://help.mandrill.com/entries/21699367-Inbound-Email-Processing-Overview

## Credits

Griddler::Mandrill was extracted from Griddler by [Stafford Brunk](https://github.com/wingrunr21).

Griddler was written by [Caleb Thompson](https://github.com/calebthompson) and [Joel Oliveira](https://github.com/jayroh).
