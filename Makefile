.PHONY: clean tests


index.js : index.coffee
	coffee -c index.coffee

filters.js : filters.coffee
	coffee -c filters.coffee

tests: clean index.js filters.js tests/tests.coffee
	coffee -c tests/tests.coffee
	node tests/tests.js

clean: 
	rm -f index.js
