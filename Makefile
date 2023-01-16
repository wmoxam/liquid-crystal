.PHONY: test

test:
	crystal run test/liquid/assign_test.cr
	crystal run test/liquid/block_test.cr
	crystal run test/liquid/condition_test.cr
	crystal run test/liquid/context_test.cr
	crystal run test/liquid/drop_test.cr
	crystal run test/liquid/error_handling_test.cr
	crystal run test/liquid/file_system_test.cr
	crystal run test/liquid/filter_test.cr
	crystal run test/liquid/output_test.cr
	crystal run test/liquid/parsing_quirks_test.cr
	crystal run test/liquid/regexp_test.cr
	crystal run test/liquid/security_test.cr
	crystal run test/liquid/standard_filter_test.cr
	crystal run test/liquid/strainer_test.cr
	crystal run test/liquid/template_test.cr
	crystal run test/liquid/variable_test.cr

	crystal run test/liquid/tags/*.cr
