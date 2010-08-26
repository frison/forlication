# Forlication
module Forlication

  autoload :PerformableMethod, 'forlication/performable_method'
  autoload :Job, 'forlication/job'
  
  module Controllers
    autoload :Helpers, 'forlication/controllers/helpers'
    autoload :UrlHelpers, 'forlication/controllers/url_helpers'
  end

  # Store forlication action mappings
  mattr_accessor :mappings
  @@mappings = ActiveSupport::OrderedHash.new
  
end

class ForlicationActionClass
  def initialize(token)
    @token = token
  end

  def render
    {:text => "#{@token}"}
  end

  def redirect_to
    "http://www.google.ca"
  end
end


require 'forlication/mapping'
require 'forlication/rails'
