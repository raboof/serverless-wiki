Serverless-wiki is a 'serverless' public wiki

This means most of the functionality can be accessed while
serving static pages from a CDN, and only for updates is any
server-side code required.

In a nutshell:

* Pages are mostly static and served from a CDN (e.g. github pages)
* Page sources are stored as markdown in a git repository (e.g. github)
* Logging in stores your password in your browser, and checks whether your
  password is 'plausible' (based on a high-collision hash)
* Update pages with an authenticated POST with new markdown, which:
  * commits the new markdown to the git repo
  * generates new HTML and commit it to the CDN

## Authentication

'logging in' is initially a usability feature rather than a security feature:
the password is put though a non-cryptographic, high-collision hash function.

The 'real' authentication happens when POSTing new markdown.
