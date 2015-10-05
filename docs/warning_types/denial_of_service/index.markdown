Denial of Service (DoS) is any attack which causes a service to become unavailable for legitimate clients.

For issues that Brakeman detects, this typically arises in the form of memory leaks. In particular, since Symbols are not garbage collected, creation of large numbers of Symbols could lead to a server running out of memory.

Brakeman checks for instances of user input which is converted to a Symbol. When this is not restricted, an attacker could create an unlimited number of Symbols.

The best approach is to simply never convert user-controlled input to a Symbol. If this cannot be avoided, use a whitelist of acceptable values.

For example:

    valid_values = ["valid", "values", "here"]

    if valid_values.include? params[:value]
      symbolized = params[:value].to_sym
    end

However, Brakeman will still warn about this, because it cannot tell a valid guard expression has been used.

Avoiding the warning itself becomes silly:

    valid_values.each do |v|
      if v == params[:value]
        symbolized = v.to_sym
        break
      end
    end
