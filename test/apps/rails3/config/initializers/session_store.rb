# Be sure to restart your server when you modify this file.

Rails3::Application.config.session_store :cookie_store, :key => '_rails3_session', :httponly => false, :secure => false

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Rails3::Application.config.session_store :active_record_store
