module.exports = {
  defaultBrowser: "Safari",
  rewrite: [
    {
      // Redirect all urls to use https except localhost
      match: ({ url }) => url.protocol === "http" && !finicky.matchHostnames(['localhost']),
      url: { protocol: "https" }
    },
    {
      // Redirect Tiktok video links to use Proxitok public proxies
      match: ({ url }) => url.host.endsWith("tiktok.com"),
      url: ({ url }) => {
        // See more https://github.com/pablouser1/ProxiTok/wiki/Public-instances
        const selectRandomTikTokProxy = () => {
          const TIKTOK_PROXIES = [
            "proxitok.pabloferreiro.es", // Official
            "proxitok.pussthecat.org",
            "tok.habedieeh.re",
            "proxitok.esmailelbob.xyz",
            "proxitok.privacydev.net",
            "tok.artemislena.eu",
            "tok.adminforge.de",
            "tt.vern.cc",
            "cringe.whatever.social",
            "proxitok.lunar.icu",
            "proxitok.privacy.com.de",
            "cringe.seitan-ayoub.lol",
            "cringe.datura.network",
            "tt.opnxng.com",
            "tiktok.wpme.pl",
            "proxitok.r4fo.com",
            "proxitok.belloworld.it",
          ]
          return TIKTOK_PROXIES[Math.floor(Math.random() * TIKTOK_PROXIES.length)]
        }
        const tikTokUrlToProxitok = (url) => {
          if (url.pathname.startsWith('/@'))
            return url.pathname
          if (url.pathname.startsWith('/t/'))
            return url.pathname.replace('/t/', "/@placeholder/video/")
          return `/@placeholder/video${url.pathname}`
        }
        return {
          protocol: "https",
          host: selectRandomTikTokProxy(),
          // Prepend pathname with /@placeholder/video to match ProkiTok urls
          pathname: tikTokUrlToProxitok(url)
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
        "swappie.*" // Login to Swappie systems with Chrome
      ],
      browser: "Google Chrome"
    }
  ]
};