#!/usr/bin/env ruby

require 'tamanegi'

Ramaze.start :adapter => :thin, :port => 7000, :load_engines => :Builder
