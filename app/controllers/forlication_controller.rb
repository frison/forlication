
# This class
class ForlicationController < Forlication::ApplicationController
  before_filter :set_mapping
  before_filter :set_token

  def show
    method_parameters = {:token => @token,
                         :user_agent => request.env['HTTP_USER_AGENT'],
                         :referrer => request.referrer,
                         :ip_address => request.env['REMOTE_ADDR']
    }
    ac = nil

    if @mapping.performer
      job = Forlication::Job.find_by_token_and_scope(@token, @mapping.scope.to_s)
      ac = job.invoke_job(method_parameters)  if job
    else
      delegator = @mapping.action_class
      if delegator.respond_to?(:forlicate)
        ac = delegator.forlicate(method_parameters)
      else
        ac = delegator.new(method_parameters)
      end
    end

    if ac.respond_to?(:redirect_to) and ac.redirect_to
      redirect_to ac.redirect_to
      return
    elsif ac.respond_to?(:render) and ac.render
      render ac.render if ac.respond_to?(:render)
      return
    end
    render_not_found
  end


  protected

  def set_mapping
    @mapping = Forlication::Mapping.find_by_path(request.path)
    render_not_found if !@mapping
  end

  def set_token
    @token = params[@mapping.token.to_sym] if @mapping
    render_not_found if !@token
  end

  def render_not_found
    render :text => '404 Not Found', :status => '404 Not Found'
  end

end
