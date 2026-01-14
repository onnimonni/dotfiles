export default {
  defaultBrowser: "Safari",
  rewrite: [
    {
      // Redirect Tiktok video links to use offtiktok.com
      match: "tiktok.com/*",
      url: (url) => {
        url.host = "vm.offtiktok.com";
        return url;
      },
    },
    {
      // Redirect all x.com urls to use xcancel.com
      match: "x.com/*",
      url: (url) => {
        url.host = "xcancel.com";
        return url;
      },
    },
    {
      // Redirect Instagram reel links to vxinstagram.com
      match: "instagram.com/reel/*",
      url: (url) => {
        url.host = "vxinstagram.com";
        return url;
      },
    },
    {
      // Redirect links like this: https://c212.net/c/link/?t=0&l=en&o=4218234-1&h=2715864414&u=https%3A%2F%2Foverturemaps.org%2Fbecome-a-member%2F&a=https%3A%2F%2Foverturemaps.org%2Fbecome-a-member%2F
      // to: https://overturemaps.org/become-a-member/
      // This is needed when using pihole which anyway blocks c212.net
      match: "c212.net/*u=*",
      url: ({ url }) => {
        return new URLSearchParams(url.search).get("u");
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
