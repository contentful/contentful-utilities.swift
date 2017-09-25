

.PHONY: install release test


clean:
	swift package clean
	rm -rf ~/Library/Developer/Xcode/DerivedData

install:
	swift package update

release:
	swift build -c release -Xswiftc -static-stdlib

test:
	swift test
