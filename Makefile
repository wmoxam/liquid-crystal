.PHONY: test

test:
	crystal run test/all_tests.cr -- --parallel 4 --verbose
