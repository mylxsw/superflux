run:
	swift run SpotdarkApp

test:
	swift test

coverage:
	swift test --enable-code-coverage

.PHONY: run test coverage
