# encoding: UTF-8

module Vines
  class Stream
    class Http
      class Auth < Client::Auth
        def initialize(stream, success=BindRestart)
          super
        end

        def node(node)
          unless stream.valid_session?(node['sid']) && body?(node) && node['rid']
            raise StreamErrors::NotAuthorized
          end
          nodes = stream.parse_body(node)
          raise StreamErrors::NotAuthorized unless nodes.size == 1
          super(nodes.first)
        end
      end
    end
  end
end
