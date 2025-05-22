module.exports = {
  defaultBrowser: "Safari",
  rewrite: [
    {
      // Redirect all urls to use https except localhost
      match: ({ url }) => url.protocol === "http" && !finicky.matchHostnames(['localhost']),
      url: { protocol: "https" }
    },
    {
      // TODO: This gets links like: https://vm.tiktok.com/ZNeKFD54M
      // Redirect them to: https://vm.offtiktok.com/ZNeKFD54M instead
      // Redirect Tiktok video links to use offtiktok.com
      match: ({ url }) => url.host.endsWith("tiktok.com"),
      url: ({ url }) => {
        return {
          protocol: "https",
          host: "vm.offtiktok.com",
          pathname: url.pathname
        }
      }
    }
  ],
  handlers: [
    {
      // Open google.com and *.google.com urls in Google Chrome
      match: [
        "google.com/*", // match google.com urls
        "*.google.com/*", // match google.com subdomains
        "*.cloud.google.com/*", // Use GCP with chrome
        "github.com/*",
        "*.app.netsuite.com/*",
        "swappie.*", // Login to Swappie systems with Chrome
        // Use Drizzle studio with Chrome since chrome plugin is so good
        "local.drizzle.studio"
      ],
      browser: "Google Chrome"
    }
  ]
};
