.PHONY: clean tests


index.js : index.coffee
	coffee -c index.coffee

tests: clean index.js tests/tests.coffee
	coffee -c tests/tests.coffee
	node tests/tests.js

clean: 
	rm -f index.js
