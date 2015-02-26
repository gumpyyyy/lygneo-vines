require 'active_record'

module Vines
  class Storage
    class Sql < Storage
      register :sql

      class Person < ActiveRecord::Base; end
      class Follower < ActiveRecord::Base
        belongs_to :user
        belongs_to :person
      end

      class User < ActiveRecord::Base
        has_many :followers#, through: :user_id
        has_many :follower_people, :through => :followers, :source => :person
        has_one :person, :foreign_key => :owner_id
      end

      # Wrap the method with ActiveRecord connection pool logic, so we properly
      # return connections to the pool when we're finished with them. This also
      # defers the original method by pushing it onto the EM thread pool because
      # ActiveRecord uses blocking IO.
      def self.with_connection(method, args={})
        deferrable = args.key?(:defer) ? args[:defer] : true
        old = instance_method(method)
        define_method method do |*args|
          ActiveRecord::Base.connection_pool.with_connection do
            old.bind(self).call(*args)
          end
        end
        defer(method) if deferrable
      end

      def initialize(&block)
        raise "You configured lygneo-sql adapter without Lygneo" unless defined? AppConfig
        @config = {
          :adapter => AppConfig.adapter.to_s,
          :database => AppConfig.database.to_s,
          :host => AppConfig.host.to_s,
          :port => AppConfig.port.to_i,
          :username => AppConfig.username.to_s,
          :password => AppConfig.password.to_s
        }

        required = [:adapter, :database]
        required << [:host, :port] unless @config[:adapter] == 'sqlite3'
        required.flatten.each {|key| raise "Must provide #{key}" unless @config[key] }
        [:username, :password].each {|key| @config.delete(key) if empty?(@config[key]) }
        establish_connection
      end

      def find_user(jid)
        jid = JID.new(jid).bare.to_s
        return if jid.empty?
        xuser = user_by_jid(jid)
        return Vines::User.new(jid: jid).tap do |user|
          user.name, user.password = xuser.username, xuser.authentication_token

          xuser.followers.each do |follower|
            handle = follower.person.lygneo_handle
            ask = 'none'
            subscription = 'none'

            if follower.sharing && follower.receiving
              subscription = 'both'
            elsif follower.sharing && !follower.receiving
              ask = 'suscribe'
              subscription = 'from'
            elsif !follower.sharing && follower.receiving
              subscription = 'to'
            else
              ask = 'suscribe'
            end
            # finally build the roster entry
            user.roster << Vines::Follower.new(
              jid: handle,
              name: handle.gsub(/\@.*?$/, ''),
              subscription: subscription,
              ask: ask
            ) if handle
          end
        end if xuser
      end
      with_connection :find_user

      def authenticate(username, password)
        user = find_user(username)

        dbhash = BCrypt::Password.new(user.password) rescue nil
        hash = BCrypt::Engine.hash_secret("#{password}#{Config.instance.pepper}", dbhash.salt) rescue nil

        userAuth = ((hash && dbhash) && hash == dbhash)
        tokenAuth = ((password && user.password) && password == user.password)
        (tokenAuth || userAuth)? user : nil
      end

      def save_user(user)
        # do nothing
        #log.error("You cannot save a user via XMPP server!")
      end
      with_connection :save_user

      def find_vcard(jid)
        # do nothing
        nil
      end
      with_connection :find_vcard

      def save_vcard(jid, card)
        # do nothing
      end
      with_connection :save_vcard

      def find_fragment(jid, node)
        # do nothing
        nil
      end
      with_connection :find_fragment

      def save_fragment(jid, node)
        # do nothing
      end
      with_connection :save_fragment

      private
        def establish_connection
          ActiveRecord::Base.logger = Logger.new('/dev/null')
          ActiveRecord::Base.establish_connection(@config)
        end

        def user_by_jid(jid)
          name = JID.new(jid).node
          Sql::User.find_by_username(name)
        end
    end
  end
end
