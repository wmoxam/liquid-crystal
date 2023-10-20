.PHONY: test

all: deps test

test:
	bundle exec ruby --yjit src/benchmark.rb
	crystal build --release src/benchmark.cr
	./benchmark

deps:
	shards install
	bundle install --path .bundle