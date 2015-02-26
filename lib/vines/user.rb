# encoding: UTF-8

module Vines
  class User
    include Comparable

    attr_accessor :name, :password, :roster
    attr_reader :jid

    def initialize(args={})
      @jid = JID.new(args[:jid])
      raise ArgumentError, 'invalid jid' if @jid.empty?

      @name = args[:name]
      @password = args[:password]
      @roster = args[:roster] || []
    end

    def <=>(user)
      user.is_a?(User) ? self.jid.to_s <=> user.jid.to_s : nil
    end

    alias :eql? :==

    def hash
      jid.to_s.hash
    end

    # Update this user's information from the given user object.
    def update_from(user)
      @name = user.name
      @password = user.password
      @roster = user.roster.map {|c| c.clone }
    end

    # Return true if the jid is on this user's roster.
    def follower?(jid)
      !follower(jid).nil?
    end

    # Returns the follower with this jid or nil if not found.
    def follower(jid)
      bare = JID.new(jid).bare
      @roster.find {|c| c.jid.bare == bare }
    end

    # Returns true if the user is subscribed to this follower's
    # presence updates.
    def subscribed_to?(jid)
      follower = follower(jid)
      follower && follower.subscribed_to?
    end

    # Returns true if the user has a presence subscription from this follower.
    # The follower is subscribed to this user's presence.
    def subscribed_from?(jid)
      follower = follower(jid)
      follower && follower.subscribed_from?
    end

    # Removes the follower with this jid from the user's roster.
    def remove_follower(jid)
      bare = JID.new(jid).bare
      @roster.reject! {|c| c.jid.bare == bare }
    end

    # Returns a list of the followers to which this user has
    # successfully subscribed.
    def subscribed_to_followers
      @roster.select {|c| c.subscribed_to? }
    end

    # Returns a list of the followers that are subscribed to this user's
    # presence updates.
    def subscribed_from_followers
      @roster.select {|c| c.subscribed_from? }
    end

    # Update the follower's jid on this user's roster to signal that this user
    # has requested the follower's permission to receive their presence updates.
    def request_subscription(jid)
      unless follower = follower(jid)
        follower = Follower.new(:jid => jid)
        @roster << follower
      end
      follower.ask = 'subscribe' if %w[none from].include?(follower.subscription)
    end

    # Add the user's jid to this follower's roster with a subscription state of
    # 'from.' This signals that this follower has approved a user's subscription.
    def add_subscription_from(jid)
      unless follower = follower(jid)
        follower = Follower.new(:jid => jid)
        @roster << follower
      end
      follower.subscribe_from
    end

    def remove_subscription_to(jid)
      if follower = follower(jid)
        follower.unsubscribe_to
      end
    end

    def remove_subscription_from(jid)
      if follower = follower(jid)
        follower.unsubscribe_from
      end
    end

    # Returns this user's roster followers as an iq query element.
    def to_roster_xml(id)
      doc = Nokogiri::XML::Document.new
      doc.create_element('iq', 'id' => id, 'type' => 'result') do |el|
        el << doc.create_element('query', 'xmlns' => 'jabber:iq:roster') do |query|
          @roster.sort!.each do |follower|
            query << follower.to_roster_xml
          end
        end
      end
    end
  end
end
