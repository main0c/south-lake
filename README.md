
## South Lake

Secret project for new Journler like application. Shhhh.

## Builder Beware

The document format and data model may change at any point at this stage of development, rendering your saved data unreadable. Use at your own risk.

## Road Map

- v0.0 [Current] : Initial develompent
- v0.1 : MVP release: basic markdown, folders, search
- v0.2 : Markdown import, plugin architecture
- v0.3 : Metadata, smart folders, import
- v0.4 : Sync
- v0.5 : Cross platform development

More: improved markdown (images), interdocument linking, table of contents, calendar view, model and ui tests, templates (plugins), autocompletion (plugins) ...

## Build

Ensure you have [Cocoapods](https://cocoapods.org/) installed.

Pull the repository and its submodules:

```
git clone https://github.com/phildow/south-lake.git
cd south-lake
git submodule update --init --recursive
```

CD into the MacDown dependency directory and install the required pods

```
cd Dependencies/macdown
pod install
```

CD back into the project directory and pod install:

```
cd ../..
pod install
```

Check that cocoapods didn't bork the preprocessor macros in build settings:

```
Debug:   DEBUG=1 COCOAPODS=1 SOUTHLAKE=1
Release: COCOAPODS=1 SOUTHLAKE=1
```

You may need to build BRFullTextSearch manually. If so open up its workspace in the Dependencies folder and Archive it. That will produce Framework-MacOS/Release/BRFullTextSearch in the BRFullTextSearch directory, which is where South Lake looks for it.

Open up the South Lake workspace, build and go!

## Create Project

Instructions used to create the project from scratch. If not automated then at least documented. Xcode 7.3, MacDown 0.5.5.1 (717), CouchBase-Lite 1.2. You probably don't need to worry about this.

**Create Xcode project**

Create a new Mac OS Cocoa application: 

```
Language : Swift
---
[X] Use Storyboards
[X] Create Document-Based Application
---
[ ] Use Core Data
[X] Include Unit Tests
[X] Include UI Tests 
```

Git init. Add [gitignore](https://github.com/github/gitignore/blob/master/Swift.gitignore). Add bridging header and update build setting for it. Pod init.

**Integrate MacDown**

Add MacDown as submodule and recursively update submodules:

```
git submodule add -b dependency-mods https://github.com/phildow/macdown.git Dependencies/macdown
git submodule update --init --recursive
```

Install MacDown pod dependencies in macdown subdirectory (see MacDown ReadMe):

```
pod install # in Dependencies/macdown
```

Add required MacDown dependencies to project Podfile:

```ruby
# MacDown dependencies
pod 'handlebars-objc', '~> 1.4'
pod 'hoedown', '~> 3.0'
pod 'LibYAML', '~> 0.1', :inhibit_warnings => true
pod 'M13OrderedDictionary', '~> 1.1'
pod 'PAPreferences', '~> 0.4'
```

And install:

```
pod install
```

Don't forget to use the workspace from now on! Define `SOUTHLAKE=1` preprocessor macro. We do this after Cocoapods installs so it doesn't botch its own preprocessor macros.

Add Apple frameworks needed by MacDown: 

```
WebKit
JavaScript Core
```

Add MacDown build phase to xcode project: 

```bash
WORKSPACE=$PROJECT_DIR/Dependencies/macdown/MacDown.xcworkspace
SCHEME=MacDown

xcodebuild -workspace $WORKSPACE -scheme $SCHEME
```

Build project. MacDown build generates additional source files and resources.

Add MacDown resources to project with folder references, and add them to the copy bundle resources build phase:

```
Data/
Extensions/
MathJax/
Prism/
Styles/
syntax_highlighting.json
Themes/
```

Add code to project:

```
Peg-Markdown-Highlight:
	HGMarkdownHighlighter.h
	HGMarkdownHighlighter.m
	HGMarkdownHighlightingStyle.h
	HGMarkdownHighlightingStyle.m
	pmh_definitions.h
	pmh_parser.c
	pmh_parser.h
	pmh_styleparser.c
	pmh_styleparser.h

YAML-framework:
	YAMLSerialization.h
	YAMLSerialization.m
	
MacDown:
	Document:
		MPAsset.h
		MPAsset.m
		MPDocument.h
		MPDocument.m
		MPRenderer.h
		MPRenderer.m
	Extension:
		DOMNode+Text.h
		DOMNode+Text.m
		hoedown_html_patch.c
		hoedown_html_patch.h
		NSColor+HTML.h
		NSColor+HTML.m
		NSDocumentController+Document.h
		NSDocumentController+Document.m
		NSJSONSerialization+File.h
		NSJSONSerialization+File.m
		NSObject+HTMLTabularize.h
		NSObject+HTMLTabularize.m
		NSString+Lookup.h
		NSString+Lookup.m
		NSTextView+Autocomplete.h
		NSTextView+Autocomplete.m
		WebView+WebViewPrivateHeaders.h
	Preferences:
		MPPreferences.h
		MPPreferences.m
	Utility:
		MPAutosaving.h
		MPMathJaxListener.h
		MPMathJaxListener.m
		MPUtilities.h
		MPUtilities.m
	View:
		MPDocumentSplitView.h
		MPDocumentSplitView.m
		MPEditorView.h
		MPEditorView.m
```

Update compiler flags for source files:

```
pmh_styleparser.c   :  -Wno-conversion
pmh_parser.c        :  -Wno-conversion -Wno-unreachable-code
YAMLSerialization.m :  -fno-objc-arc -Wno-unused-variable
```

Update BridgingHeader:

```c
// MacDown
#import "MPDocumentSplitView.h"
#import "MPEditorView.h"
#import "MPPreferences.h"
#import "MPRenderer.h"
#import "MPMathJaxListener.h"
#import "MPUtilities.h"
```

Check your build! MacDown is integrated.

**Integrate BRFullTextSearch**

Add BRFullTextSearch submodule:

```
git submodule add -b macos-framework https://github.com/phildow/BRFullTextSearch Dependencies/BRFullTextSearch
git submodule update --init --recursive
```

Add build phase:

```bash
WORKSPACE=$PROJECT_DIR/Dependencies/BRFullTextSearch/BRFullTextSearch.xcworkspace
SCHEME="BRFullTextSearch Mac OS"

xcodebuild -workspace $WORKSPACE -scheme "$SCHEME"
```

Build, and then add the *BRFullTextSearch.framework* MacOS release framework to project as embedded binary.

Update BridgingHeader:

```c
// BRFullTextSearch
#import <BRFullTextSearch/BRFullTextSearch.h>
#import <BRFullTextSearch/BRSearchService.h>
#import <BRFullTextSearch/CLuceneSearchService.h>
```

**Integrate Couchbase Lite**

Couchbase Lite doesn't seem to want to build from Carthage or from source so just download the framework to a Frameworks directory and add it as an embedded binary. Source:

[http://www.couchbase.com/dl/releases/couchbase-lite/macosx/1.2.0/couchbase-lite-macosx-enterprise_1.2.0-112.zip](http://www.couchbase.com/dl/releases/couchbase-lite/macosx/1.2.0/couchbase-lite-macosx-enterprise_1.2.0-112.zip)

Add required MacOS frameworks to project:

```
Security
CFNetwork
SystemConfiguration
```

Update BridgingHeader:

```c
// Couchbase
#import <CouchbaseLite/CouchbaseLite.h>
```

Does it still run? You betcha.

**Integrate MMTabBarView**

Add MMTabBarView as submodule:

```
git submodule add -b south-lake https://github.com/phildow/MMTabBarView.git Dependencies/MMTabBarView
```

Add MMTabBarView/MMTabBarView.xcodeproj as subproject. This is what we really want to do with all our dependencies. Add MMTabBarView framework to embedded binaries.

Update BridgingHeader:

```c
// MMTabBarView
#import <MMTabBarView/MMTabBarView.h>
#import <MMTabBarView/MMTabBarItem.h>
```

Dude. Tabs.