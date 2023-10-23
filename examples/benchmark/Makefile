.PHONY: test

all: deps test

test:
	bundle exec ruby --yjit src/benchmark.rb
	crystal build --release src/benchmark.cr
	./benchmark

	bundle exec ruby --yjit src/benchmark-with-filter.rb
	crystal build --release src/benchmark-with-filter.cr
	./benchmark-with-filter

deps:
	shards install
	bundle install --path .bundle