# This is normal GET request instead of HEAD request
# It also follows redirects
# Usage: $ headers google.fi
function headers --description 'Print all http headers of http GET request'
  # Some stupid services have WAF based on the User-Agent header
  # Discovering what's going on is harder without a proper User-Agent
  set -l FAKE_USER_AGENT 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36'

  # -IXGET throws away the body like HEAD does and uses GET http verb
  # Source: https://www.woolie.co.uk/article/curl-full-get-request-dropping-body/
  curl -L -IXGET -H "User-Agent: $FAKE_USER_AGENT" $argv
end
