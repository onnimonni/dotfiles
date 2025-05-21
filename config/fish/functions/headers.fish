# This is normal GET request instead of HEAD request
# It also follows redirects
# Usage: $ headers google.fi
function headers --description 'Print all http headers of http GET request'
  # Source: https://www.woolie.co.uk/article/curl-full-get-request-dropping-body/
  curl -L -IXGET -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36' $argv
end
