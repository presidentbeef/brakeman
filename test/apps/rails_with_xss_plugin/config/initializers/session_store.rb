# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_forums_session',
  :secret      => 'a2b5bb679742890a7af48afb795fc54b17b19670a6ebd713bfaa25c11988cf8619c7138b32913a825dfc37876aa011a195260feaa7219b37c1797762668eba8d'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
