# contentful-utilities.swift

> Command line utilities to be used in conjunction with Contentful's Swift SDK's and libraries. See [contentful.swift][2] and [contentful-persistence.swift][3].

**What is Contentful?**

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

## Usage

There are three required arguments and one optional argument. The following command will download all the JSON data from your space in master environment to the specified output directory:

```bash
contentful-utilities sync-to-bundle --space-id "cfexampleapi" --access-token "b4c0n73n7fu1" --environment "master" --output .
```
If you don't specify `environment` parameter master will be used as default value. 
If you additionally want to download the binary data for all your assets, you can add the `--download-asset-data` flag.

## Next steps

Add the downloaded files to your iOS project's bundle and use the following methods from the [contentful-persistence.swift][3] library seed a CoreData database on first launch (note that you are responsible for implementing your own logic for detecting first launch). See [this](https://github.com/contentful/contentful-persistence.swift/blob/master/Sources/ContentfulPersistence/SynchronizationManager%2BSeedDB.swift) file for more detail

```swift
public func seedDBFromJSONFiles(in directory: String, in bundle: Bundle) throws

static func bundledData(for media: AssetProtocol, inDirectoryNamed directory: String, in bundle: Bundle) -> Data?
```


## License

Copyright (c) 2018 Contentful GmbH. See [LICENSE](LICENSE) for further details.

[1]: https://www.contentful.com
[2]: https://github.com/contentful/contentful.swift
[3]: https://github.com/contentful/contentful-persistence.swift
