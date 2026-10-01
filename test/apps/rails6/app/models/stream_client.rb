# Plain HTTP client (not ActiveRecord). `connection` here is a Faraday
# connection, so `connection.delete(url)` is an HTTP request, not SQL.
# Regression coverage for issue #1750 (SQL injection false positive).
class StreamClient
  def connection
    @connection ||= Faraday.new(connection_options)
  end

  def unpublish_stream(session_id:, stream_id:)
    connection.delete("api/sessions/#{session_id}/stream/#{stream_id}")
  end

  def fetch_session(session_id)
    connection.get("/v1/sessions/#{session_id}")
  end
end
