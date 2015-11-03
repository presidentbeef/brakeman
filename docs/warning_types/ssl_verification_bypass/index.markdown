Simply using SSL isn't enough to ensure the data you are sending is secure. Man in the middle (MITM) attacks are well known and widely used. In some cases, these attacks rely on the client to establish a connection that doesn't check the validity of the SSL certificate presented by the server. In this case, the attacker can present their own certificate and act as a man in the middle.

In Ruby, this happens when the OpenSSL verification mode is set to `VERIFY_NONE`

    require "net/https"
	require "uri"

	uri = URI.parse("https://ssl-site.com/")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE

	request = Net::HTTP::Get.new(uri.request_uri)

	response = http.request(request)

In this case, if an invalid certificate was presented, no verification would occur, providing an opportunity for attack. When successful, the data transmitted (cookies, request parameters, POST bodies, etc.) would all be able to be intercepted by the MITM.

Brakeman would produce a warning like this:

    SSL certificate verification was bypassed near line 24: http.verify_mode = OpenSSL::SSL::VERIFY_NONE

To ensure that SSL verification happens use the following mode:

    http.verify_mode = OpenSSL::SSL::VERIFY_PEER

If the server certificate is invalid or context.ca_file is not set when verifying peers an OpenSSL::SSL::SSLError will be raised.

For more information on the impact of this issue, see the paper [The Most Dangerous Code in the World](https://www.cs.utexas.edu/~shmat/shmat_ccs12.pdf).
