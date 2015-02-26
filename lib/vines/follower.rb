# encoding: UTF-8

module Vines
  class Follower
    include Comparable

    attr_accessor :name, :subscription, :ask, :groups
    attr_reader :jid

    def initialize(args={})
      @jid = JID.new(args[:jid]).bare
      raise ArgumentError, 'invalid jid' if @jid.empty?
      @name = args[:name]
      @subscription = args[:subscription] || 'none'
      @ask = args[:ask]
      @groups = args[:groups] || []
    end

    def <=>(follower)
      follower.is_a?(Follower) ? self.jid.to_s <=> follower.jid.to_s : nil
    end

    alias :eql? :==

    def hash
      jid.to_s.hash
    end

    def update_from(follower)
      @name = follower.name
      @subscription = follower.subscription
      @ask = follower.ask
      @groups = follower.groups.clone
    end

    # Returns true if this follower is in a state that allows the user
    # to subscribe to their presence updates.
    def can_subscribe?
      @ask == 'subscribe' && %w[none from].include?(@subscription)
    end

    def subscribe_to
      @subscription = (@subscription == 'none') ? 'to' : 'both'
      @ask = nil
    end

    def unsubscribe_to
      @subscription = (@subscription == 'both') ? 'from' : 'none'
    end

    def subscribe_from
      @subscription = (@subscription == 'none') ? 'from' : 'both'
      @ask = nil
    end

    def unsubscribe_from
      @subscription = (@subscription == 'both') ? 'to' : 'none'
    end

    # Returns true if the user is subscribed to this follower's
    # presence updates.
    def subscribed_to?
      %w[to both].include?(@subscription)
    end

    # Returns true if the user has a presence subscription from
    # this follower. The follower is subscribed to this user's presence.
    def subscribed_from?
      %w[from both].include?(@subscription)
    end

    # Returns a hash of this follower's attributes suitable for persisting in
    # a document store.
    def to_h
      {
        'name' => @name,
        'subscription' => @subscription,
        'ask' => @ask,
        'groups' => @groups.sort!
      }
    end

    # Write an iq stanza to the recipient stream representing this follower's
    # current roster item state.
    def send_roster_push(recipient)
      doc = Nokogiri::XML::Document.new
      node = doc.create_element('iq',
        'id'   => Kit.uuid,
        'to'   => recipient.user.jid.to_s,
        'type' => 'set')
      node << doc.create_element('query', 'xmlns' => NAMESPACES[:roster]) do |query|
        query << to_roster_xml
      end
      recipient.write(node)
    end

    # Returns this follower as an xmpp <item> element.
    def to_roster_xml
      doc = Nokogiri::XML::Document.new
      doc.create_element('item') do |el|
        el['ask'] = @ask unless @ask.nil? || @ask.empty?
        el['jid'] = @jid.bare.to_s
        el['name'] = @name unless @name.nil? || @name.empty?
        el['subscription'] = @subscription
        @groups.sort!.each do |group|
          el << doc.create_element('group', group)
        end
      end
    end
  end
end
