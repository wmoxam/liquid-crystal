.PHONY: test

all: compile test

test:
	ruby src/benchmark.rb
	./benchmark

compile:
	crystal build --release src/benchmark.cr

