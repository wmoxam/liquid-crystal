.PHONY: test

test:
	crystal run test/all_tests.cr -- --verbose
	crystal run test/liquid/context_test.cr -- --verbose
	crystal run test/liquid/drop_test.cr -- --verbose
	crystal run test/liquid/error_handling_test.cr -- --verbose
	crystal run test/liquid/standard_filter_test.cr -- --verbose
