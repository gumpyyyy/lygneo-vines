# encoding: UTF-8

module Vines
  module Command
    class Init
      def run(opts)
        raise 'vines init <domain>' unless opts[:args].size == 1
        domain = opts[:args].first.downcase
        dir = File.expand_path(domain)
        raise "Directory already initialized: #{domain}" if File.exists?(dir)
        Dir.mkdir(dir)

        create_directories(dir)
        create_users(domain, dir)
        update_config(domain, dir)
        Command::Cert.new.create_cert(domain, File.join(dir, 'conf/certs'))

        puts "Initialized server directory: #{domain}"
        puts "Run 'cd #{domain} && vines start' to begin"
      end

      private

      # Limit file system database directory access so the server is the only
      # process managing the data. The config.rb file contains component and
      # database passwords, so restrict access to just the server user as well.
      def create_directories(dir)
        %w[conf web].each do |sub|
          FileUtils.cp_r(File.expand_path("../../../../#{sub}", __FILE__), dir)
        end
        %w[data log pid].each do |sub|
          Dir.mkdir(File.join(dir, sub), 0700)
        end
        File.chmod(0600, File.join(dir, 'conf/config.rb'))
      end

      def update_config(domain, dir)
        config = File.expand_path('conf/config.rb', dir)
        text = File.read(config, encoding: 'utf-8')
        File.open(config, 'w:utf-8') do |f|
          f.write(text.gsub('wonderland.lit', domain))
        end
      end

      def create_users(domain, dir)
        password = 'secr3t'
        alice, arthur = %w[alice arthur].map do |jid|
          User.new(jid: [jid, domain].join('@'),
            password: BCrypt::Password.create(password).to_s)
        end

        [[alice, arthur], [arthur, alice]].each do |user, follower|
          user.roster << Follower.new(
            jid: follower.jid,
            name: follower.jid.node.capitalize,
            subscription: 'both',
            groups: %w[Buddies])
        end

        storage = Storage::Local.new { dir(File.join(dir, 'data')) }
        [alice, arthur].each do |user|
          storage.save_user(user)
          puts "Created example user #{user.jid} with password #{password}"
        end
      end
    end
  end
end
