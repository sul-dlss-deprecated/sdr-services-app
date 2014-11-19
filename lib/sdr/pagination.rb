require "sinatra/base"

module Sinatra
  module Pagination

    module Helpers

      def http_pagination(sequel_dataset)
        # pagination is based on github recommendation, see
        # https://developer.github.com/guides/traversing-with-pagination/
        # see alternative at http://dev.librato.com/v1/pagination
        @paginated = sequel_dataset.paginate(page, per_page)
        add_pagination_headers unless @paginated.page_count == 1
        return @paginated
      end

      private

      def add_pagination_headers
        request_url = request.url.split("?")[0]

        links = []
        links << %(<#{request_url}?page=#{@paginated.prev_page.to_s}&per_page=#{per_page}>; rel="prev") if @paginated.prev_page
        links << %(<#{request_url}?page=#{@paginated.next_page.to_s}&per_page=#{per_page}>; rel="next") if @paginated.next_page
        links << %(<#{request_url}?page=1&per_page=#{per_page}>; rel="first")
        links << %(<#{request_url}?page=#{@paginated.page_count.to_s}&per_page=#{per_page}>; rel="last")

        headers "Link" => links.join(",")
      end

      # Ensure that invalid page numbers just return the first page
      # An out of range page number is still valid -- 0, -1, foo are not valid
      def page
        p = params[:page].to_i
        p.between?(1, Float::INFINITY) ? p : 1
      end

      # Default to 30 items per page
      # Permit up to 200 items per page, if more than 200 are requested, return 200
      def per_page
        max = 200
        if per = params[:per_page].to_i
          if per.between?(1, max)
            per
          elsif per > max
            max
          elsif per < 1
            30
          end
        else
          30
        end
      end

    end

    def self.registered(app)
      app.helpers Pagination::Helpers
    end

  end
  register Pagination
end
