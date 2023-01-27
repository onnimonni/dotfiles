// Use https://finicky-kickstart.now.sh to generate basic configuration
// Learn more about configuration options: https://github.com/johnste/finicky/wiki/Configuration
module.exports = {
    defaultBrowser: "Safari",
    rewrite: [
      {
        // Redirect all urls to use https
        match: ({ url }) => url.protocol === "http",
        url: { protocol: "https" }
      }
    ],
    handlers: [
      {
        // Open google.com and *.google.com urls in Google Chrome
        match: [
          "google.com/*", // match google.com urls
          "*.google.com/*", // match google.com subdomains
          "*.cloud.google.com", // Use GCP with chrome
        ],
        browser: "Google Chrome"
      }
    ]
  };