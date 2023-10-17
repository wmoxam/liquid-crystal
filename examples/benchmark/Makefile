.PHONY: test

all: compile test

test:
	bundle install --path .bundle
	bundle exec ruby --yjit src/benchmark.rb
	./benchmark

compile:
	shards install
	crystal build --release src/benchmark.cr

