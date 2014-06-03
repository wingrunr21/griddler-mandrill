require 'griddler'
require 'griddler/mandrill/version'
require 'griddler/mandrill/adapter'

Griddler.adapter_registry.register(:mandrill, Griddler::Mandrill::Adapter)
