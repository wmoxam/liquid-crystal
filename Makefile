.PHONY: test

test:
	crystal run test/all_tests.cr -- --verbose
