#!/usr/bin/env ruby
#require 'rubygems'  # if less than Ruby 1.9

#require the packages needed for the application. Stored in an Array to make things a little prettier!
packages = ['mongo','uri','json','optparse','ostruct','openssl','rethinkdb','redis','elasticsearch']
packages.each { |x| require x }

#OptionParser to handle the available options.
options = OpenStruct.new
OptionParser.new do |opt|
  opt.on('--db-type <mongo|rethink>', 'Type of database to connect to'){ |o| options.dbtype = o }
  opt.on('--db DATABASE', 'Database to connect to'){ |o| options.db = o }
  opt.on('-m', '--mongo-conn MONGO-CONNECTION', 'Connection string required for MongoDB in form <host:port>,<host:port>/<db>?replicaSet=<set_id>'){ |o| options.connection = o }
  opt.on('--host HOST', 'Host to connect to'){ |o| options.host = o }
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

  conn = r.connect(:host => options.host,
                   :port => options.port,
                   :auth_key => options.authKey,
                   :ssl => { :ca_certs => options.cert }
                   ).repl

  dbs=r.db_list().run(conn)
  print(dbs)
when 'redis'

  #flag used to determine if we can complete the connection to the redis database.
  redisError = false

  #check if required parameters are set
  if options.host.eql?(nil)
    puts 'Error: Redis host not set. Use --host <HOST> to set'
    redisError = true
  elsif options.port.nil?
    puts 'Error: Redis port not set. Use --port <PORT> to set'
    redisError = true
  elsif options.db.eql?(nil)
    puts 'Error: Redis database not set. Use --db <DATABSE> to set'
    redisError = true
  elsif options.password.eql?(nil)
    puts 'Error: Redis password not set. Use --pass <PASSWORD> to set'
    redisError = true
  else #Clears configuration and prints a status message
    puts 'Configuring redis connection'
  end

  #if no errors then we test the connection.
  if redisError != true

    #connection configuration
    redis = Redis.new(:host => options.host,
                      :port => options.port,
                      :db => options.db,
                      :password => options.password
    )

    #Inserts a key into the redis deployment
    puts 'Inserting key into redis "connected" => ""connection was established\"'
    redis.set("connected", "connection was established")
    puts 'Inserted successfully'

    #Gets the key from the redis deployment to confirm connectivity
    puts 'Getting \"connected\" key from redis deployment'
    puts redis.get("connected")

    #Removes the key from the redis deployment
    puts 'Deleting \"connected\" key from redis deployment'
    redis.del("connected")
    puts 'Deleted successfully'
  end
when 'elasticsearch'
else #Prints an error if the user doesn't specify a db-type
  puts 'Error: No database type selected use the \"--db-type\" option. Run \"MongoConnectionTester.rb -h\" for more details'
end #case options.dbtype
