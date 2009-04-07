# == About camping/ar/session.rb
#
# This file contains two modules which supply basic sessioning to your Camping app.
# Again, we're dealing with a pretty little bit of code: approx. 60 lines.
# 
# * Camping::Models::Session is a module which adds a single <tt>sessions</tt> table
#   to your database.
# * Camping::ARSession is a module which you will mix into your application (or into
#   specific controllers which require sessions) to supply a <tt>@state</tt> variable
#   you can use in controllers and views.
#
# For a basic tutorial, see the *Getting Started* section of the Camping::ARSession module.
require 'camping'
require 'camping/ar'

module Camping::Models
# A database table for storing Camping sessions.  Contains a unique 32-character hashid, a
# creation timestamp, and a column of serialized data called <tt>ivars</tt>. 
class Session < Base
    serialize :ivars
    set_primary_key :hashid

    def []=(k, v) # :nodoc:
        self.ivars[k] = v
    end
    def [](k) # :nodoc:
        self.ivars[k] rescue nil
    end

  protected
    RAND_CHARS = [*'A'..'Z'] + [*'0'..'9'] + [*'a'..'z']
    def before_create
      rand_max = RAND_CHARS.size
      sid = (0...32).inject("") { |ret,_| ret << RAND_CHARS[rand(rand_max)] }
      write_attribute('hashid', sid)
    end

    # Generates a new session ID and creates a row for the new session in the database.
    def self.generate cookies
        sess = Session.create :ivars => Camping::H[]
        cookies.camping_sid = sess.hashid
        sess
    end

    # Gets the existing session based on the <tt>camping_sid</tt> available in cookies.
    # If none is found, generates a new session.
    def self.persist cookies
        session = nil
        if cookies.camping_sid
            session = Camping::Models::Session.find_by_hashid cookies.camping_sid
        end
        unless session
            session = Camping::Models::Session.generate cookies
        end
        session
    end

    # Builds the session table in the database.  To be used in your application's
    # <tt>create</tt> method.
    #
    # Like so:
    #
    #   def Blog.create
    #       Camping::Models::Session.create_schema
    #       unless Blog::Models::Post.table_exists?
    #           ActiveRecord::Schema.define(&Blog::Models.schema)
    #       end
    #   end
    #
    def self.create_schema
        unless table_exists?
            ActiveRecord::Schema.define do
                create_table :sessions, :force => true, :id => false do |t|
                    t.column :hashid,      :string,  :limit => 32, :null => false
                    t.column :created_at,  :datetime
                    t.column :ivars,       :text
                end
                add_index :sessions, [:hashid], :unique => true
            end
            reset_column_information
        end
    end
end
Session.partial_updates = false if Session.respond_to?(:partial_updates=)
end

module Camping
# The Camping::ARSession module is designed to be mixed into your application or into specific
# controllers which require sessions.  This module defines a <tt>service</tt> method which
# intercepts all requests handed to those controllers.
#
# == Getting Started
#
# To get sessions working for your application:
#
# 1. <tt>require 'camping/session'</tt>
# 2. Mixin the module: <tt>module YourApp; include Camping::ARSession end</tt>
# 3. In your application's <tt>create</tt> method, add a call to <tt>Camping::Models::Session.create_schema</tt>
# 4. Throughout your application, use the <tt>@state</tt> var like a hash to store your application's data. 
# 
# If you are unfamiliar with the <tt>create</tt> method, see 
# http://code.whytheluckystiff.net/camping/wiki/GiveUsTheCreateMethod.
#
# == A Few Notes
#
# * The session ID is stored in a cookie. Look in <tt>@cookies.camping_sid</tt>.
# * The session data is stored in the <tt>sessions</tt> table in your database.
# * All mounted Camping apps using this class will use the same database table.
# * However, your application's data is stored in its own hash.
# * Session data is only saved if it has changed. 
module ARSession
    # This <tt>service</tt> method, when mixed into controllers, intercepts requests
    # and wraps them with code to start and close the session.  If a session isn't found
    # in the database it is created.  The <tt>@state</tt> variable is set and if it changes,
    # it is saved back into the database.
    def service(*a)
        session = Camping::Models::Session.persist @cookies
        app = self.class.name.gsub(/^(\w+)::.+$/, '\1')
        @state = (session[app] ||= Camping::H[])
        hash_before = Marshal.dump(@state).hash
        return super(*a)
    ensure
        if session
            hash_after = Marshal.dump(@state).hash
            unless hash_before == hash_after
                session[app] = @state
                session.save
            end
        end
    end
end
end
