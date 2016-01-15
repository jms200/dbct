#!/usr/bin/env ruby
#require 'rubygems'  # if less than Ruby 1.9
packages = ['mongo','uri','json','optparse','ostruct','openssl','rethinkdb']
packages.each { |x| require x }

include Mongo

options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('--db-type <mongo|rethink>', 'Type of database to connect to'){ |o| options.dbtype = o }
  opt.on('-m', '--mongo-conn MONGO-CONNECTION', 'Connection string required for MongoDB in form <host:port>,<host:port>/<db>?replicaSet=<set_id>'){ |o| options.connection = o }
  opt.on('--rethink-host HOST', 'Host for rethinkDB deployment'){ |o| options.rethinkHost = o }
  opt.on('--port PORT', 'Connection port'){ |o| options.port = o.to_i }
  opt.on('-a', '--auth-key AUTH-KEY', 'Auth key used for DB authentication'){ |o| options.authKey = o }
  opt.on('-u', '--user USERNAME', 'Username for DB authentication'){ |o| options.username = o }
  opt.on('--cert CERT-PATH', 'Path to SSL cert used for encrypted communication'){ |o| options.cert = o }
  opt.on('-p', '--pass PASSWORD', 'Username for DB authentication'){ |o| options.password = o }
end.parse!

case options.dbtype
when 'mongo'
  include Mongo

  client = Mongo::Client.new('mongodb://' + options.username + ':' + options.password + '@' + options.connection)
  db = client.database

  puts "Collections"
  puts "==========="
  collections = db.collection_names
  puts collections
when 'rethink'
  include RethinkDB::Shortcuts

  conn = r.connect(:host => options.rethinkHost,
                   :port => options.port,
                   :auth_key => options.authKey,
                   :ssl => { :ca_certs => options.cert }
                   ).repl

  dbs=r.db_list().run(conn)
  print(dbs)
else
  puts 'Error: No database type selected use the \"--db-type\" option. Run \"MongoConnectionTester.rb -h\" for more details'
end
