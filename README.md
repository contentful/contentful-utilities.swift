
# contentful-utilities.swift

Command line utilities to be used in conjunction with Contentful's Swift SDK's and libraries. See [contentful.swift][2] and [contentful-persistence.swift][3].

[Contentful][1] provides a content infrastructure for digital teams to power content in websites, apps, and devices. Unlike a CMS, Contentful was built to integrate with the modern software stack. It offers a central hub for structured content, powerful management and delivery APIs, and a customizable web app that enable developers and content creators to ship digital products faster.
## Usage

While more commands will be added in the future, there is currently only one sub-command for the command line interface: `sync-to-bundle`. This command uses the `/sync` endpoint of Contentful's Content Delivery API to save all data in a Contentful space to a directory. If you bundle this directory in your Cocoa applications bundle, then you can seed a CoreData database with the data in this directory using the relevant methods in [contentful-persistence.swift][3]. `sync-to-bundle` takes 3 arguments: your space identifier, CDA access token, and the path to the directory you'd like to save the synced content to.

## Installation

As the contentful-utilities command line interface is not yet distributed via any package managers, you will need to clone the repo, build, and install it yourself:

```bash
git clone git@github.com:contentful/contentful-utilities.swift
cd contentful-utilities.swift
make release
```

Now that the executable has compiled, `cd` in to the build directory and then copy the executable to your path:

```bash
cd .build/release
cp -f ContentfulUtilties /usr/local/bin/contentful-utilities
```

## License

Copyright (c) 2016 Contentful GmbH. See LICENSE for further details.

[1]: https://www.contentful.com
[2]: https://github.com/contentful/contentful.swift
[3]: https://github.com/contentful/contentful-persistence.swift
