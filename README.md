# KinoTochkaApi

Api for accessing data from https://kinotochka.co.

    # Commands
    
```sh
swift package generate-xcodeproj
swift package init --type=executable
swift package init --type=library
swift package resolve
swift build
swift test -l
swift test -s <testname>
swift package show-dependencies
swift package show-dependencies --format json
swift -I .build/debug -L .build/debug -lKinoTochkaApi
```

# Publishing

```bash
git tag 1.0.2
git push --tags
```

  