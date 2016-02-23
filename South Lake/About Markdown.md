## Journler Rebuilt

### Core Design Principle 

1. No walled gardens
2. Customizable, modular and extensible
3. Native has value
4. Offline and online 

### Core Development Principles

1. United code base

As a consequence of modular and extensible, web technologies make more sense than platform specific ones.

But Sublime works with packages as well. The trick is that what surrounds the editor is native but the editor itself uses open technologies and so can be scripted.

But what if you want the capabilities around the editor (folders, smart folders, calendar, etc) to be customizable as well.

"Sublime Text is available for OS X, Windows and Linux. One license is all you need to use Sublime Text on every computer you own, no matter what operating system it uses.

Sublime Text uses a custom UI toolkit, optimized for speed and beauty, while taking advantage of native functionality on each platform."

### Tensions

- Native vs build-once and extensible
- Text-based vs PDFs and other documents
- Easy to use but customizable

### Ideas

Wiki-Markdown-Journler thing.

1. Markdown based, so also HTML/CSS/JS
2. Unified frontend code : all frontend code: desktop, mobile, web, shares a common base.*
2. One application, many journals
3. Views on to data: the data is markdown entries and views include calendar, folders, tags, etc.
4. But data is also: pdf documents, etc.
2. Support for latex and other javascript based support (D3...)
3. Must be able to index and possibly view other document types
3. Links: effectively a private wiki
4. Support for CS customization
5. NLP and Recommendation Engines
6. Web component: syncing
7. Web component: community and cross-accout recommendations


This is a professional tool, something like Adobe Photoshop or Apple Logic for information management. Or is it possible to sell an approachable basic journaling application and a professional two.

The tension is between native interface and a unified codebase.

It would be amazing to use MongoDB or some other document based database on the backend, because then users could define their own metadata!

## Personal

There is a very deep part of me that doesn't want to spend time coding, fixing bugs, half-assing architecture, kludging kludges. And instead to spend time reading and writing and researching.

## Business Model

One license: works unsynced on any device. Multiple devices synced: monthly payments.

Desktop: single payments for major versions of the Desktop application using some kind of freemium or shareware based model, license works for any desktop version. Probably no app stores.

Mobile: mobile versions may be free. App store where necessary.

Web Application: monthly payments, perhaps with some kind of freemium model based on amount of storage used.

Syncing requires an online account and monthly payments.

### Market

What's the target niche? What kind of people used Journler before? Many professionals, some personal. Target professionals. What kind of professionals? What does Journler offer that is unique? Markdown and LaTeX are common in technical computing. Target scientific users and researches.

## Frontend Code

*2. Unified frontend code : all frontend code: desktop, mobile, web, shares a common base. Which means that the core of the application is a web view wrapping web code.

Is that the right way to do it, or do you want to support native interfaces on a given platform? For example, drag and drop with folders is done a particular way on the Mac OS, and another way on Windows I'm sure. Each aspect of that interface would need to be re-written for each platform. On the other hand if you're web based entirely you can write the code once and have it work anywhere.

