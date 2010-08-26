module Forlication
  # Heavily influenced by tobi/delayed_job.git
  class DeserializationError < StandardError
  end

  # A job object that is persisted to the database.
  # Contains the work object as a YAML field.
  class Job < ActiveRecord::Base
    MAX_ATTEMPTS = 25
    MAX_RUN_TIME = 4.hours
    set_table_name :forlication_jobs

    ParseObjectFromYaml = /\!ruby\/\w+\:([^\s]+)/

    before_create :generate_token

    def failed?
      failed_at
    end
    alias_method :failed, :failed?

    def payload_object
      @payload_object ||= deserialize(self['handler'])
    end

    def name
      @name ||= begin
        payload = payload_object
        if payload.respond_to?(:display_name)
          payload.display_name
        else
          payload.class.name
        end
      end
    end

    def payload_object=(object)
      self['handler'] = object.to_yaml
    end

    def self.link(object, scope, &block)
      job = simple(object, scope, &block)

      job.token
    end

    # Add a job to the queue
    def self.simple(*args, &block)
      object = block_given? ? EvaledJob.new(&block) : args.shift
      scope = args.shift

      unless object.respond_to?(:perform) || block_given?
        raise ArgumentError, 'Cannot simplify forlication links when objects do not respond to perform'
      end

      Job.create(:payload_object => object, :scope => scope)
    end


    # This is a good hook if you need to report job processing errors in additional or different ways
    def log_exception(error)
      logger.error "* [JOB] #{name} failed with #{error.class.name}: #{error.message} - #{attempts} failed attempts"
      logger.error(error)
    end


    # Moved into its own method so that new_relic can trace it.
    def invoke_job(params)
      if action_count < action_limit
        resp = payload_object.perform(params)
        increment!(:action_count)
      end
      return resp
    end

    private

    def deserialize(source)
      handler = YAML.load(source) rescue nil

      unless handler.respond_to?(:perform)
        if handler.nil? && source =~ ParseObjectFromYaml
          handler_class = $1
        end
        attempt_to_load(handler_class || handler.class)
        handler = YAML.load(source)
      end

      return handler if handler.respond_to?(:perform)

      raise DeserializationError,
            'Job failed to load: Unknown handler. Try to manually require the appropiate file.'
    rescue TypeError, LoadError, NameError => e
      raise DeserializationError,
            "Job failed to load: #{e.message}. Try to manually require the required file."
    end

    # Constantize the object so that ActiveSupport can attempt
    # its auto loading magic. Will raise LoadError if not successful.
    def attempt_to_load(klass)
      klass.constantize
    end

    # Get the current time (GMT or local depending on DB)
    # Note: This does not ping the DB to get the time, so all your clients
    # must have syncronized clocks.
    def self.db_time_now
      (ActiveRecord::Base.default_timezone == :utc) ? Time.now.utc : Time.zone.now
    end

    protected

    def generate_token
      attempts_left = 5
      while attempts_left > 0
        token_attempt = Digest::MD5.hexdigest("#{Time.current.to_i} #{rand(2**30)}SALTY")

        # Could find_by_token_and_scope
        token = self.class.find_by_token_and_scope(scope, token_attempt)
        break if !token
        attempts_left -= 1
      end
      if attempts_left > 0
        self.token ||= token_attempt
      else
        raise 'Could not generate a unique token'
      end
    end
  end

  class EvaledJob
    def initialize
      @job = yield
    end

    def perform
      eval(@job)
    end
  end
end
