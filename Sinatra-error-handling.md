# Sinatra Error Handling

Sinatra is a RESTful web application framework in which each request URI is routed to a block of code (the handler) based on pattern matching of the URI path.  

* If no no matching route can be found, or Sinatra::NotFound exception is raised, then the default behavior is to return a 404 (Not Found) response.
* If a RuntimeException or other error occurs during processing in a route handler, Sinatra's default behavior is to return a 500 (Internal Service Error) response.

The default exception handling behavior can be overridden by adding a custom "not_found" or "error" handler to the application.  Additionally, one or more custom error handlers can be added to trap specific exception subtypes.  

* The documentation for these handlers provides examples wherein the response body text returned to the browser client is altered from the message contained in the default sinatra.error variable.  example:

        error do
            'So what happened was...' + env['sinatra.error'].message
        end	

* It is also possible to change the response code using the error handler:

        error FileNotFound do
          	status 404
            erb :oops
        end

The error handlers will only be invoked, however, if both the Sinatra :raise_errors and :show_exceptions configuration options have been set to false.  For reasons that are clear to the author (but less obvious to mere mortals), the default values of these options follows a formula that depends on the value of the Rack environment.  

* :raise_errors defaults to true in the "test" environment and to false on other environments.
* :show_exceptions value defaults to true in the "development" environment and to false on other environments
* Additionally a :dump_errors option (defaulting to enabled except in "test") can be used to control whether stack traces should be included in the error output.  From Sinatra base.rb:

        set :raise_errors, Proc.new { test? }
        set :dump_errors, Proc.new { !test? }
        set :show_exceptions, Proc.new { development? }

The author of Sintra has said:  "This \[behavior] is intentional.  The idea is that error blocks will hide the issue and you usually don't want to do this in development mode. "   The author also recommends setting :show_exceptions to :after_handler, which causes a stack trace to be sent in the browser after invoking the custom error handler.

So if you want your custom error handlers to be invoked in all but the development environment, then you should "disable :raise_errors".  If you want the same behavior in the development environment, then you should also "disable :show_exceptions".

References

* https://github.com/sinatra/sinatra#error
* http://www.sinatrarb.com/intro#Error%20Handling
* http://www.sinatrarb.com/documentation.html
* http://www.sinatrarb.com/configuration.html
* https://github.com/sinatra/sinatra/issues/566
* https://github.com/sinatra/sinatra/issues/578
