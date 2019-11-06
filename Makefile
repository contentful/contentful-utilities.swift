
.PHONY: install release test clean open

project:
	swift package generate-xcodeproj
open:
	open ContentfulUtilities.xcodeproj

clean:
	swift package clean
	rm -rf .build

install:
	swift package update

release:
	swift build -c release

test:
	swift test
