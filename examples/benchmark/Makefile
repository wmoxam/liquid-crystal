.PHONY: test

all: compile test

test:
	bundle install --path .bundle
	bundle exec ruby src/benchmark.rb
	./benchmark

compile:
	shards install
	crystal build --release src/benchmark.cr