Having looked at [Atom](https://atom.io/) I would love to build on top of that. [Electron provides those capabilities](http://electron.atom.io/). [NW.js](http://nwjs.io/) seems to be the competitor to Electron.

But using Electron doesn't seem to ensure the existence of a web-based product.

Examples using Electron:

- [https://www.nylas.com/n1](https://www.nylas.com/n1)
- [http://lab.ionic.io/](http://lab.ionic.io/)
- [http://zoommyapp.com/](http://zoommyapp.com/)
- [http://caret.io/](http://caret.io/) : Markdown editor
- [https://b00st.io/](https://b00st.io/) : Markdown journal

Could you provide a *Mac Native* version as well as an Eletron cross-platform version?

### Pros for Native

Some of the native interface stuff is just gorgeous and can help your product stand out. Make it beautiful for users who love the computers they use and appreciate that consistent aesthetic.

### Shared Frontend and Shared Backend

Either I want to write one frontend using something like Electron and one backend all using the same server code and database system (eg node and mongodb on mac, windows, linux and web application -- but then how do you package that product? Would you have to download code and compile like R studio and NPM or can you deliver binaries appropriate for each platform, ooh, just in time binaries compiled on your own secure servers).

Share frontend makes the development so much easier but loses some of the value of a native experience. Community packages 

### Native Frontend and Shared Backend

Leverage what is beautiful and specific to each platform for the user interface but it communicates with the same backend code. Still have

### Native Frontend and Native Backend

Write completely native code. Not only must different code be maintained for each platform but syncing data across them is more of an issue.

I don't consider the option of using the same frontend code and different backend code.

### React Native

*Greg suggests React Native from Facebook*

- [https://facebook.github.io/react-native/](https://facebook.github.io/react-native/)
- [http://www.reactnative.com/](http://www.reactnative.com/)

1. Does React Native work with Electron? : [React Desktop](https://github.com/gabrielbull/react-desktop)
2. Does Electron work with a custom backend?

Whether native or JS front end is used the idea would be to define a front end that communicates via a rest interface with a backend that manages data storage, even on the desktop. So the desktop application would itself spin up a server that the desktop front end communicates with.

*Ari Najarian on Twitter recommends pouchDB that syncs automatically with couchDB*

- [http://pouchdb.com/](http://pouchdb.com/)

## Backend Code

What I want to do is run the same database on the desktop, mobile and web applications, and use the same code from any one of those to communicate with some other, for example, the same iOS code communicates with the local database server and with the remote database server, and just needs a switch to know which one.

Peer-to-peer replication sounds amazing as well. The database itself knows how to copy and sync itself.

[CouchDB](http://couchdb.apache.org/) (and PouchDB)

[Couchbase](http://www.couchbase.com/)

[Couchbase Mobile](http://www.couchbase.com/nosql-databases/couchbase-mobile)

Not sure what the difference between CouchDB and Couchbase are:

[http://stackoverflow.com/questions/25736125/confused-with-couchdb-and-couchbase](http://stackoverflow.com/questions/25736125/confused-with-couchdb-and-couchbase)

[http://stackoverflow.com/questions/5578608/difference-between-couchdb-and-couchbase/15184612#15184612](http://stackoverflow.com/questions/5578608/difference-between-couchdb-and-couchbase/15184612#15184612)

There there is Couchbase Lite which is meant for mobile use and can sync with a server.

### CouchDB (and Couchbase Lite)

CouchDB advertises automatic syncing between master-master instances of a dataset. Appealing. Does it actually work?

But it uses map-reduce for all querying. You create a view onto the data with a map function that outputs a key and a value along with the document's _id by default.

For example, if your document has a title and tags like so:

```
[
	{
		title: "Developing South Lake",
		tags: ["journler", "software"
	},
	{
		title: "Philosophy or Software?",
		tags: ["personal"]
	}
]
```

Then you'll:

```
emit(doc.title)
```

And get:

```
[
	{
		key: "Developing South Lake",
		value: null,
		id: ...
	},
	{
		key: "Philosophy or Software?",
		value: null,
		id: ...
	}
]
```

Tags might be more interesting. You want to call `emit` once for each tag:

```
for tag in doc.tags {
	emit(tag)
}
```

And get:

```
[
	{
		key: "journler",
		value: null,
		id: ...
	},
	{
		key: "software",
		value: null,
		id: ...
	},
	{
		key: "personal",
		value: null,
		id: ...
	}
]
```

Unfortunately this doesn't make CouchDB practical for full text search or ad hoc searches. Book recommends Lucene or ElasticSearch.

You have the option of including a reduce function, which will usually be some kind of statistical aggregator.

Once you have the view and the data indexed using B-Trees, you can then query it. Queries are run against keys.

For example, you could query the tags view for the key "personal" and get back only those entries where the key == personal.

I believe then you want to create all your views in advance. Views for queries on title, tags, date\_created, date\_updated, etc. Then you query against a particular set of keys.

But the queries are equality only. You can't query prefix (starts with), suffix (ends with), pattern matching, and so on. That's a serious limitation.

You could imagine building a basic full text search, when for each document you emit each word in the document as a key. You could porter stem it or whatever.

## Text Search

If CouchDB does not provide full text search we need another technology for it. Mac OS provides SearchKit, which is a technology I used in Journler for document and inverted document searching, but it isn't available for iOS let alone other platforms. What is?

Two estbalished options are [Lucene](https://lucene.apache.org/) and [Elastic Search](https://www.elastic.co/). I believe Elastic Search is web based, whereas Lucene can be compiled and embedded. Ok, can I use Lucene on Mac and iOS?

### Lucene

The [Wikipedia](https://en.wikipedia.org/wiki/Lucene) entry says there is a c++ library: [CLucene](http://clucene.sourceforge.net/). Perfect. And it looks like Blue Rocket built an objective-c wrapper around it: [BRFullTextSearch](https://github.com/Blue-Rocket/BRFullTextSearch). Nice. They advertise it as an iOS search engine but I can't imagine it doesn't work with the Mac OS.

But it's only set up to build for iOS, which means I need to figure out how to build it for Mac OS.

## Technologies Being Used

[MMTabBarView](https://github.com/MiMo42/MMTabBarView)

[MacDown](http://macdown.uranusjr.com/)

## Markdown Editors

[MacDown](http://macdown.uranusjr.com/)

[https://stackedit.io/](https://stackedit.io/)

## Other

[Text Extraction](https://www.npmjs.com/package/textract) for node

[Angular with electron](https://scotch.io/tutorials/creating-desktop-applications-with-angularjs-and-github-electron)

[WebShell](https://github.com/djyde/WebShell) : Bundle web apps as native apps - it's doing what I want to do with StackEdit

## Features

It's markdown, so when you create a new entry you don't actually have to give it a title. You go ## title and it takes that as the title.

Automatically parses markdown and creates a document hierarchy for a particular entry.

Smart folders: drop to tag

Menu shortcuts like in Sublime and Atom. Not just menu keyboard shortcuts but that dropdown that appears at the top center.

## Competition and Related Tools

[Day One App](http://dayoneapp.com/) : Journaling

[Evernote](https://evernote.com/) : Information Dump

[Devon Think](http://www.devontechnologies.com/) : Document Manager

[Mellel](http://www.mellel.com/) : Word Processor

[Things](https://culturedcode.com/things/) : Tasks and ToDos

[Bookends](http://www.sonnysoftware.com/) : Citations

## Data Model

### Source list

Section is top level. A section contains documents and folders. A folder contains other folders and documents. A document can only be a leaf. A folder can belong to a single folder. But a document can belong to many folders.

```
Source ->

Section
Document 
Folder:
	Smart Folder
```

The one-to-many parent-child relationships will be modeled using object-ids. I need to make sure that when a source item is transformed into a model object from its document representation, that additional transformations from the document representation produce the same model object.

How does the outline view handle a single item appearing more than once, e.g. a document appearing in two folders. I might have to use a proxy with represented objects.

> Each item in the outline view must be unique.

Yup. Use `NSTreeNode` which can contain a represented object

## File System

Can't use NSDocument because saving with NSFileWrapper and URL writing is fucking weird. Still want to have separate journals and store the attachments and markdown in an accessible way.

So I can either continue to use application support or I can create a custom package document in the user's Document's directory, then with the following directory structure:

```
Bundle Directory:
	Journal A:
		CouchbaseLite:
			Managed Files
			...
		Entries:
			Markdown File
			Markdown File
			...
	Journal B:
		CouchbaseLite:
			Managed Files
			...
		Entries:
			Markdown File
			Markdown File
			...
	...
```

The user selects which journal they want to use at any given moment, and each "instance" of a journal manages access to the correct database.

This actually might make more sense because we're also handling syncing ourselves.

Wait, this might not actually be true. I don't need to work with any of the saving methods provided by NSDocument that are weird with file wrappers or don't provide the original URL during atomic operations. 

All I need is the original URL when the document is created, in order to create the database, the document's current URL in order to copy over files, which I believe the document keeps track of, and the document's URL when the file is opened, in order to read the database.

I don't actually do anything when saving. In fact, there is no save operation in the application. All activity is immediately persisted.

## Rendering Table of Contents

Hoedown is a markdown processing library in C. Hoedown renders the table of contents with its own function:

```
hoedown_html_renderer_new
hoedown_html_toc_renderer_new
```

The `MPRenderer` includes the TOC as part of the markdown -> html conversion process which produces the entire html:

```
NS_INLINE NSString *MPHTMLFromMarkdown
```

That function is called via:

```
MPRenderer.parse()
MPRenderer.parseAndRenderNow() | MPRenderer.parseAndRenderLater()
```

which is called at various times by the Document.

I should be able to extract the table of contents part of the process. Yup, got it.

Now I need to make sure to render the toc by default from the markdown without including the TOC tag, so that the href targets are built into the html. Then I need to render the TOC itself into another webview, intercept the link clicks, and jump to the href target in the other web view.